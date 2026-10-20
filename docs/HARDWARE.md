# Crash-resistant hardware notes (ESP32)

Safety-critical **ignition lock** and **local LED/buzzer** alerts must work
**without internet**. Firebase RTDB is for phone monitoring and emergency email
coordination only.

## Recommended components

| Role | Example | Notes |
|------|---------|--------|
| MCU | ESP32 (DevKit / WROOM) | Wi-Fi for RTDB when available |
| Battery | Li-ion / LiPo + protection | Secure pouch; foam padding |
| Alcohol | MQ-3 (or equivalent) | Calibrate threshold on device |
| Helmet clip | Limit switch / magnetic reed | Closed = worn/clipped |
| Accident | MPU6050 / SW-420 / impact switch | Local severity mapping |
| Drowsiness | IR eye blink / tilt heuristic | Prototype only |
| Warning | High-visibility LED + piezo buzzer | Driven directly from GPIO |
| Ignition relay | Automotive relay / MOSFET | Fail-safe: default OFF |

## Local logic (offline-safe)

```
ignitionAllowed = helmetClipped AND NOT alcoholDetected
if drowsy OR accidentActive:
  warningActive = true  # LED + buzzer
if NOT ignitionAllowed:
  hold ignition relay OFF
```

Do **not** wait for Firebase round-trips before cutting ignition or sounding the
buzzer.

## Enclosure requirements

- Rigid outer shell with foam / elastomer isolation for the PCB and battery.
- Strain-relieved wiring; no solder joints as primary mechanical support.
- Battery compartment isolated from impact sensors where practical.
- Waterproof or splash-resistant sealing for outdoor use.
- Mount so alcohol sensor samples exhaled breath path, not ambient wind only.

## Pin map (example — adjust to your board)

| Signal | GPIO (example) |
|--------|----------------|
| Alcohol analog | GPIO34 |
| Helmet clip digital | GPIO27 |
| IMU I2C SDA/SCL | GPIO21 / GPIO22 |
| LED warning | GPIO2 |
| Buzzer | GPIO15 |
| Ignition relay | GPIO26 |

## Phone GPS (not hardware GPS)

Accident location for emergency email comes from the **smartphone GPS** in the
Flutter app. Do not add a separate GPS module for this academic scope.

## Firmware payload

See `docs/RTDB_SCHEMA.md` and `firmware/esp32_rtdb_contract.ino` for the field
names the app expects.
