"""Tests for SensorService — BMP280 reading, calibration, and storm detection."""

from __future__ import annotations

import unittest
from collections import deque
from unittest.mock import patch, MagicMock

from storm_sense.config import (
    DisplayMode,
    HISTORY_MAX_SAMPLES,
    SESSION_LOG_MAX,
    StormLevel,
)
from storm_sense.sensor_service import SensorService, CPU_TEMP_PATH


def _make_service_with_mock_rh(
    temperature: float = 25.0,
    pressure: float = 1013.25,
) -> tuple[SensorService, MagicMock]:
    """Create a SensorService with a mocked rainbowhat module."""
    mock_rh = MagicMock()
    mock_rh.weather.temperature.return_value = temperature
    mock_rh.weather.pressure.return_value = pressure

    with patch('storm_sense.sensor_service.rh', mock_rh):
        svc = SensorService()
    return svc, mock_rh


class TestSensorServiceRead(unittest.TestCase):
    """read() updates all state fields correctly."""

    def test_read_updates_all_fields(self):
        svc, mock_rh = _make_service_with_mock_rh(temperature=28.0, pressure=1010.0)

        with patch('storm_sense.sensor_service.rh', mock_rh), \
             patch('storm_sense.sensor_service.SensorService._read_cpu_temp', return_value=45.0):
            svc.read()

        self.assertAlmostEqual(svc.raw_temperature, 28.0)
        # calibrated = 28 - (45-28)/1.2 ≈ 13.83
        self.assertAlmostEqual(svc.temperature, 28.0 - 17.0 / 1.2)
        self.assertAlmostEqual(svc.pressure, 1010.0)
        self.assertEqual(svc.storm_level, StormLevel.FAIR)
        self.assertEqual(len(svc._session_log), 1)
        self.assertEqual(len(svc._pressure_history), 1)


class TestTemperatureCalibration(unittest.TestCase):
    """Temperature calibration: corrected = measured - (cpu - measured) / CPU_HEAT_FACTOR."""

    def test_calibration_math(self):
        """measured=28, cpu=45, factor=1.2 -> corrected = 28 - (45-28)/1.2 ≈ 13.83."""
        svc, mock_rh = _make_service_with_mock_rh(temperature=28.0)

        with patch('storm_sense.sensor_service.rh', mock_rh), \
             patch('storm_sense.sensor_service.SensorService._read_cpu_temp', return_value=45.0):
            svc.read()

        self.assertAlmostEqual(svc.temperature, 28.0 - 17.0 / 1.2)

    def test_calibration_no_offset(self):
        """If cpu == measured, no calibration needed."""
        svc, mock_rh = _make_service_with_mock_rh(temperature=30.0)

        with patch('storm_sense.sensor_service.rh', mock_rh), \
             patch('storm_sense.sensor_service.SensorService._read_cpu_temp', return_value=30.0):
            svc.read()

        self.assertAlmostEqual(svc.temperature, 30.0)


