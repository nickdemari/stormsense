"""Drop-in mock for the rainbowhat library. Allows Pi code to run on macOS."""

import time


class _Weather:
    """Mock BMP280 sensor readings."""

    def __init__(self):
        self._temperature = 25.0
        self._pressure = 1013.25

    def temperature(self):
        return self._temperature

    def pressure(self):
        return self._pressure


class _Display:
    """Mock 14-segment alphanumeric display."""

    def print_str(self, text):
        pass

    def print_float(self, value):
        pass

    def print_number_str(self, text):
        pass

    def show(self):
        pass

    def clear(self):
        pass

    def set_decimal(self, index, state):
        pass


class _Rainbow:
    """Mock APA102 7-LED rainbow arc."""

    def set_pixel(self, index, r, g, b, brightness=0.5):
        pass

    def show(self):
        pass

    def clear(self):
        pass

    def set_all(self, r, g, b, brightness=0.5):
        pass


class _Buzzer:
    """Mock piezo buzzer."""

    def midi_note(self, note, duration):
        pass

    def note(self, frequency, duration):
        pass

    def stop(self):
        pass


class _TouchButton:
    """Mock capacitive touch button."""

    def __init__(self):
        self._press_handler = None
        self._release_handler = None

    def press(self, handler=None):
        if handler is not None:
            self._press_handler = handler

    def release(self, handler=None):
        if handler is not None:
            self._release_handler = handler

    def _simulate_press(self):
        if self._press_handler:
            self._press_handler()

    def _simulate_release(self):
        if self._release_handler:
            self._release_handler()


class _Touch:
    """Mock touch interface with three buttons."""

    def __init__(self):
        self.A = _TouchButton()
        self.B = _TouchButton()
        self.C = _TouchButton()


class _Lights:
    """Mock button LED lights."""

    def rgb(self, r, g, b):
        pass


# Module-level singletons (matches rainbowhat API)
weather = _Weather()
display = _Display()
rainbow = _Rainbow()
buzzer = _Buzzer()
touch = _Touch()
lights = _Lights()
