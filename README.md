# Smart Safety Helmet

Academic Flutter project for a motorcycle / vehicle **smart safety helmet** with
ESP32 sensing, **Firebase Realtime Database** (not Cloud Firestore), Firebase
Authentication, and smartphone GPS + emergency email (adapted from
[DeepCrash / Car Crash Detection System](../Car_Crash_Detection_System)).

## Features

- **Alcohol detection** — ESP32 reports status; ignition blocked when alcohol is detected
- **Helmet wearing / clip detection** — ignition blocked when not clipped
- **Accident detection** — ESP32 raises RTDB accident events; app countdown + cancel; phone GPS; emergency email with Google Maps link
- **Drowsiness detection** — status + local LED/buzzer warning on hardware
- **Dashboard** — helmet, alcohol, ignition, accident, drowsiness
- **Emergency contacts** — email addresses managed per authenticated user
- **False-alert cancellation** — severity-based countdown (low 30s / medium 20s / high 10s); duplicate emails prevented per `eventId`
- **Crash-resistant hardware notes** — see `docs/HARDWARE.md`

## Architecture

```
lib/
  models/          Device, accident, contacts, notification, GPS types
  repositories/    Firebase RTDB access
  services/        Auth, location (DeepCrash-style), accident countdown, email bridge client
  screens/         Login, dashboard, contacts, accident alert panel
  theme/           Material 3 safety UI
firmware/          ESP32 field contract reference sketch
local-email-bridge/  SMTP bridge (DeepCrash approach)
docs/              RTDB schema + hardware
```

Ignition allow/deny and LED/buzzer warnings are **ESP32-local** and must not
depend on internet connectivity.

## Setup

### 1. Flutter

```bash
flutter pub get
flutter analyze
flutter test
```

### 2. Firebase

1. Create a Firebase project and enable **Authentication** (Email/Password) and
   **Realtime Database**.
2. Do **not** enable/use Cloud Firestore for this app.
3. Run `flutterfire configure` (or paste keys into
   `lib/config/firebase_options.dart` and `android/app/google-services.json`).
4. Deploy rules: `firebase deploy --only database` (uses `database.rules.json`).
5. Seed a device node such as `devices/helmet-001/status` (see `docs/RTDB_SCHEMA.md`).

### 3. Dart defines (optional)

Copy `dart_defines.example.json` → `dart_defines.json` (git-ignored):

```bash
flutter run --dart-define-from-file=dart_defines.json
```

### 4. Emergency email bridge

Adapted from DeepCrash. The app posts JSON to the bridge; SMTP credentials stay
on the PC.

```bash
cd local-email-bridge
cp .env.example .env   # set TEST_EMAIL + SMTP_*
npm install
npm start
```

On a physical Android phone, set `EMAIL_BRIDGE_URL` to your PC LAN IP
(e.g. `http://192.168.1.10:3000`).

### 5. Hardware

See `docs/HARDWARE.md` and `firmware/esp32_rtdb_contract.ino`.

## Verification status

Automated: `flutter pub get`, `flutter analyze`, and unit tests in this repo.

**Not claimed as verified in this scaffold:** live ESP32 connectivity, live SMTP
delivery, or a production Firebase project — those require your credentials and
hardware.

## License

Academic / coursework use.
