"""WU-4: Main entry point — orchestrates all StormSense modules."""

import logging
import signal
import threading
import time

from storm_sense.config import (
    API_HOST,
    API_PORT,
    SAMPLE_INTERVAL_S,
    DisplayMode,
    StormLevel,
)
from storm_sense.sensor_service import SensorService
from storm_sense.hat_interface import HATInterface
from storm_sense.api_server import ApiServer

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
)
logger = logging.getLogger(__name__)


class StormSenseApp:
    """Main application orchestrator."""

    def __init__(self):
        self._sensor = SensorService()
        self._hat = HATInterface()
        self._api = ApiServer(self._sensor)
        self._shutdown_event = threading.Event()
        self._previous_storm_level = StormLevel.CLEAR

        self._wire_buttons()

    def _wire_buttons(self) -> None:
        """Connect button callbacks to display mode changes."""

        def on_button_a():
            self._sensor.display_mode = DisplayMode.TEMPERATURE
            self._hat.show_temperature(self._sensor.temperature)
            logger.info('Button A: Temperature mode')

        def on_button_b():
            self._sensor.display_mode = DisplayMode.PRESSURE
            self._hat.show_pressure(self._sensor.pressure)
            logger.info('Button B: Pressure mode')

        def on_button_c():
            self._sensor.reset_history()
            self._sensor.display_mode = DisplayMode.STORM_LEVEL
            self._hat.show_storm_level(self._sensor.storm_level)
            logger.info('Button C: Reset history, Storm Level mode')

        self._hat.on_button_a = on_button_a
        self._hat.on_button_b = on_button_b
        self._hat.on_button_c = on_button_c

    def _sensor_loop(self) -> None:
        """Background thread: read sensor and update display every SAMPLE_INTERVAL_S."""
        logger.info('Sensor loop started (interval: %ds)', SAMPLE_INTERVAL_S)
        while not self._shutdown_event.is_set():
            try:
                self._sensor.read()

                # Check for storm escalation
                current_level = self._sensor.storm_level
                if current_level > self._previous_storm_level:
                    logger.warning(
                        'Storm escalation: %s -> %s',
                        self._previous_storm_level.name,
                        current_level.name,
                    )
                    self._hat.buzz_alert(current_level)
                self._previous_storm_level = current_level

                # Update LEDs
                self._hat.update_leds(current_level)

                # Update display based on current mode
                mode = self._sensor.display_mode
                if mode == DisplayMode.TEMPERATURE:
                    self._hat.show_temperature(self._sensor.temperature)
                elif mode == DisplayMode.PRESSURE:
                    self._hat.show_pressure(self._sensor.pressure)
                elif mode == DisplayMode.STORM_LEVEL:
                    self._hat.show_storm_level(current_level)

                logger.info(
                    'Reading: %.1f°C, %.1f hPa, %s',
                    self._sensor.temperature,
                    self._sensor.pressure,
                    current_level.name,
                )

            except Exception:
                logger.exception('Error in sensor loop')
                self._hat.show_text('ERR ')

            self._shutdown_event.wait(SAMPLE_INTERVAL_S)

    def _handle_signal(self, signum, frame) -> None:
        """Handle SIGINT/SIGTERM for clean shutdown."""
        sig_name = signal.Signals(signum).name
        logger.info('Received %s, shutting down...', sig_name)
        self._shutdown_event.set()

    def run(self) -> None:
        """Start StormSense: sensor loop + Flask API."""
        signal.signal(signal.SIGINT, self._handle_signal)
        signal.signal(signal.SIGTERM, self._handle_signal)

        self._hat.show_text('INIT')
        logger.info('StormSense starting...')

        # Initial reading
        try:
            self._sensor.read()
            self._hat.update_leds(self._sensor.storm_level)
            self._hat.show_temperature(self._sensor.temperature)
        except Exception:
            logger.exception('Failed initial sensor read')
            self._hat.show_text('ERR ')

        # Start sensor loop in background
        sensor_thread = threading.Thread(
            target=self._sensor_loop, daemon=True
        )
        sensor_thread.start()

        # Run Flask in main thread
        logger.info('API server starting on %s:%d', API_HOST, API_PORT)
        try:
            self._api.run(host=API_HOST, port=API_PORT)
        except Exception:
            logger.exception('API server error')
        finally:
            self._shutdown_event.set()
            self._hat.clear_all()
            logger.info('StormSense shutdown complete')


def main():
    app = StormSenseApp()
    app.run()


if __name__ == '__main__':
    main()