class TestStormDetection(unittest.TestCase):
    """Storm detection based on pressure delta over rolling window."""

    def _build_pressure_drop(self, svc, mock_rh, start, end, steps=3):
        """Simulate a gradual pressure drop over multiple reads."""
        drop_per_step = (end - start) / (steps - 1)
        with patch('storm_sense.sensor_service.rh', mock_rh), \
             patch('storm_sense.sensor_service.SensorService._read_cpu_temp', return_value=45.0):
            for i in range(steps):
                mock_rh.weather.pressure.return_value = start + drop_per_step * i
                svc.read()

    def test_clear_with_stable_pressure(self):
        svc, mock_rh = _make_service_with_mock_rh(pressure=1013.0)

        with patch('storm_sense.sensor_service.rh', mock_rh), \
             patch('storm_sense.sensor_service.SensorService._read_cpu_temp', return_value=45.0):
            svc.read()
            svc.read()

        self.assertEqual(svc.storm_level, StormLevel.FAIR)
        self.assertAlmostEqual(svc.pressure_delta_3h, 0.0)

    def test_watch_threshold(self):
        """A -3.5 hPa drop triggers WATCH."""
        svc, mock_rh = _make_service_with_mock_rh()

        with patch('storm_sense.sensor_service.rh', mock_rh), \
             patch('storm_sense.sensor_service.SensorService._read_cpu_temp', return_value=45.0):
            mock_rh.weather.pressure.return_value = 1013.0
            svc.read()
            mock_rh.weather.pressure.return_value = 1009.5  # delta = -3.5
            svc.read()

        self.assertEqual(svc.storm_level, StormLevel.CHANGE)
        self.assertAlmostEqual(svc.pressure_delta_3h, -3.5)

    def test_warning_threshold(self):
        """A -6.5 hPa drop triggers WARNING."""
        svc, mock_rh = _make_service_with_mock_rh()

        with patch('storm_sense.sensor_service.rh', mock_rh), \
             patch('storm_sense.sensor_service.SensorService._read_cpu_temp', return_value=45.0):
            mock_rh.weather.pressure.return_value = 1013.0
            svc.read()
            mock_rh.weather.pressure.return_value = 1006.5  # delta = -6.5
            svc.read()

        self.assertEqual(svc.storm_level, StormLevel.RAIN)
        self.assertAlmostEqual(svc.pressure_delta_3h, -6.5)

    def test_severe_threshold(self):
        """A -10.5 hPa drop triggers SEVERE."""
        svc, mock_rh = _make_service_with_mock_rh()

        with patch('storm_sense.sensor_service.rh', mock_rh), \
             patch('storm_sense.sensor_service.SensorService._read_cpu_temp', return_value=45.0):
            mock_rh.weather.pressure.return_value = 1013.0
            svc.read()
            mock_rh.weather.pressure.return_value = 1002.5  # delta = -10.5
            svc.read()

        self.assertEqual(svc.storm_level, StormLevel.STORMY)
        self.assertAlmostEqual(svc.pressure_delta_3h, -10.5)

    def test_storm_deescalation(self):
        """SEVERE -> reset -> CLEAR."""
        svc, mock_rh = _make_service_with_mock_rh()

        with patch('storm_sense.sensor_service.rh', mock_rh), \
             patch('storm_sense.sensor_service.SensorService._read_cpu_temp', return_value=45.0):
            mock_rh.weather.pressure.return_value = 1013.0
            svc.read()
            mock_rh.weather.pressure.return_value = 1002.0  # SEVERE
            svc.read()

        self.assertEqual(svc.storm_level, StormLevel.STORMY)

        svc.reset_history()
        self.assertEqual(svc.storm_level, StormLevel.FAIR)
        self.assertIsNone(svc.pressure_delta_3h)

    def test_delta_none_with_single_sample(self):
        svc, mock_rh = _make_service_with_mock_rh()

        with patch('storm_sense.sensor_service.rh', mock_rh), \
             patch('storm_sense.sensor_service.SensorService._read_cpu_temp', return_value=45.0):
            svc.read()

        self.assertIsNone(svc.pressure_delta_3h)
        self.assertEqual(svc.storm_level, StormLevel.FAIR)

    def test_exact_boundary_thresholds(self):
        """Exactly -3.0, -6.0, -10.0 should trigger WATCH, WARNING, SEVERE."""
        svc, mock_rh = _make_service_with_mock_rh()

        with patch('storm_sense.sensor_service.rh', mock_rh), \
             patch('storm_sense.sensor_service.SensorService._read_cpu_temp', return_value=45.0):
            # Exactly -3.0 -> WATCH
            mock_rh.weather.pressure.return_value = 1013.0
            svc.read()
            mock_rh.weather.pressure.return_value = 1010.0
            svc.read()
        self.assertEqual(svc.storm_level, StormLevel.CHANGE)

        svc.reset_history()

        with patch('storm_sense.sensor_service.rh', mock_rh), \
             patch('storm_sense.sensor_service.SensorService._read_cpu_temp', return_value=45.0):
            # Exactly -6.0 -> WARNING
            mock_rh.weather.pressure.return_value = 1013.0
            svc.read()
            mock_rh.weather.pressure.return_value = 1007.0
            svc.read()
        self.assertEqual(svc.storm_level, StormLevel.RAIN)

        svc.reset_history()

        with patch('storm_sense.sensor_service.rh', mock_rh), \
             patch('storm_sense.sensor_service.SensorService._read_cpu_temp', return_value=45.0):
            # Exactly -10.0 -> SEVERE
            mock_rh.weather.pressure.return_value = 1013.0
            svc.read()
            mock_rh.weather.pressure.return_value = 1003.0
            svc.read()
        self.assertEqual(svc.storm_level, StormLevel.STORMY)


class TestHistoryCaps(unittest.TestCase):
    """Pressure history and session log respect their maxlen bounds."""

    def test_pressure_history_capped(self):
        svc, mock_rh = _make_service_with_mock_rh()

        with patch('storm_sense.sensor_service.rh', mock_rh), \
             patch('storm_sense.sensor_service.SensorService._read_cpu_temp', return_value=45.0):
            for _ in range(HISTORY_MAX_SAMPLES + 50):
                svc.read()

        self.assertEqual(len(svc._pressure_history), HISTORY_MAX_SAMPLES)

    def test_session_log_capped(self):
        svc, mock_rh = _make_service_with_mock_rh()

        with patch('storm_sense.sensor_service.rh', mock_rh), \
             patch('storm_sense.sensor_service.SensorService._read_cpu_temp', return_value=45.0):
            for _ in range(SESSION_LOG_MAX + 50):
                svc.read()

        self.assertEqual(len(svc._session_log), SESSION_LOG_MAX)


