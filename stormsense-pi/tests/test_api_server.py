"""Tests for ApiServer — Flask REST API endpoints."""

import unittest
from unittest.mock import MagicMock

from flask import Flask

from storm_sense.api_server import ApiServer


def _make_mock_sensor() -> MagicMock:
    """Build a MagicMock mimicking SensorService with canned data."""
    mock = MagicMock()
    mock.get_status.return_value = {
        'temperature': 23.45,
        'raw_temperature': 28.12,
        'pressure': 1013.25,
        'storm_level': 0,
        'storm_label': 'CLEAR',
        'samples_collected': 42,
        'history_full': False,
        'display_mode': 'TEMPERATURE',
        'pressure_delta_3h': None,
    }
    mock.get_history.return_value = [{
        'timestamp': 1708635600.0,
        'temperature': 23.45,
        'raw_temperature': 28.12,
        'pressure': 1013.25,
        'storm_level': 0,
    }]
    mock._pressure_history = [None] * 42  # len() == 42 for health endpoint
    return mock


class TestStatusEndpoint(unittest.TestCase):
    """GET /api/status returns 200 with correct JSON matching all fields."""

    def setUp(self):
        self.mock_sensor = _make_mock_sensor()
        self.server = ApiServer(self.mock_sensor)
        self.client = self.server.get_app().test_client()

    def test_status_returns_200(self):
        resp = self.client.get('/api/status')
        self.assertEqual(resp.status_code, 200)

    def test_status_json_matches_all_fields(self):
        resp = self.client.get('/api/status')
        data = resp.get_json()

        self.assertAlmostEqual(data['temperature'], 23.45)
        self.assertAlmostEqual(data['raw_temperature'], 28.12)
        self.assertAlmostEqual(data['pressure'], 1013.25)
        self.assertEqual(data['storm_level'], 0)
        self.assertEqual(data['storm_label'], 'CLEAR')
        self.assertEqual(data['samples_collected'], 42)
        self.assertFalse(data['history_full'])
        self.assertEqual(data['display_mode'], 'TEMPERATURE')
        self.assertIsNone(data['pressure_delta_3h'])

    def test_status_calls_sensor_get_status(self):
        self.client.get('/api/status')
        self.mock_sensor.get_status.assert_called_once()


class TestHistoryEndpoint(unittest.TestCase):
    """GET /api/history returns 200 with JSON array."""

    def setUp(self):
        self.mock_sensor = _make_mock_sensor()
        self.server = ApiServer(self.mock_sensor)
        self.client = self.server.get_app().test_client()

    def test_history_returns_200(self):
        resp = self.client.get('/api/history')
        self.assertEqual(resp.status_code, 200)

    def test_history_returns_json_array(self):
        resp = self.client.get('/api/history')
        data = resp.get_json()

        self.assertIsInstance(data, list)
        self.assertEqual(len(data), 1)

    def test_history_entry_fields(self):
        resp = self.client.get('/api/history')
        entry = resp.get_json()[0]

        self.assertAlmostEqual(entry['timestamp'], 1708635600.0)
        self.assertAlmostEqual(entry['temperature'], 23.45)
        self.assertAlmostEqual(entry['raw_temperature'], 28.12)
        self.assertAlmostEqual(entry['pressure'], 1013.25)
        self.assertEqual(entry['storm_level'], 0)

    def test_history_calls_sensor_get_history(self):
        self.client.get('/api/history')
        self.mock_sensor.get_history.assert_called_once_with(since=0)

    def test_history_since_query_param(self):
        resp = self.client.get('/api/history?since=1708635500.0')
        self.assertEqual(resp.status_code, 200)
        self.mock_sensor.get_history.assert_called_once_with(since=1708635500.0)

    def test_history_since_invalid_falls_back_to_zero(self):
        resp = self.client.get('/api/history?since=notanumber')
        self.assertEqual(resp.status_code, 200)
        self.mock_sensor.get_history.assert_called_once_with(since=0)


class TestHealthEndpoint(unittest.TestCase):
    """GET /api/health returns 200 with {"status": "ok", "uptime_samples": 42}."""

    def setUp(self):
        self.mock_sensor = _make_mock_sensor()
        self.server = ApiServer(self.mock_sensor)
        self.client = self.server.get_app().test_client()

    def test_health_returns_200(self):
        resp = self.client.get('/api/health')
        self.assertEqual(resp.status_code, 200)

    def test_health_json_body(self):
        resp = self.client.get('/api/health')
        data = resp.get_json()

        self.assertEqual(data, {'status': 'ok', 'uptime_samples': 42})


class TestCorsHeaders(unittest.TestCase):
    """CORS headers present (Access-Control-Allow-Origin)."""

    def setUp(self):
        self.mock_sensor = _make_mock_sensor()
        self.server = ApiServer(self.mock_sensor)
        self.client = self.server.get_app().test_client()

    def test_cors_header_on_status(self):
        resp = self.client.get('/api/status')
        self.assertIn('Access-Control-Allow-Origin', resp.headers)

    def test_cors_header_on_history(self):
        resp = self.client.get('/api/history')
        self.assertIn('Access-Control-Allow-Origin', resp.headers)

    def test_cors_header_on_health(self):
        resp = self.client.get('/api/health')
        self.assertIn('Access-Control-Allow-Origin', resp.headers)

    def test_cors_preflight(self):
        resp = self.client.options(
            '/api/status',
            headers={'Origin': 'http://localhost:3000'},
        )
        self.assertIn('Access-Control-Allow-Origin', resp.headers)


class TestGetApp(unittest.TestCase):
    """get_app() returns Flask instance."""

    def test_get_app_returns_flask_instance(self):
        mock_sensor = _make_mock_sensor()
        server = ApiServer(mock_sensor)

        app = server.get_app()
        self.assertIsInstance(app, Flask)


if __name__ == '__main__':
    unittest.main()
