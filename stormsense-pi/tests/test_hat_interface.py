"""Tests for HATInterface -- display, LEDs, buzzer, and button callbacks."""

import unittest
from unittest.mock import MagicMock, call, patch

from storm_sense.config import StormLevel


# We patch the entire mock_rainbowhat module so every test gets a clean
# set of MagicMock singletons.  The patch target is the *already-imported*
# reference inside hat_interface, not the original module.
MODULE = "storm_sense.hat_interface.rh"


class TestShowTemperature(unittest.TestCase):
    """show_temperature formats to 4.1f and writes to the display."""

    @patch(MODULE)
    def test_displays_23_5(self, mock_rh: MagicMock) -> None:
        from storm_sense.hat_interface import HATInterface

        hat = HATInterface()
        hat.show_temperature(23.5)

        mock_rh.display.print_str.assert_called_with("23.5")
        mock_rh.display.show.assert_called()

    @patch(MODULE)
    def test_displays_negative(self, mock_rh: MagicMock) -> None:
        from storm_sense.hat_interface import HATInterface

        hat = HATInterface()
        hat.show_temperature(-3.2)

        mock_rh.display.print_str.assert_called_with("-3.2")

    @patch(MODULE)
    def test_truncates_long_value(self, mock_rh: MagicMock) -> None:
        from storm_sense.hat_interface import HATInterface

        hat = HATInterface()
        hat.show_temperature(123.456)

        # f'{123.456:4.1f}' == '123.5' -> [:4] == '123.'
        mock_rh.display.print_str.assert_called_with("123.")


class TestShowPressure(unittest.TestCase):
    """show_pressure formats to 4.0f and writes to the display."""

    @patch(MODULE)
    def test_displays_1013(self, mock_rh: MagicMock) -> None:
        from storm_sense.hat_interface import HATInterface

        hat = HATInterface()
        hat.show_pressure(1013.25)

        mock_rh.display.print_str.assert_called_with("1013")
        mock_rh.display.show.assert_called()

    @patch(MODULE)
    def test_displays_990(self, mock_rh: MagicMock) -> None:
        from storm_sense.hat_interface import HATInterface

        hat = HATInterface()
        hat.show_pressure(990.0)

        mock_rh.display.print_str.assert_called_with(" 990")


class TestShowStormLevel(unittest.TestCase):
    """show_storm_level writes the correct 4-char label for every level."""

    @patch(MODULE)
    def test_clear(self, mock_rh: MagicMock) -> None:
        from storm_sense.hat_interface import HATInterface

        HATInterface().show_storm_level(StormLevel.CLEAR)
        mock_rh.display.print_str.assert_called_with("CLR ")

    @patch(MODULE)
    def test_watch(self, mock_rh: MagicMock) -> None:
        from storm_sense.hat_interface import HATInterface

        HATInterface().show_storm_level(StormLevel.WATCH)
        mock_rh.display.print_str.assert_called_with("WTCH")

    @patch(MODULE)
    def test_warning(self, mock_rh: MagicMock) -> None:
        from storm_sense.hat_interface import HATInterface

        HATInterface().show_storm_level(StormLevel.WARNING)
        mock_rh.display.print_str.assert_called_with("WARN")

    @patch(MODULE)
    def test_severe(self, mock_rh: MagicMock) -> None:
        from storm_sense.hat_interface import HATInterface

        HATInterface().show_storm_level(StormLevel.SEVERE)
        mock_rh.display.print_str.assert_called_with("SEVR")

    @patch(MODULE)
    def test_show_called(self, mock_rh: MagicMock) -> None:
        from storm_sense.hat_interface import HATInterface

        HATInterface().show_storm_level(StormLevel.SEVERE)
        mock_rh.display.show.assert_called()


class TestUpdateLeds(unittest.TestCase):
    """update_leds sets all 7 APA102 LEDs to the correct palette."""

    @patch(MODULE)
    def test_clear_all_green(self, mock_rh: MagicMock) -> None:
        from storm_sense.hat_interface import HATInterface

        HATInterface().update_leds(StormLevel.CLEAR)

        expected = [call(i, 0, 80, 0) for i in range(7)]
        mock_rh.rainbow.set_pixel.assert_has_calls(expected)
        mock_rh.rainbow.show.assert_called()

    @patch(MODULE)
    def test_severe_all_red(self, mock_rh: MagicMock) -> None:
        from storm_sense.hat_interface import HATInterface

        HATInterface().update_leds(StormLevel.SEVERE)

        expected = [call(i, 80, 0, 0) for i in range(7)]
        mock_rh.rainbow.set_pixel.assert_has_calls(expected)

    @patch(MODULE)
    def test_watch_mixed(self, mock_rh: MagicMock) -> None:
        from storm_sense.hat_interface import HATInterface

        HATInterface().update_leds(StormLevel.WATCH)

        calls = mock_rh.rainbow.set_pixel.call_args_list
        # First 4 green, last 3 yellow
        for i in range(4):
            self.assertEqual(calls[i], call(i, 0, 80, 0))
        for i in range(4, 7):
            self.assertEqual(calls[i], call(i, 80, 80, 0))

    @patch(MODULE)
    def test_warning_mixed(self, mock_rh: MagicMock) -> None:
        from storm_sense.hat_interface import HATInterface

        HATInterface().update_leds(StormLevel.WARNING)

        calls = mock_rh.rainbow.set_pixel.call_args_list
        # 2 green, 2 yellow, 3 orange
        for i in range(2):
            self.assertEqual(calls[i], call(i, 0, 80, 0))
        for i in range(2, 4):
            self.assertEqual(calls[i], call(i, 80, 80, 0))
        for i in range(4, 7):
            self.assertEqual(calls[i], call(i, 80, 30, 0))


