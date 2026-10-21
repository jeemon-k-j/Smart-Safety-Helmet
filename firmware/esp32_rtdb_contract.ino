/*
 * Smart Safety Helmet — ESP32 RTDB field contract (reference sketch).
 *
 * Active RTDB:
 *   Project: smart-safety-helmet-93f6d
 *   URL:     https://smart-safety-helmet-93f6d-default-rtdb.firebaseio.com/
 *   Status:  devices/helmet-001/status
 *   Accident: devices/helmet-001/accident
 *
 * See docs/RTDB_SCHEMA.md for the full field contract.
 * Replace Wi-Fi / Firebase credentials at flash time. Ignition and warning
 * outputs are driven locally and do not wait for the network.
 *
 * Libraries (install via Arduino Library Manager as needed):
 *   - Firebase ESP Client (or Firebase Arduino Client Library for ESP8266 and ESP32)
 */

#include <Arduino.h>

// --- Local safety I/O (example pins) ---
const int PIN_ALCOHOL = 34;
const int PIN_HELMET_CLIP = 27;
const int PIN_LED = 2;
const int PIN_BUZZER = 15;
const int PIN_IGNITION_RELAY = 26;

// Thresholds are device-local; tune during calibration.
const int ALCOHOL_THRESHOLD = 1200;

bool alcoholDetected = false;
bool helmetClipped = false;
bool ignitionAllowed = false;
bool ignitionActive = false;
bool drowsy = false;
bool warningActive = false;
bool accidentActive = false;

void applyLocalSafety() {
  ignitionAllowed = helmetClipped && !alcoholDetected;
  warningActive = drowsy || accidentActive;

  digitalWrite(PIN_LED, warningActive ? HIGH : LOW);
  digitalWrite(PIN_BUZZER, warningActive ? HIGH : LOW);
  // Fail-safe: relay OFF unless allowed.
  digitalWrite(PIN_IGNITION_RELAY, ignitionAllowed ? HIGH : LOW);
}

/*
 * Status node: devices/{deviceId}/status
 *
 * {
 *   "alcoholDetected": false,
 *   "helmetClipped": true,
 *   "ignitionAllowed": true,
 *   "ignitionActive": false,
 *   "drowsy": false,
 *   "warningActive": false,
 *   "updatedAt": <epoch_ms>
 * }
 *
 * Accident node: devices/{deviceId}/accident
 *
 * {
 *   "eventId": "acc-<unique>",
 *   "active": true,
 *   "severity": "low" | "medium" | "high",
 *   "detectedAt": <epoch_ms>,
 *   "cancelled": false,
 *   "notificationSent": false
 * }
 */

void setup() {
  pinMode(PIN_HELMET_CLIP, INPUT_PULLUP);
  pinMode(PIN_LED, OUTPUT);
  pinMode(PIN_BUZZER, OUTPUT);
  pinMode(PIN_IGNITION_RELAY, OUTPUT);
  applyLocalSafety();
  // TODO: connect Wi-Fi and Firebase RTDB using your credentials.
}

void loop() {
  alcoholDetected = analogRead(PIN_ALCOHOL) > ALCOHOL_THRESHOLD;
  helmetClipped = digitalRead(PIN_HELMET_CLIP) == LOW;
  applyLocalSafety();
  // TODO: publish status / accident maps when networked.
  delay(100);
}
