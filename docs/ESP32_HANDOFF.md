# ESP32 hardware integration handoff

Flutter + Firebase RTDB for project **smart-safety-helmet-93f6d** are complete and
tested. This document is the handoff for the ESP32 developer.

Reference sketch: `firmware/esp32_rtdb_contract.ino`  
Full schema: `docs/RTDB_SCHEMA.md`

---

## Firebase target

| Item | Value |
|------|--------|
| Project ID | `smart-safety-helmet-93f6d` |
| RTDB URL | `https://smart-safety-helmet-93f6d-default-rtdb.firebaseio.com/` |
| Device ID | `helmet-001` |

### Paths ESP32 must write

| Purpose | Path |
|---------|------|
| Live sensors / ignition | `devices/helmet-001/status` |
| Accident episode | `devices/helmet-001/accident` |

Do **not** write phone GPS or emergency-email fields. Do **not** use Cloud Firestore.

---

## Hardware responsibilities (ESP32)

| Concern | Owner | Notes |
|---------|--------|--------|
| Alcohol sensing | ESP32 | Write `alcoholDetected` |
| Helmet clip sensing | ESP32 | Write `helmetClipped` |
| Ignition allow / active | ESP32 | Decide locally; write `ignitionAllowed`, `ignitionActive` |
| Drowsiness + LED/buzzer | ESP32 | Write `drowsy`, `warningActive`; drive GPIO offline-safe |
| Accident detection + severity | ESP32 | Raise `accident` with new `eventId` |
| Smartphone GPS | **Flutter** | Not ESP32 |
| Emergency email / Maps link | **Flutter + email bridge** | Not ESP32 |
| False-alert cancel countdown | **Flutter** | ESP32 may set `active: false` if hardware clears |

Ignition cut-off and LED/buzzer **must work without internet**. Do not wait for RTDB
or the phone before acting locally.

---

## Status node — `devices/helmet-001/status`

Publish the full object periodically (or on change). Booleans must be JSON
`true` / `false` (not `0`/`1` strings).

| Field | Type | Meaning |
|-------|------|---------|
| `alcoholDetected` | boolean | Alcohol above threshold |
| `helmetClipped` | boolean | Helmet worn / clip closed |
| `ignitionAllowed` | boolean | Local decision (typically helmet clipped AND not alcohol) |
| `ignitionActive` | boolean | Engine / ignition currently on |
| `drowsy` | boolean | Drowsiness detected |
| `warningActive` | boolean | Local LED/buzzer warning active |
| `updatedAt` | number | Epoch **milliseconds** (recommended) |

### Example — clear / safe

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

### Example — alcohol + helmet off (ignition blocked)

```json
{
  "alcoholDetected": true,
  "helmetClipped": false,
  "ignitionAllowed": false,
  "ignitionActive": false,
  "drowsy": false,
  "warningActive": false,
  "updatedAt": 1710000001000
}
```

### Example — drowsiness warning

```json
{
  "alcoholDetected": false,
  "helmetClipped": true,
  "ignitionAllowed": true,
  "ignitionActive": true,
  "drowsy": true,
  "warningActive": true,
  "updatedAt": 1710000002000
}
```

If this node is missing or empty, the Flutter UI shows **Unknown / Unavailable**.
It does not invent sensor values.

---

## Accident node — `devices/helmet-001/accident`

Raise one object when a **new** accident episode starts.

| Field | Type | Who writes | Meaning |
|-------|------|------------|---------|
| `eventId` | string | ESP32 | Unique ID per episode |
| `active` | boolean | ESP32 | `true` while episode is live |
| `severity` | string | ESP32 | `"low"` \| `"medium"` \| `"high"` |
| `detectedAt` | number | ESP32 | Epoch **milliseconds** |
| `cancelled` | boolean | ESP32 / Flutter | Start `false`; Flutter may set `true` on cancel |
| `notificationSent` | boolean | Flutter | Start `false`; leave for the app |
| `latitude` / `longitude` / `mapsUrl` / `locationSource` | — | **Flutter only** | Do not set from ESP32 |

### Example — raise accident

```json
{
  "eventId": "acc-20260401T120000Z-a3f9",
  "active": true,
  "severity": "medium",
  "detectedAt": 1710000003000,
  "cancelled": false,
  "notificationSent": false
}
```

Severity drives the phone countdown before email: **high ≈ 10 s**, **medium ≈ 20 s**,
**low ≈ 30 s**.

### Unique `eventId` — avoid repeat triggers

1. Generate a **new** `eventId` for every distinct accident (e.g. `acc-` + UTC timestamp + short random suffix).
2. While that episode is active, **do not** rewrite the same `eventId` with `active: true` repeatedly to “re-fire” the alert.
3. Flutter ignores duplicate / already-processed IDs (idempotency). Reusing an ID will **not** send another emergency email.
4. When the episode ends on hardware, set `active: false` (keep the same `eventId`). Start the next accident with a **new** ID.

---

## What Flutter owns (not ESP32)

- Phone GPS for the accident location and Google Maps link  
- Emergency email recipients and the local SMTP email bridge  
- False-alert cancel UI and countdown  
- Filling `latitude`, `longitude`, `mapsUrl`, `locationSource`, and `notificationSent`

---

## Minimal integration checklist

1. Connect ESP32 to Wi-Fi and RTDB project `smart-safety-helmet-93f6d`.
2. Continuously update `devices/helmet-001/status` with the seven fields above.
3. On crash/impact, write `devices/helmet-001/accident` once with a **new** `eventId`.
4. Keep ignition + LED/buzzer local and offline-safe.
5. Leave GPS and email to the Flutter app.
