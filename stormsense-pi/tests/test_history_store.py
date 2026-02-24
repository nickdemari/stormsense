"""Tests for HistoryStore — SQLite persistence for sensor readings."""

from __future__ import annotations

import os
import sqlite3
import tempfile
import time
import unittest
from unittest.mock import patch

from storm_sense.history_store import HistoryStore, PRUNE_MAX_AGE_S


def _make_store(db_path: str | None = None) -> tuple[HistoryStore, str]:
    """Create a HistoryStore backed by a temp file. Returns (store, path)."""
    if db_path is None:
        fd, db_path = tempfile.mkstemp(suffix='.db')
        os.close(fd)
        os.unlink(db_path)  # let HistoryStore create it fresh
    store = HistoryStore(db_path=db_path)
    return store, db_path


def _sample_reading(
    ts: float = 1700000000.0,
    temp: float = 22.0,
    pressure: float = 1013.25,
    storm_level: int = 1,
) -> dict:
    """Build a reading dict matching the schema."""
    temp_f = temp * 9.0 / 5.0 + 32.0
    return {
        'timestamp': ts,
        'temperature': temp,
        'temperature_f': temp_f,
        'raw_temperature': temp + 5.0,
        'pressure': pressure,
        'storm_level': storm_level,
    }


class TestHistoryStoreBasics(unittest.TestCase):
    """Core CRUD operations on a fresh database."""

    def setUp(self):
        self.store, self.path = _make_store()

    def tearDown(self):
        self.store.close()
        if os.path.exists(self.path):
            os.unlink(self.path)

    def test_is_available_on_good_path(self):
        self.assertTrue(self.store.is_available)

    def test_empty_store_has_zero_count(self):
        self.assertEqual(self.store.count(), 0)

    def test_add_and_retrieve_single_reading(self):
        reading = _sample_reading()
        self.store.add_reading(reading)
        self.assertEqual(self.store.count(), 1)

        rows = self.store.get_history()
        self.assertEqual(len(rows), 1)
        self.assertAlmostEqual(rows[0]['timestamp'], reading['timestamp'])
        self.assertAlmostEqual(rows[0]['temperature'], reading['temperature'])
        self.assertAlmostEqual(rows[0]['pressure'], reading['pressure'])
        self.assertEqual(rows[0]['storm_level'], reading['storm_level'])

    def test_add_multiple_readings_preserves_order(self):
        for i in range(5):
            self.store.add_reading(_sample_reading(ts=1700000000.0 + i))

        rows = self.store.get_history()
        self.assertEqual(len(rows), 5)
        timestamps = [r['timestamp'] for r in rows]
        self.assertEqual(timestamps, sorted(timestamps))

    def test_get_history_respects_limit(self):
        for i in range(20):
            self.store.add_reading(_sample_reading(ts=1700000000.0 + i))

        rows = self.store.get_history(limit=5)
        self.assertEqual(len(rows), 5)

    def test_get_history_respects_since(self):
        for i in range(10):
            self.store.add_reading(_sample_reading(ts=1700000000.0 + i))

        rows = self.store.get_history(since=1700000004.5)
        self.assertEqual(len(rows), 5)
        self.assertTrue(all(r['timestamp'] > 1700000004.5 for r in rows))

    def test_get_history_since_and_limit(self):
        for i in range(10):
            self.store.add_reading(_sample_reading(ts=1700000000.0 + i))

        rows = self.store.get_history(limit=2, since=1700000004.5)
        self.assertEqual(len(rows), 2)

    def test_reading_dict_has_all_fields(self):
        self.store.add_reading(_sample_reading())
        row = self.store.get_history()[0]
        expected_keys = {
            'timestamp', 'temperature', 'temperature_f',
            'raw_temperature', 'pressure', 'storm_level',
        }
        self.assertEqual(set(row.keys()), expected_keys)


