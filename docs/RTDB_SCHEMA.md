# Firebase Realtime Database schema

Cloud Firestore is **not** used. All live device and user data lives in RTDB.

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

## ESP32 → RTDB contract

ESP32 writes `status` and raises `accident` locally. It **must not** depend on the
phone for ignition cut-off or LED/buzzer warnings.

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

Use a new `eventId` for every distinct accident. Repeating the same id will not
trigger another email (app-side gate + bridge idempotency).

## Auth

- Authenticated users may read device nodes used by the linked helmet.
- Users may only read/write their own `users/{uid}` tree (emergency contacts).
- Deploy rules from `database.rules.json`.
