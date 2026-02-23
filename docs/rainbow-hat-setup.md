# Rainbow HAT Setup Guide

## What's in the Box

The Pimoroni Rainbow HAT is a Raspberry Pi add-on board with:

- **BMP280** — temperature + barometric pressure sensor
- **APA102** — 7 RGB LEDs (the "rainbow" arc)
- **HT16K33** — four 14-segment alphanumeric displays
- **Piezo buzzer**
- **3 capacitive touch buttons** (A, B, C)
- **3 LEDs** (red, green, blue)

```
  ┌──────────────────────────────────────────┐
  │           RAINBOW HAT (top view)         │
  │                                          │
  │    (R) (G) (B)          BMP280 sensor    │
  │   status LEDs            [chip]          │
  │                                          │
  │   🔴🟠🟡🟢🔵🟣⚪  ← 7 RGB LEDs (arc)   │
  │                                          │
  │      ┌──┬──┬──┬──┐                       │
  │      │88│88│88│88│  ← 14-seg displays    │
  │      └──┴──┴──┴──┘                       │
  │                                          │
  │    [A]    [B]    [C]  ← touch buttons    │
  │                                          │
  │   ○ piezo buzzer                         │
  │                                          │
  │  ┌─────────────────────────────────┐     │
  │  │  40-pin GPIO header (underside) │     │
  │  └─────────────────────────────────┘     │
  └──────────────────────────────────────────┘
```

## Compatible Pi Models

| Model | Compatible | Notes |
|-------|-----------|-------|
| Pi 3B | Yes | StormSense target board |
| Pi 3B+ | Yes | Use stand-offs (PoE pins) |
| Pi 4 | Yes | Use stand-offs (PoE pins) |
| Pi 5 | Yes | Use stand-offs (PoE pins) |
| Pi Zero 2 W | Yes | |
| Pi 1 / 2 | Yes | |

> **Stand-offs**: Pi 3B+ and later have PoE pins that can short against the
> HAT underside. Use nylon stand-offs between the Pi and HAT to create clearance.

## Physical Installation

```
        Step 1              Step 2              Step 3
   ┌────────────┐      ┌────────────┐      ┌────────────┐
   │  Power OFF │      │ Align pins │      │ Press down  │
   │  your Pi   │ ───> │ carefully  │ ───> │ firmly      │
   │            │      │            │      │            │
   │  ████████  │      │  ════════  │      │ ┌────────┐ │
   │  Pi board  │      │  ||||||||  │      │ │  HAT   │ │
   │            │      │  Pi board  │      │ ├────────┤ │
   └────────────┘      └────────────┘      │ │ Pi     │ │
                                           └─┴────────┘─┘
```

1. **Power off** your Raspberry Pi completely
2. **Align** the HAT's header holes with the Pi's 40-pin GPIO header
3. **Press down** gently but firmly until fully seated
4. For Pi 3B+/4/5: install nylon stand-offs first

## Software Setup

### Prerequisites

```
┌─────────────────────────────────────────────┐
│              Setup Flow                     │
│                                             │
│  Enable SPI + I2C                           │
│        │                                    │
│        v                                    │
│  Install rainbowhat library                 │
│        │                                    │
│        v                                    │
│  Reboot                                     │
│        │                                    │
│        v                                    │
│  Verify with Python import                  │
│        │                                    │
│        v                                    │
│  Clone StormSense + install deps            │
│        │                                    │
│        v                                    │
│  Run StormSense                             │
└─────────────────────────────────────────────┘
```

### Step 1: Enable SPI and I2C

The HAT uses two communication buses:
- **SPI** for the APA102 RGB LEDs
- **I2C** for the BMP280 sensor and 14-segment display

```bash
sudo raspi-config
```

Navigate to: **Interface Options** > enable both **SPI** and **I2C**.

Or edit `/boot/config.txt` directly:

```bash
sudo nano /boot/config.txt
```

Add (or uncomment):

```
dtparam=spi=on
dtparam=i2c_arm=on
```

### Step 2: Install the Rainbow HAT Library

Option A — automated installer (recommended):

```bash
curl https://get.pimoroni.com/rainbowhat | bash
```

Option B — pip:

```bash
sudo pip3 install rainbowhat
```

Option C — apt:

```bash
sudo apt-get install python3-rainbowhat
```

### Step 3: Reboot

```bash
sudo reboot
```

### Step 4: Verify Installation

```bash
python3 -c "import rainbowhat as rh; print('Temperature:', rh.weather.temperature()); print('Pressure:', rh.weather.pressure())"
```

Expected output:

```
Temperature: 25.3
Pressure: 1013.2
```

If you see numbers (not errors), the HAT is working.

## Deploy StormSense

### Step 1: Copy Files to Pi

From your development machine:

```bash
scp -r stormsense-pi/ pi@<PI_IP>:~/stormsense-pi/
```

### Step 2: Install Python Dependencies

```bash
cd ~/stormsense-pi
pip3 install -r requirements.txt
```

`requirements.txt` contains: `rainbowhat`, `flask`, `flask-cors`

### Step 3: Test Run

```bash
cd ~/stormsense-pi
python3 -m storm_sense.main
```

You should see:

```
2026-02-22 12:00:00 [INFO] StormSense starting...
2026-02-22 12:00:00 [INFO] API server starting on 0.0.0.0:5000
2026-02-22 12:00:00 [INFO] Reading: 23.5°C, 1013.2 hPa, CLEAR
```

The display should show the temperature, and all LEDs should be green.

Press `Ctrl+C` to stop.

### Step 4: Install as System Service (Auto-Start on Boot)

```bash
sudo cp ~/stormsense-pi/stormsense.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable stormsense
sudo systemctl start stormsense
```

Check status:

```bash
sudo systemctl status stormsense
```

### Step 5: Connect the Flutter App

1. Find your Pi's IP: `hostname -I`
2. Open the StormSense app on your phone
3. Enter the Pi's IP address on the connect screen
4. Tap **Connect**

```
┌──────────────┐         WiFi          ┌──────────────┐
│              │  ◄──────────────────►  │              │
│   Flutter    │    GET /api/status     │  Raspberry   │
│     App      │    GET /api/history    │   Pi + HAT   │
│              │    GET /api/health     │              │
│  (phone)     │                        │  port 5000   │
└──────────────┘                        └──────────────┘
```

## Troubleshooting 

| Problem | Fix |
|---------|-----|
| `ModuleNotFoundError: rainbowhat` | Run `sudo pip3 install rainbowhat` and reboot |
| `Permission denied` on GPIO | Run with `sudo` or add user to `gpio` group: `sudo usermod -aG gpio pi` |
| Temperature reads too high | Normal — BMP280 sits near the CPU. StormSense applies calibration automatically |
| LEDs don't light up | Check SPI is enabled: `ls /dev/spidev*` should show devices |
| Display shows nothing | Check I2C is enabled: `sudo i2cdetect -y 1` should show address `0x70` |
| Can't connect from app | Ensure Pi and phone are on same WiFi network. Check firewall: `sudo ufw allow 5000` |
| Service won't start | Check logs: `sudo journalctl -u stormsense -f` |