class TestGetStatus(unittest.TestCase):
    """get_status() returns the correct shape with all required keys."""

    def test_status_keys_and_types(self):
        svc, mock_rh = _make_service_with_mock_rh(temperature=28.0, pressure=1013.0)

        with patch('storm_sense.sensor_service.rh', mock_rh), \
             patch('storm_sense.sensor_service.SensorService._read_cpu_temp', return_value=45.0):
            svc.read()

        status = svc.get_status()

        required_keys = {
            'temperature', 'temperature_f', 'raw_temperature', 'pressure',
            'storm_level', 'storm_label', 'samples_collected',
            'history_full', 'display_mode', 'pressure_delta_3h',
        }
        self.assertEqual(set(status.keys()), required_keys)

        self.assertIsInstance(status['temperature'], float)
        self.assertIsInstance(status['temperature_f'], float)
        self.assertIsInstance(status['raw_temperature'], float)
        self.assertIsInstance(status['pressure'], float)
        self.assertIsInstance(status['storm_level'], int)
        self.assertIsInstance(status['storm_label'], str)
        self.assertIsInstance(status['samples_collected'], int)
        self.assertIsInstance(status['history_full'], bool)
        self.assertIsInstance(status['display_mode'], str)

    def test_status_values_after_read(self):
        svc, mock_rh = _make_service_with_mock_rh(temperature=28.0, pressure=1013.0)

        with patch('storm_sense.sensor_service.rh', mock_rh), \
             patch('storm_sense.sensor_service.SensorService._read_cpu_temp', return_value=45.0):
            svc.read()

        status = svc.get_status()
        expected_temp = 28.0 - 17.0 / 1.2
        self.assertAlmostEqual(status['temperature'], expected_temp)
        self.assertAlmostEqual(status['temperature_f'], expected_temp * 9.0 / 5.0 + 32.0)
        self.assertAlmostEqual(status['raw_temperature'], 28.0)
        self.assertAlmostEqual(status['pressure'], 1013.0)
        self.assertEqual(status['storm_level'], 1)
        self.assertEqual(status['storm_label'], 'FAIR')
        self.assertEqual(status['samples_collected'], 1)
        self.assertFalse(status['history_full'])
        self.assertEqual(status['display_mode'], 'TEMPERATURE')
        self.assertIsNone(status['pressure_delta_3h'])


class TestGetHistory(unittest.TestCase):
    """get_history() returns list of dicts with all required keys."""

    def test_history_shape(self):
        svc, mock_rh = _make_service_with_mock_rh(temperature=28.0, pressure=1013.0)

        with patch('storm_sense.sensor_service.rh', mock_rh), \
             patch('storm_sense.sensor_service.SensorService._read_cpu_temp', return_value=45.0):
            svc.read()
            svc.read()

        history = svc.get_history()
        self.assertIsInstance(history, list)
        self.assertEqual(len(history), 2)

        required_keys = {'timestamp', 'temperature', 'temperature_f', 'raw_temperature', 'pressure', 'storm_level'}
        for entry in history:
            self.assertEqual(set(entry.keys()), required_keys)
            self.assertIsInstance(entry['timestamp'], float)
            self.assertIsInstance(entry['temperature'], float)
            self.assertIsInstance(entry['temperature_f'], float)
            self.assertIsInstance(entry['raw_temperature'], float)
            self.assertIsInstance(entry['pressure'], float)
            self.assertIsInstance(entry['storm_level'], int)


class TestResetHistory(unittest.TestCase):
    """reset_history() clears everything and resets storm state."""

    def test_reset_clears_all(self):
        svc, mock_rh = _make_service_with_mock_rh()

        with patch('storm_sense.sensor_service.rh', mock_rh), \
             patch('storm_sense.sensor_service.SensorService._read_cpu_temp', return_value=45.0):
            for _ in range(5):
                svc.read()

        self.assertGreater(len(svc._pressure_history), 0)
        self.assertGreater(len(svc._session_log), 0)

        svc.reset_history()

        self.assertEqual(len(svc._pressure_history), 0)
        self.assertEqual(len(svc._session_log), 0)
        self.assertEqual(svc.storm_level, StormLevel.FAIR)
        self.assertIsNone(svc.pressure_delta_3h)


class TestCpuTempFallback(unittest.TestCase):
    """CPU temp fallback when sysfs is unavailable (macOS)."""

    def test_fallback_on_missing_file(self):
        svc, _ = _make_service_with_mock_rh()

        with patch('builtins.open', side_effect=FileNotFoundError):
            result = svc._read_cpu_temp()

        self.assertAlmostEqual(result, 45.0)

    def test_fallback_on_os_error(self):
        svc, _ = _make_service_with_mock_rh()

        with patch('builtins.open', side_effect=OSError):
            result = svc._read_cpu_temp()

        self.assertAlmostEqual(result, 45.0)

    def test_reads_real_value_when_available(self):
        svc, _ = _make_service_with_mock_rh()

        mock_file = MagicMock()
        mock_file.__enter__ = MagicMock(return_value=mock_file)
        mock_file.__exit__ = MagicMock(return_value=False)
        mock_file.read.return_value = '52000\n'

        with patch('builtins.open', return_value=mock_file):
            result = svc._read_cpu_temp()

        self.assertAlmostEqual(result, 52.0)


if __name__ == '__main__':
    unittest.main()
