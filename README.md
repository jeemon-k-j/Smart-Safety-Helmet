# Smart Safety Helmet

Academic Flutter project for a motorcycle / vehicle **smart safety helmet** with
ESP32 sensing, **Firebase Realtime Database** (not Cloud Firestore), Firebase
Authentication, and smartphone GPS + emergency email (adapted from DeepCrash /
`Car_Crash_Detection_System`).

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
  models/           Device, accident, contacts, notification, GPS types
  repositories/     Abstract + Firebase RTDB + local (credential-free) adapters
  services/         Auth, location (DeepCrash-style), accident countdown, email bridge client
  screens/          Login, Safety dashboard, Alerts (countdown + email recipients)
  bootstrap.dart    Initializes Firebase only when dart-defines are present
  app_dependencies.dart  Wires Firebase or local implementations
firmware/           ESP32 field contract reference sketch
local-email-bridge/ SMTP bridge (DeepCrash approach; secrets in .env only)
docs/               RTDB schema, hardware, CREDENTIALS
```

Bottom navigation has two requirement-derived destinations only: **Safety** and
**Alerts**. Emergency email recipients live on Alerts (not a separate Contacts tab).

Ignition allow/deny and LED/buzzer warnings are **ESP32-local** and must not
depend on internet connectivity.

Phone GPS uses the device location APIs (**no Google Maps API key** required for
coordinates or a `maps.google.com` link).

## Run without client credentials

The app starts with local auth/contacts/status repositories when Firebase
dart-defines are absent. There are **no** demo/simulator controls in the UI.

```bash
flutter pub get
flutter run
```

See **`docs/CREDENTIALS.md`** for the short list of steps still blocked on
client Firebase / SMTP credentials.

## Setup (when credentials are approved)

### 1. Flutter

```bash
flutter pub get
flutter analyze
flutter test
```

### 2. Firebase (client-provided project only)

1. Use the **approved** Firebase project; enable Email/Password Auth and RTDB.
2. Do **not** use Cloud Firestore for this app.
3. Copy `dart_defines.example.json` → `dart_defines.json` and fill `FIREBASE_*`
   (never commit real secrets). Optionally run `flutterfire configure` for
   platform files.
4. Deploy rules: `firebase deploy --only database`.
5. Seed `devices/helmet-001/status` (see `docs/RTDB_SCHEMA.md`).

```bash
flutter run --dart-define-from-file=dart_defines.json
```

### 3. Emergency email bridge

```bash
cd local-email-bridge
cp .env.example .env   # set TEST_EMAIL + SMTP_* (pending client values)
npm install
npm start
```

### 4. Hardware

See `docs/HARDWARE.md` and `firmware/esp32_rtdb_contract.ino`.

## Verification status

Automated: `flutter pub get`, `flutter analyze`, unit/widget tests.

**Not claimed:** live Firebase connectivity, live SMTP delivery, or ESP32
hardware integration — those need client credentials and devices
(`docs/CREDENTIALS.md`).

## License

Academic / coursework use.
