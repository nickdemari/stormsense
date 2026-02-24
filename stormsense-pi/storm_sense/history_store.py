"""HistoryStore — SQLite-backed persistence for sensor readings."""

from __future__ import annotations

import logging
import sqlite3
import time
from pathlib import Path

logger = logging.getLogger(__name__)

DEFAULT_DB_PATH = '/home/pi/stormsense_history.db'
PRUNE_MAX_AGE_S = 7 * 24 * 3600  # 7 days


class HistoryStore:
    """SQLite-backed history storage for sensor readings.

    Falls back gracefully to a no-op stub if the database cannot be opened
    (e.g. read-only filesystem, permissions error).  The sensor service
    should always keep its in-memory structures as the primary data source
    so that a database failure never takes down the station.
    """

    def __init__(self, db_path: str = DEFAULT_DB_PATH) -> None:
        self._db_path = db_path
        self._conn: sqlite3.Connection | None = None
        self._last_prune: float = 0.0
        self._open()

    # ── Public API ──────────────────────────────────────────────

    @property
    def is_available(self) -> bool:
        """True when the database connection is live."""
        return self._conn is not None

    def add_reading(self, reading: dict) -> None:
        """Persist a single sensor reading.  Silently skips if DB is down."""
        if self._conn is None:
            return
        try:
            self._conn.execute(
                '''INSERT INTO readings
                   (timestamp, temperature, temperature_f,
                    raw_temperature, pressure, storm_level)
                   VALUES (?, ?, ?, ?, ?, ?)''',
                (
                    reading['timestamp'],
                    reading['temperature'],
                    reading['temperature_f'],
                    reading['raw_temperature'],
                    reading['pressure'],
                    reading['storm_level'],
                ),
            )
            self._conn.commit()
        except sqlite3.Error:
            logger.exception('Failed to write reading to SQLite')

    def get_history(self, limit: int = 1000, since: float = 0) -> list[dict]:
        """Return readings ordered by timestamp ascending.

        Args:
            limit: Maximum number of rows to return.
            since: Only return readings with timestamp > since.
        """
        if self._conn is None:
            return []
        try:
            cursor = self._conn.execute(
                '''SELECT timestamp, temperature, temperature_f,
                          raw_temperature, pressure, storm_level
                   FROM readings
                   WHERE timestamp > ?
                   ORDER BY timestamp ASC
                   LIMIT ?''',
                (since, limit),
            )
            return [dict(row) for row in cursor.fetchall()]
        except sqlite3.Error:
            logger.exception('Failed to read history from SQLite')
            return []

    def prune_if_due(self, max_age_seconds: int = PRUNE_MAX_AGE_S) -> int:
        """Delete old readings, but only if an hour has elapsed since last prune.

        Returns number of rows deleted (0 if skipped or unavailable).
        """
        now = time.time()
        if now - self._last_prune < 3600:
            return 0
        self._last_prune = now
        return self._prune(max_age_seconds)

    def count(self) -> int:
        """Total number of stored readings."""
        if self._conn is None:
            return 0
        try:
            cursor = self._conn.execute('SELECT COUNT(*) FROM readings')
            return cursor.fetchone()[0]
        except sqlite3.Error:
            logger.exception('Failed to count readings in SQLite')
            return 0

    def close(self) -> None:
        """Close the database connection."""
        if self._conn is not None:
            try:
                self._conn.close()
            except sqlite3.Error:
                logger.exception('Error closing SQLite connection')
            finally:
                self._conn = None

    # ── Private helpers ─────────────────────────────────────────

    def _open(self) -> None:
        """Open the database and create the schema.  On failure, stay in
        memory-only mode with a warning."""
        try:
            # Ensure parent directory exists
            Path(self._db_path).parent.mkdir(parents=True, exist_ok=True)
            self._conn = sqlite3.connect(self._db_path)
            self._conn.row_factory = sqlite3.Row
            self._create_table()
            logger.info(
                'History store opened: %s (%d existing readings)',
                self._db_path,
                self.count(),
            )
        except (sqlite3.Error, OSError) as exc:
            logger.warning(
                'Could not open history database at %s — '
                'running in memory-only mode: %s',
                self._db_path,
                exc,
            )
            self._conn = None

    def _create_table(self) -> None:
        """Create the readings table and index if they don't exist."""
        assert self._conn is not None
        self._conn.execute('''
            CREATE TABLE IF NOT EXISTS readings (
                id          INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp   REAL    NOT NULL,
                temperature REAL    NOT NULL,
                temperature_f REAL  NOT NULL,
                raw_temperature REAL NOT NULL,
                pressure    REAL    NOT NULL,
                storm_level INTEGER NOT NULL
            )
        ''')
        self._conn.execute('''
            CREATE INDEX IF NOT EXISTS idx_readings_timestamp
            ON readings(timestamp)
        ''')
        self._conn.commit()

    def _prune(self, max_age_seconds: int) -> int:
        """Actually delete old rows."""
        if self._conn is None:
            return 0
        try:
            cutoff = time.time() - max_age_seconds
            cursor = self._conn.execute(
                'DELETE FROM readings WHERE timestamp < ?', (cutoff,),
            )
            self._conn.commit()
            deleted = cursor.rowcount
            if deleted > 0:
                logger.info('Pruned %d readings older than %d seconds', deleted, max_age_seconds)
            return deleted
        except sqlite3.Error:
            logger.exception('Failed to prune old readings')
            return 0