class TestBuzzAlert(unittest.TestCase):
    """buzz_alert sounds appropriate tones per storm level."""

    @patch(MODULE)
    def test_clear_no_sound(self, mock_rh: MagicMock) -> None:
        from storm_sense.hat_interface import HATInterface

        HATInterface().buzz_alert(StormLevel.CLEAR)
        mock_rh.buzzer.midi_note.assert_not_called()

    @patch(MODULE)
    def test_watch_single_c4(self, mock_rh: MagicMock) -> None:
        from storm_sense.hat_interface import HATInterface

        HATInterface().buzz_alert(StormLevel.WATCH)
        mock_rh.buzzer.midi_note.assert_called_once_with(60, 0.3)

    @patch("storm_sense.hat_interface.time")
    @patch(MODULE)
    def test_warning_triple_a4(self, mock_rh: MagicMock, mock_time: MagicMock) -> None:
        from storm_sense.hat_interface import HATInterface

        HATInterface().buzz_alert(StormLevel.WARNING)

        expected_midi = [call(69, 0.2)] * 3
        mock_rh.buzzer.midi_note.assert_has_calls(expected_midi)
        self.assertEqual(mock_rh.buzzer.midi_note.call_count, 3)

        # Two gaps between three notes
        expected_sleep = [call(0.1)] * 2
        mock_time.sleep.assert_has_calls(expected_sleep)
        self.assertEqual(mock_time.sleep.call_count, 2)

    @patch("storm_sense.hat_interface.time")
    @patch(MODULE)
    def test_severe_triple_a4(self, mock_rh: MagicMock, mock_time: MagicMock) -> None:
        from storm_sense.hat_interface import HATInterface

        HATInterface().buzz_alert(StormLevel.SEVERE)

        self.assertEqual(mock_rh.buzzer.midi_note.call_count, 3)
        mock_rh.buzzer.midi_note.assert_any_call(69, 0.2)


class TestClearAll(unittest.TestCase):
    """clear_all resets display, LEDs, and buzzer."""

    @patch(MODULE)
    def test_clear_all(self, mock_rh: MagicMock) -> None:
        from storm_sense.hat_interface import HATInterface

        HATInterface().clear_all()

        mock_rh.display.clear.assert_called_once()
        mock_rh.rainbow.clear.assert_called_once()
        mock_rh.rainbow.show.assert_called_once()
        mock_rh.buzzer.stop.assert_called_once()


class TestButtonCallbacks(unittest.TestCase):
    """Button handlers fire registered callbacks and are safe when None."""

    @patch(MODULE)
    def test_button_a_fires_callback(self, mock_rh: MagicMock) -> None:
        from storm_sense.hat_interface import HATInterface

        hat = HATInterface()
        cb = MagicMock()
        hat.on_button_a = cb

        # Grab the handler that was registered with touch.A.press()
        handler = mock_rh.touch.A.press.call_args[0][0]
        handler()

        cb.assert_called_once()

    @patch(MODULE)
    def test_button_b_fires_callback(self, mock_rh: MagicMock) -> None:
        from storm_sense.hat_interface import HATInterface

        hat = HATInterface()
        cb = MagicMock()
        hat.on_button_b = cb

        handler = mock_rh.touch.B.press.call_args[0][0]
        handler()

        cb.assert_called_once()

    @patch(MODULE)
    def test_button_c_fires_callback(self, mock_rh: MagicMock) -> None:
        from storm_sense.hat_interface import HATInterface

        hat = HATInterface()
        cb = MagicMock()
        hat.on_button_c = cb

        handler = mock_rh.touch.C.press.call_args[0][0]
        handler()

        cb.assert_called_once()

    @patch(MODULE)
    def test_button_a_safe_when_none(self, mock_rh: MagicMock) -> None:
        from storm_sense.hat_interface import HATInterface

        hat = HATInterface()
        # on_button_a is None by default -- calling handler must not raise
        handler = mock_rh.touch.A.press.call_args[0][0]
        handler()  # should not raise

    @patch(MODULE)
    def test_button_b_safe_when_none(self, mock_rh: MagicMock) -> None:
        from storm_sense.hat_interface import HATInterface

        HATInterface()
        handler = mock_rh.touch.B.press.call_args[0][0]
        handler()  # should not raise

    @patch(MODULE)
    def test_button_c_safe_when_none(self, mock_rh: MagicMock) -> None:
        from storm_sense.hat_interface import HATInterface

        HATInterface()
        handler = mock_rh.touch.C.press.call_args[0][0]
        handler()  # should not raise


class TestShowText(unittest.TestCase):
    """show_text displays arbitrary text truncated to 4 chars."""

    @patch(MODULE)
    def test_short_text(self, mock_rh: MagicMock) -> None:
        from storm_sense.hat_interface import HATInterface

        HATInterface().show_text("HI")
        mock_rh.display.print_str.assert_called_with("HI")
        mock_rh.display.show.assert_called()

    @patch(MODULE)
    def test_long_text_truncated(self, mock_rh: MagicMock) -> None:
        from storm_sense.hat_interface import HATInterface

        HATInterface().show_text("HELLO WORLD")
        mock_rh.display.print_str.assert_called_with("HELL")


if __name__ == "__main__":
    unittest.main()
