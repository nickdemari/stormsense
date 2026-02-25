"""ApiServer — Flask REST API for StormSense Pi weather station."""

from __future__ import annotations

from flask import Flask, jsonify, request
from flask_cors import CORS
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

from storm_sense.config import API_HOST, API_PORT
from storm_sense.sensor_service import SensorService


class ApiServer:
    """HTTP API exposing sensor status, history, and health endpoints."""

    def __init__(self, sensor_service: SensorService) -> None:
        self._sensor_service = sensor_service
        self._app = Flask(__name__)
        CORS(self._app)
        self._limiter = Limiter(
            app=self._app,
            key_func=get_remote_address,
            default_limits=["60 per minute"],
        )
        self._register_routes()

    # ── Public API ──────────────────────────────────────────────

    def run(self, host: str = API_HOST, port: int = API_PORT) -> None:
        """Start the Flask development server."""
        self._app.run(host=host, port=port)

    def get_app(self) -> Flask:
        """Return the Flask application instance (useful for testing)."""
        return self._app

    # ── Route Registration ──────────────────────────────────────

    def _register_routes(self) -> None:
        """Wire up all API endpoints."""

        @self._app.route('/api/status')
        @self._limiter.limit("30 per minute")
        def api_status():
            return jsonify(self._sensor_service.get_status())

        @self._app.route('/api/history')
        @self._limiter.limit("30 per minute")
        def api_history():
            since = request.args.get('since', 0, type=float)
            return jsonify(self._sensor_service.get_history(since=since))

        @self._app.route('/api/health')
        @self._limiter.limit("10 per minute")
        def api_health():
            return jsonify({
                'status': 'ok',
                'uptime_samples': len(self._sensor_service._pressure_history),
            })