class TestHistoryStorePruning(unittest.TestCase):
    """Pruning deletes old rows and respects the hourly rate limit."""

    def setUp(self):
        self.store, self.path = _make_store()

    def tearDown(self):
        self.store.close()
        if os.path.exists(self.path):
            os.unlink(self.path)

    def test_prune_removes_old_readings(self):
        now = time.time()
        old_ts = now - 8 * 24 * 3600  # 8 days ago
        new_ts = now - 1 * 3600       # 1 hour ago

        self.store.add_reading(_sample_reading(ts=old_ts))
        self.store.add_reading(_sample_reading(ts=new_ts))
        self.assertEqual(self.store.count(), 2)

        # Force the last-prune timestamp to be old enough
        self.store._last_prune = 0
        deleted = self.store.prune_if_due(max_age_seconds=PRUNE_MAX_AGE_S)
        self.assertEqual(deleted, 1)
        self.assertEqual(self.store.count(), 1)

    def test_prune_skips_when_recently_pruned(self):
        self.store._last_prune = time.time()  # just pruned
        deleted = self.store.prune_if_due()
        self.assertEqual(deleted, 0)

    def test_prune_keeps_recent_readings(self):
        now = time.time()
        for i in range(5):
            self.store.add_reading(_sample_reading(ts=now - i * 60))

        self.store._last_prune = 0
        deleted = self.store.prune_if_due()
        self.assertEqual(deleted, 0)
        self.assertEqual(self.store.count(), 5)


class TestHistoryStoreGracefulDegradation(unittest.TestCase):
    """Store degrades to no-op when the database path is inaccessible."""

    def test_unavailable_on_bad_path(self):
        store = HistoryStore(db_path='/nonexistent/dir/that/cant/be/created/db.sqlite')
        self.assertFalse(store.is_available)
        store.close()

    def test_add_reading_noop_when_unavailable(self):
        store = HistoryStore(db_path='/nonexistent/dir/db.sqlite')
        # Should not raise
        store.add_reading(_sample_reading())
        store.close()

    def test_get_history_returns_empty_when_unavailable(self):
        store = HistoryStore(db_path='/nonexistent/dir/db.sqlite')
        self.assertEqual(store.get_history(), [])
        store.close()

    def test_count_returns_zero_when_unavailable(self):
        store = HistoryStore(db_path='/nonexistent/dir/db.sqlite')
        self.assertEqual(store.count(), 0)
        store.close()

    def test_prune_returns_zero_when_unavailable(self):
        store = HistoryStore(db_path='/nonexistent/dir/db.sqlite')
        store._last_prune = 0
        self.assertEqual(store.prune_if_due(), 0)
        store.close()


class TestHistoryStoreClose(unittest.TestCase):
    """Close is idempotent and makes operations safe no-ops."""

    def test_close_is_idempotent(self):
        store, path = _make_store()
        store.close()
        store.close()  # should not raise
        if os.path.exists(path):
            os.unlink(path)

    def test_operations_after_close_are_safe(self):
        store, path = _make_store()
        store.close()
        # All should be safe no-ops
        store.add_reading(_sample_reading())
        self.assertEqual(store.get_history(), [])
        self.assertEqual(store.count(), 0)
        if os.path.exists(path):
            os.unlink(path)


class TestHistoryStoreSchema(unittest.TestCase):
    """Database schema is correct and reopenable."""

    def test_data_survives_reopen(self):
        """Simulate a restart: close and reopen the same db file."""
        fd, path = tempfile.mkstemp(suffix='.db')
        os.close(fd)
        os.unlink(path)

        store1 = HistoryStore(db_path=path)
        for i in range(3):
            store1.add_reading(_sample_reading(ts=1700000000.0 + i))
        store1.close()

        store2 = HistoryStore(db_path=path)
        self.assertEqual(store2.count(), 3)
        rows = store2.get_history()
        self.assertEqual(len(rows), 3)
        store2.close()

        os.unlink(path)


if __name__ == '__main__':
    unittest.main()
