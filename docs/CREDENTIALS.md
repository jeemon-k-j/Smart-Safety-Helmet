# Credential-blocked configuration

Independent app, UI, RTDB models/repositories, GPS, and email **payload** work
are complete. The items below are the **only** steps blocked on client
credentials. Do not create a production Firebase project or enable paid Google
Cloud APIs without approval.

## Blocked until Firebase credentials arrive

1. Real `FIREBASE_*` values in `dart_defines.json` (see `dart_defines.example.json`)
2. Platform files from the client Firebase console / FlutterFire:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist` (when shipping iOS)
3. Enabling **Authentication → Email/Password** and creating the **Realtime Database**
   instance in the approved Firebase project
4. Deploying `database.rules.json` to that project
5. ESP32 writing to the live RTDB with the project’s database secret / auth method

Until then the app runs with **local** auth and empty device/accident
streams (no demo simulator controls in the UI).

## Blocked until SMTP / email bridge credentials arrive

1. `local-email-bridge/.env` with `TEST_EMAIL`, `SMTP_HOST`, `SMTP_USER`,
   `SMTP_PASSWORD` (and related SMTP settings)
2. Verified delivery from the bridge to a real inbox

The Flutter app already posts DeepCrash-style JSON to `EMAIL_BRIDGE_URL`. It
never stores SMTP passwords. Live email delivery is **not** claimed until the
bridge is configured and tested.

## Not required for basic phone GPS

Geolocator / device location permission is enough for accident coordinates and a
Google Maps **link** (`https://maps.google.com/?q=lat,lng`).

**No Google Maps Platform API key** is required for that basic location flow.

## Optional after credentials

| Item | Purpose |
|------|---------|
| `DEVICE_ID` dart-define | Which `devices/{id}` node the dashboard watches |
| `EMAIL_BRIDGE_URL` | LAN IP of the PC running the email bridge |

## Explicit non-claims

Until the above are provided and verified:

- Live Firebase connectivity is **not** verified
- Live emergency email delivery is **not** verified
- Hardware ESP32 ↔ RTDB integration is **not** verified
