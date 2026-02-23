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
    def test_stormy(self, mock_rh: MagicMock) -> None:
        from storm_sense.hat_interface import HATInterface

        HATInterface().show_storm_level(StormLevel.STORMY)
        mock_rh.display.print_str.assert_called_with("STRM")

    @patch(MODULE)
    def test_rain(self, mock_rh: MagicMock) -> None:
        from storm_sense.hat_interface import HATInterface

        HATInterface().show_storm_level(StormLevel.RAIN)
        mock_rh.display.print_str.assert_called_with("RAIN")

    @patch(MODULE)
    def test_change(self, mock_rh: MagicMock) -> None:
        from storm_sense.hat_interface import HATInterface

        HATInterface().show_storm_level(StormLevel.CHANGE)
        mock_rh.display.print_str.assert_called_with("CHNG")

    @patch(MODULE)
    def test_fair(self, mock_rh: MagicMock) -> None:
        from storm_sense.hat_interface import HATInterface

        HATInterface().show_storm_level(StormLevel.FAIR)
        mock_rh.display.print_str.assert_called_with("FAIR")

    @patch(MODULE)
    def test_dry(self, mock_rh: MagicMock) -> None:
        from storm_sense.hat_interface import HATInterface

        HATInterface().show_storm_level(StormLevel.DRY)
        mock_rh.display.print_str.assert_called_with("DRY ")

    @patch(MODULE)
    def test_show_called(self, mock_rh: MagicMock) -> None:
        from storm_sense.hat_interface import HATInterface

        HATInterface().show_storm_level(StormLevel.STORMY)
        mock_rh.display.show.assert_called()


class TestUpdateLeds(unittest.TestCase):
    """update_leds lights a single LED on the barometer gauge."""

    @patch(MODULE)
    def test_fair_green_at_pos_1(self, mock_rh: MagicMock) -> None:
        from storm_sense.hat_interface import HATInterface

        HATInterface().update_leds(StormLevel.FAIR)

        mock_rh.rainbow.clear.assert_called_once()
        mock_rh.rainbow.set_pixel.assert_called_once_with(1, 0, 80, 0)
        mock_rh.rainbow.show.assert_called()

    @patch(MODULE)
    def test_stormy_red_at_pos_6(self, mock_rh: MagicMock) -> None:
        from storm_sense.hat_interface import HATInterface

        HATInterface().update_leds(StormLevel.STORMY)

        mock_rh.rainbow.clear.assert_called_once()
        mock_rh.rainbow.set_pixel.assert_called_once_with(6, 80, 0, 0)

    @patch(MODULE)
    def test_rain_orange_at_pos_5(self, mock_rh: MagicMock) -> None:
        from storm_sense.hat_interface import HATInterface

        HATInterface().update_leds(StormLevel.RAIN)

        mock_rh.rainbow.set_pixel.assert_called_once_with(5, 80, 30, 0)

    @patch(MODULE)
    def test_change_yellow_at_pos_3(self, mock_rh: MagicMock) -> None:
        from storm_sense.hat_interface import HATInterface

        HATInterface().update_leds(StormLevel.CHANGE)

        mock_rh.rainbow.set_pixel.assert_called_once_with(3, 80, 80, 0)

    @patch(MODULE)
    def test_dry_cyan_at_pos_0(self, mock_rh: MagicMock) -> None:
        from storm_sense.hat_interface import HATInterface

        HATInterface().update_leds(StormLevel.DRY)

        mock_rh.rainbow.set_pixel.assert_called_once_with(0, 0, 40, 80)


class TestBuzzAlert(unittest.TestCase):
    """buzz_alert sounds appropriate tones per storm level."""

    @patch(MODULE)
    def test_fair_no_sound(self, mock_rh: MagicMock) -> None:
        from storm_sense.hat_interface import HATInterface

        HATInterface().buzz_alert(StormLevel.FAIR)
        mock_rh.buzzer.midi_note.assert_not_called()

    @patch(MODULE)
    def test_dry_no_sound(self, mock_rh: MagicMock) -> None:
        from storm_sense.hat_interface import HATInterface

        HATInterface().buzz_alert(StormLevel.DRY)
        mock_rh.buzzer.midi_note.assert_not_called()

    @patch(MODULE)
    def test_change_single_c4(self, mock_rh: MagicMock) -> None:
        from storm_sense.hat_interface import HATInterface

        HATInterface().buzz_alert(StormLevel.CHANGE)
        mock_rh.buzzer.midi_note.assert_called_once_with(60, 0.3)

    @patch("storm_sense.hat_interface.time")
    @patch(MODULE)
    def test_rain_triple_a4(self, mock_rh: MagicMock, mock_time: MagicMock) -> None:
        from storm_sense.hat_interface import HATInterface

        HATInterface().buzz_alert(StormLevel.RAIN)

        expected_midi = [call(69, 0.2)] * 3
        mock_rh.buzzer.midi_note.assert_has_calls(expected_midi)
        self.assertEqual(mock_rh.buzzer.midi_note.call_count, 3)

        expected_sleep = [call(0.1)] * 2
        mock_time.sleep.assert_has_calls(expected_sleep)
        self.assertEqual(mock_time.sleep.call_count, 2)

    @patch("storm_sense.hat_interface.time")
    @patch(MODULE)
    def test_stormy_triple_a4(self, mock_rh: MagicMock, mock_time: MagicMock) -> None:
        from storm_sense.hat_interface import HATInterface

        HATInterface().buzz_alert(StormLevel.STORMY)

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
