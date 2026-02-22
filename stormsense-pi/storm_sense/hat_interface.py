"""HATInterface -- drives the Pimoroni Rainbow HAT hardware.

Handles the 14-segment display, 7x APA102 RGB LEDs, piezo buzzer,
and capacitive touch buttons.  Falls back to a mock module on macOS
so development can happen without the physical HAT attached.
"""

from __future__ import annotations

import time
from typing import Callable

try:
    import rainbowhat as rh
except ImportError:
    from storm_sense.mocks import mock_rainbowhat as rh

from storm_sense.config import StormLevel

# ── Display label lookup ────────────────────────────────────────
_STORM_LABELS: dict[StormLevel, str] = {
    StormLevel.CLEAR: "CLR ",
    StormLevel.WATCH: "WTCH",
    StormLevel.WARNING: "WARN",
    StormLevel.SEVERE: "SEVR",
}

# ── LED palette lookup (7 LEDs each) ───────────────────────────
_LED_PALETTES: dict[StormLevel, list[tuple[int, int, int]]] = {
    StormLevel.CLEAR: [(0, 80, 0)] * 7,
    StormLevel.WATCH: [(0, 80, 0)] * 4 + [(80, 80, 0)] * 3,
    StormLevel.WARNING: [(0, 80, 0)] * 2 + [(80, 80, 0)] * 2 + [(80, 30, 0)] * 3,
    StormLevel.SEVERE: [(80, 0, 0)] * 7,
}

# ── Buzzer constants ────────────────────────────────────────────
_MIDI_C4 = 60
_MIDI_A4 = 69


class HATInterface:
    """High-level driver for the Rainbow HAT peripherals."""

    on_button_a: Callable | None
    on_button_b: Callable | None
    on_button_c: Callable | None

    def __init__(self) -> None:
        self.on_button_a = None
        self.on_button_b = None
        self.on_button_c = None

        rh.touch.A.press(self._handle_a)
        rh.touch.B.press(self._handle_b)
        rh.touch.C.press(self._handle_c)

    # ── Display methods ─────────────────────────────────────────

    def show_temperature(self, temp: float) -> None:
        """Format and display a temperature reading (e.g. '23.5')."""
        text = f"{temp:4.1f}"[:4]
        rh.display.print_str(text)
        rh.display.show()

    def show_pressure(self, pressure: float) -> None:
        """Format and display a pressure reading (e.g. '1013')."""
        text = f"{pressure:4.0f}"[:4]
        rh.display.print_str(text)
        rh.display.show()

    def show_storm_level(self, level: StormLevel) -> None:
        """Display the human-readable storm level label."""
        rh.display.print_str(_STORM_LABELS[level])
        rh.display.show()

    def show_text(self, text: str) -> None:
        """Display arbitrary text (first 4 chars)."""
        rh.display.print_str(text[:4])
        rh.display.show()

    # ── LED methods ─────────────────────────────────────────────

    def update_leds(self, level: StormLevel) -> None:
        """Set all 7 APA102 LEDs to the palette matching *level*."""
        palette = _LED_PALETTES[level]
        for i, (r, g, b) in enumerate(palette):
            rh.rainbow.set_pixel(i, r, g, b)
        rh.rainbow.show()

    # ── Buzzer methods ──────────────────────────────────────────

    def buzz_alert(self, level: StormLevel) -> None:
        """Sound a buzzer alert appropriate for *level*.

        CLEAR  -- no sound
        WATCH  -- single C4 note, 0.3 s
        WARNING / SEVERE -- three A4 notes, 0.2 s each, 0.1 s gap
        """
        if level == StormLevel.CLEAR:
            return

        if level == StormLevel.WATCH:
            rh.buzzer.midi_note(_MIDI_C4, 0.3)
            return

        # WARNING or SEVERE
        for i in range(3):
            rh.buzzer.midi_note(_MIDI_A4, 0.2)
            if i < 2:
                time.sleep(0.1)

    # ── Housekeeping ────────────────────────────────────────────

    def clear_all(self) -> None:
        """Turn off display, LEDs, and buzzer."""
        rh.display.clear()
        rh.rainbow.clear()
        rh.rainbow.show()
        rh.buzzer.stop()

    # ── Internal button handlers ────────────────────────────────

    def _handle_a(self) -> None:
        if self.on_button_a is not None:
            self.on_button_a()

    def _handle_b(self) -> None:
        if self.on_button_b is not None:
            self.on_button_b()

    def _handle_c(self) -> None:
        if self.on_button_c is not None:
            self.on_button_c()
