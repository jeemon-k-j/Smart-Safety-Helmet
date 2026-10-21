# Firebase Realtime Database schema

Cloud Firestore is **not** used. All live device and user data lives in RTDB.

## Active project (Flutter + ESP32)

| Item | Value |
|------|--------|
| Project ID | `smart-safety-helmet-93f6d` |
| RTDB URL | `https://smart-safety-helmet-93f6d-default-rtdb.firebaseio.com/` |
| Default device id | `helmet-001` |

The Flutter app watches **`devices/helmet-001/status`** and
**`devices/helmet-001/accident`** by default (`DEVICE_ID` dart-define).

RTDB rules for this project intentionally allow hardware read/write for ESP32
integration. Do not change deployed rules from the app side.

## Paths

```
devices/{deviceId}/status
  alcoholDetected: boolean
  helmetClipped: boolean
  ignitionAllowed: boolean      # ESP32 local decision
  ignitionActive: boolean
  drowsy: boolean
  warningActive: boolean        # LED / buzzer
  updatedAt: number             # epoch ms

devices/{deviceId}/accident
  eventId: string               # unique per accident episode
  active: boolean
  severity: "low" | "medium" | "high"
  detectedAt: number            # epoch ms
  cancelled: boolean
  notificationSent: boolean
  latitude: number?             # filled by phone after GPS
  longitude: number?
  mapsUrl: string?
  locationSource: string?       # phoneGps | phoneGpsStale

users/{uid}/emergencyContacts/{contactId}
  name: string
  email: string
  createdAt: number

users/{uid}/linkedDeviceId: string
```

## Exact ESP32 paths (default device)

Write status to:

`https://smart-safety-helmet-93f6d-default-rtdb.firebaseio.com/devices/helmet-001/status`

Raise accidents at:

`https://smart-safety-helmet-93f6d-default-rtdb.firebaseio.com/devices/helmet-001/accident`

## ESP32 → RTDB contract

ESP32 writes `status` and raises `accident` locally. It **must not** depend on the
phone for ignition cut-off or LED/buzzer warnings.

If `devices/helmet-001/status` is missing or empty, the Flutter UI shows
**Unknown / Unavailable** — it does not invent sensor values.

### Status update example

```json
{
  "alcoholDetected": false,
  "helmetClipped": true,
  "ignitionAllowed": true,
  "ignitionActive": false,
  "drowsy": false,
  "warningActive": false,
  "updatedAt": 1710000000000
}
```

Required boolean fields for a usable status reading:

- `alcoholDetected`
- `helmetClipped`
- `ignitionAllowed`
- `ignitionActive`
- `drowsy`
- `warningActive`

`updatedAt` is recommended (epoch milliseconds).

### Accident raise example

```json
{
  "eventId": "acc-2026-04-01T12:00:00Z",
  "active": true,
  "severity": "medium",
  "detectedAt": 1710000000000,
  "cancelled": false,
  "notificationSent": false
}
```

Required fields when raising an accident:

- `eventId` (new unique string per episode)
- `active` (`true` while the alert is live)
- `severity` (`low` | `medium` | `high`)

Use a new `eventId` for every distinct accident. Repeating the same id will not
trigger another email (app-side gate + bridge idempotency).

Leave `latitude`, `longitude`, `mapsUrl`, and `locationSource` for the phone app
to fill after GPS resolution.
