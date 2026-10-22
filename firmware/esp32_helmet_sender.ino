#include <WiFi.h>
#include <esp_now.h>
#include <Wire.h>
#include <math.h>
#include <string.h>
#include <time.h>
#include <HTTPClient.h>
#include <WiFiClientSecure.h>

// =====================================================
// PIN CONFIGURATION
// =====================================================

// MPU6050
#define SDA_PIN             21
#define SCL_PIN             22
#define IMU_ADDR            0x68

// MQ-3 alcohol sensor
#define MQ3_PIN             34

// Existing helmet IR sensor
#define IR_PIN              32

// NEW: Eye-closure IR sensor
#define EYE_IR_PIN          15

// Outputs
#define BUZZER_PIN          4
#define RED_LED_PIN         2
#define STRAP_LED_PIN       18

// Inputs
#define CANCEL_BUTTON_PIN   23
#define STRAP_SWITCH_PIN    5

// =====================================================
// EYE SENSOR SETTINGS
// =====================================================

// true  = eye sensor output LOW when eye is closed
// false = eye sensor output HIGH when eye is closed
#define EYE_CLOSED_ACTIVE_LOW true

// Eye must remain closed for 1.5 seconds
#define EYE_CLOSED_TIME_MS  1500UL

// =====================================================
// WIFI AND FIREBASE
// Realtime Database rules allow unauthenticated writes,
// so the web API key is not sent with these updates.
// =====================================================

#define WIFI_SSID           "project"
#define WIFI_PASSWORD       "project@1"
#define FIREBASE_HOST       "https://smart-safety-helmet-93f6d-default-rtdb.firebaseio.com"
#define DEVICE_ID           "helmet-001"

#define FIREBASE_INTERVAL_MS 2000UL
#define WIFI_RETRY_MS       10000UL

// IST (UTC+5:30). updatedAt still uses Firebase server time.
#define TZ_OFFSET_SEC       19800

bool wifiConnected = false;
unsigned long lastWifiRetry = 0;
unsigned long lastFirebaseAttempt = 0;

// 0 = none, 1 = new accident, 2 = rider / physical cancel
// Outcome (notificationSent) is written by Flutter — ESP32 must not
// auto-clear active:false on a timer (that aborts an in-flight email).
int pendingAccidentPush = 0;

// =====================================================
// ESP-NOW RECEIVER MAC ADDRESS (ESP32 #2)
// =====================================================

uint8_t receiverMAC[] = {
  0x68, 0x25, 0xDD, 0x32, 0xF7, 0x44
};

bool espNowReady = false;
bool lastSentRelayState = true;

// =====================================================
// ACCIDENT SETTINGS
// =====================================================
//
// Flutter owns countdown + emergency email (high 10s / medium 20s / low 30s).
// Local buzzer/LED: ACCIDENT_ALARM_MS only — does not clear RTDB.
// RTDB active stays true until: physical cancel (cancelled:true) OR Flutter
// records notificationSent. ESP32 re-arms locally by reading that outcome.
// =====================================================

#define ACCEL_SCALE         16384.0f
#define IMPACT_THRESHOLD_G  2.5f
#define IMPACT_MEDIUM_G     3.0f
#define IMPACT_HIGH_G       4.0f
#define GYRO_THRESHOLD_RAW  3500
#define IMPACT_WINDOW_MS    700UL
#define ACCIDENT_ALARM_MS   60000UL

// =====================================================
// MQ-3 SETTINGS
// =====================================================

#define MQ3_ALCOHOL_CHANGE  150
#define MQ3_WARMUP_TIME     3000UL

// =====================================================
// EXISTING IR SENSOR SETTINGS
// =====================================================

// LOW = object detected on typical digital IR modules
#define IR_ACTIVE_LOW       true

// =====================================================
// VARIABLES
// =====================================================

// MQ-3
int mq3Baseline = 0;
int previousMQ3Value = 0;

// Gyroscope calibration
float gyroBiasX = 0;
float gyroBiasY = 0;
float gyroBiasZ = 0;

// Alarm states
bool accidentAlarm = false;
bool accidentEpisodeOpen = false;
bool alcoholDetected = false;
bool safeMode = false;
bool eyeDrowsy = false;

// Current RTDB accident episode (unique eventId + severity for Flutter)
char currentEventId[48] = "";
char currentSeverity[8] = "low";

// Timers
unsigned long impactCandidateUntil = 0;
unsigned long accidentStartTime = 0;
unsigned long eyeClosedStartTime = 0;

unsigned long lastMQ3Read = 0;
unsigned long lastPrint = 0;

// Cancel button
int previousCancelState = HIGH;

// =====================================================
// ESP-NOW INITIALIZATION
// =====================================================

void connectWiFi()
{
  WiFi.mode(WIFI_STA);
  WiFi.setSleep(WIFI_PS_NONE);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  Serial.println();
  Serial.print("Connecting to WiFi");

  unsigned long start = millis();

  while (
    WiFi.status() != WL_CONNECTED &&
    millis() - start < 15000UL
  )
  {
    delay(250);
    Serial.print(".");
  }

  Serial.println();

  wifiConnected = (WiFi.status() == WL_CONNECTED);

  if (wifiConnected)
  {
    Serial.print("WiFi connected: ");
    Serial.println(WiFi.localIP());

    Serial.print("WiFi channel: ");
    Serial.println(WiFi.channel());
    Serial.println("ESP-NOW receiver must use this channel.");

    configTime(
      TZ_OFFSET_SEC,
      0,
      "pool.ntp.org",
      "time.google.com"
    );
  }
  else
  {
    Serial.println("WARNING: WiFi not connected.");
    Serial.println("Firebase updates paused.");
  }
}

void maintainWiFi(unsigned long now)
{
  if (WiFi.status() == WL_CONNECTED)
  {
    if (!wifiConnected)
    {
      wifiConnected = true;

      Serial.print("WiFi reconnected: ");
      Serial.println(WiFi.localIP());

      configTime(
        TZ_OFFSET_SEC,
        0,
        "pool.ntp.org",
        "time.google.com"
      );
    }

    return;
  }

  wifiConnected = false;

  if (now - lastWifiRetry < WIFI_RETRY_MS)
  {
    return;
  }

  lastWifiRetry = now;

  Serial.println("WiFi lost. Reconnecting...");
  WiFi.reconnect();
}

bool firebaseBegin(HTTPClient &http, WiFiClientSecure &client, const char *path)
{
  if (WiFi.status() != WL_CONNECTED)
  {
    return false;
  }

  client.setInsecure();
  client.setTimeout(4000);
  http.setTimeout(4000);

  char url[160];
  snprintf(
    url,
    sizeof(url),
    "%s%s.json",
    FIREBASE_HOST,
    path
  );

  client.stop();

  if (!http.begin(client, url))
  {
    Serial.println("Firebase connection failed.");
    return false;
  }

  return true;
}

bool firebasePatch(const char *path, const char *json)
{
  static WiFiClientSecure client;
  HTTPClient http;

  if (!firebaseBegin(http, client, path))
  {
    return false;
  }

  http.addHeader("Content-Type", "application/json");

  int code = http.PATCH(json);
  http.end();

  Serial.print("Firebase ");
  Serial.print(path);
  Serial.print(" -> ");
  Serial.println(code);

  return code == 200;
}

// Read accident node; return true when Flutter/hardware recorded an outcome
// for the current eventId (notificationSent or cancelled).
bool accidentOutcomeRecordedOnRtdb()
{
  if (currentEventId[0] == '\0')
  {
    return false;
  }

  char path[64];
  snprintf(
    path,
    sizeof(path),
    "/devices/%s/accident",
    DEVICE_ID
  );

  static WiFiClientSecure client;
  HTTPClient http;

  if (!firebaseBegin(http, client, path))
  {
    return false;
  }

  int code = http.GET();
  String body = (code == 200) ? http.getString() : String();
  http.end();

  if (code != 200 || body.length() == 0 || body == "null")
  {
    return false;
  }

  if (body.indexOf(currentEventId) < 0)
  {
    // Node replaced by a different episode — release local lock.
    return true;
  }

  const bool cancelled =
    body.indexOf("\"cancelled\":true") >= 0;
  const bool notified =
    body.indexOf("\"notificationSent\":true") >= 0;

  return cancelled || notified;
}

// Poll RTDB so we re-arm only once cancel or notificationSent is recorded.
void syncAccidentEpisodeFromRtdb()
{
  if (!accidentEpisodeOpen)
  {
    return;
  }

  if (!accidentOutcomeRecordedOnRtdb())
  {
    return;
  }

  accidentEpisodeOpen = false;
  accidentAlarm = false;

  Serial.println();
  Serial.println("================================");
  Serial.println("ACCIDENT OUTCOME ON RTDB — local episode closed");
  Serial.println("(notificationSent or cancelled; no timer clear)");
  Serial.println("================================");
}

void severityForImpact(float totalG, char *out, size_t outLen)
{
  const char *level = "low";

  if (totalG >= IMPACT_HIGH_G)
  {
    level = "high";
  }
  else if (totalG >= IMPACT_MEDIUM_G)
  {
    level = "medium";
  }

  snprintf(out, outLen, "%s", level);
}

void makeEventId(char *out, size_t outLen)
{
  // Unique per episode: timestamp + short random suffix (Flutter gate key).
  const unsigned suffix = (unsigned)(esp_random() & 0xFFFF);
  time_t sec = time(nullptr);

  if (sec > 1700000000)
  {
    struct tm t;
    gmtime_r(&sec, &t);

    snprintf(
      out,
      outLen,
      "acc-%04d%02d%02dT%02d%02d%02dZ-%04x",
      t.tm_year + 1900,
      t.tm_mon + 1,
      t.tm_mday,
      t.tm_hour,
      t.tm_min,
      t.tm_sec,
      suffix
    );

    return;
  }

  snprintf(
    out,
    outLen,
    "acc-ms%lu-%04x",
    millis(),
    suffix
  );
}

bool pushPendingAccident()
{
  if (pendingAccidentPush == 0)
  {
    return true;
  }

  char body[320];

  if (pendingAccidentPush == 1)
  {
    if (currentEventId[0] == '\0')
    {
      makeEventId(currentEventId, sizeof(currentEventId));
    }

    snprintf(
      body,
      sizeof(body),
      "{\"active\":true,\"cancelled\":false,"
      "\"detectedAt\":{\".sv\":\"timestamp\"},"
      "\"eventId\":\"%s\","
      "\"notificationSent\":false,"
      "\"severity\":\"%s\"}",
      currentEventId,
      currentSeverity
    );
  }
  else if (pendingAccidentPush == 2)
  {
    // Hardware / rider cancel — Flutter aborts countdown before email.
    if (currentEventId[0] != '\0')
    {
      snprintf(
        body,
        sizeof(body),
        "{\"eventId\":\"%s\",\"active\":false,\"cancelled\":true}",
        currentEventId
      );
    }
    else
    {
      snprintf(
        body,
        sizeof(body),
        "{\"active\":false,\"cancelled\":true}"
      );
    }
  }
  else
  {
    pendingAccidentPush = 0;
    return true;
  }

  char path[64];
  snprintf(
    path,
    sizeof(path),
    "/devices/%s/accident",
    DEVICE_ID
  );

  if (!firebasePatch(path, body))
  {
    return false;
  }

  if (pendingAccidentPush == 2)
  {
    accidentEpisodeOpen = false;
  }

  pendingAccidentPush = 0;
  return true;
}

void requestAccidentPush(int kind)
{
  pendingAccidentPush = kind;
  pushPendingAccident();

  // Send status in this same loop, alongside the accident.
  lastFirebaseAttempt = 0;
}

void pushHelmetStatus(
  bool alcohol,
  bool drowsy,
  bool clipped,
  bool ignitionActive,
  bool ignitionAllowed,
  bool warningActive,
  unsigned long now
)
{
  // One HTTPS update every 2 seconds, including retries.
  if (
    lastFirebaseAttempt != 0 &&
    now - lastFirebaseAttempt < FIREBASE_INTERVAL_MS
  )
  {
    return;
  }

  lastFirebaseAttempt = now;

  if (pendingAccidentPush != 0)
  {
    pushPendingAccident();
  }

  // Re-arm only after Flutter/hardware recorded cancel or email outcome.
  syncAccidentEpisodeFromRtdb();

  char body[320];

  snprintf(
    body,
    sizeof(body),
    "{\"alcoholDetected\":%s,"
    "\"drowsy\":%s,"
    "\"helmetClipped\":%s,"
    "\"ignitionActive\":%s,"
    "\"ignitionAllowed\":%s,"
    "\"warningActive\":%s,"
    "\"updatedAt\":{\".sv\":\"timestamp\"}}",
    alcohol ? "true" : "false",
    drowsy ? "true" : "false",
    clipped ? "true" : "false",
    ignitionActive ? "true" : "false",
    ignitionAllowed ? "true" : "false",
    warningActive ? "true" : "false"
  );

  char path[64];
  snprintf(
    path,
    sizeof(path),
    "/devices/%s/status",
    DEVICE_ID
  );

  firebasePatch(path, body);
}

void initializeESPNow()
{
  Serial.println();
  Serial.print("ESP32 #1 MAC: ");
  Serial.println(WiFi.macAddress());

  if (esp_now_init() != ESP_OK)
  {
    Serial.println("ERROR: ESP-NOW initialization failed!");
    return;
  }

  esp_now_peer_info_t peerInfo = {};

  memcpy(
    peerInfo.peer_addr,
    receiverMAC,
    6
  );

  peerInfo.channel = wifiConnected ? WiFi.channel() : 0;
  peerInfo.encrypt = false;

  if (esp_now_add_peer(&peerInfo) != ESP_OK)
  {
    Serial.println("ERROR: Failed to add receiver peer!");
    return;
  }

  espNowReady = true;

  Serial.println("ESP-NOW sender ready.");
}

// =====================================================
// SEND RELAY COMMAND TO ESP32 #2
// Payload: one bool (1 byte). true = relay ON, false = OFF.
// esp_now_send ESP_OK = queued locally — not delivery ACK.
// No send-callback / recv-callback registered on #1.
// Peer must share WiFi channel; #2 receiver sketch not in repo.
// =====================================================

void sendRelayCommand(bool relayState)
{
  if (!espNowReady)
  {
    return;
  }

  // Send only when requested state changes
  if (relayState == lastSentRelayState)
  {
    return;
  }

  esp_err_t result = esp_now_send(
    receiverMAC,
    (uint8_t *)&relayState,
    sizeof(relayState)
  );

  if (result == ESP_OK)
  {
    Serial.print("ESP-NOW command queued (not ACK'd): ");
    Serial.println(
      relayState ? "RELAY ON" : "RELAY OFF"
    );

    lastSentRelayState = relayState;
  }
  else
  {
    Serial.print("ESP-NOW send error: ");
    Serial.println(result);
  }
}

// =====================================================
// MPU6050 REGISTER WRITE
// =====================================================

bool writeRegister(byte reg, byte value)
{
  Wire.beginTransmission(IMU_ADDR);

  Wire.write(reg);
  Wire.write(value);

  byte error = Wire.endTransmission();

  if (error != 0)
  {
    Serial.print("IMU write error: ");
    Serial.println(error);
    return false;
  }

  return true;
}

// =====================================================
// READ MPU6050 DATA
// =====================================================

bool readIMU(
  int16_t &ax,
  int16_t &ay,
  int16_t &az,
  int16_t &gx,
  int16_t &gy,
  int16_t &gz
)
{
  Wire.beginTransmission(IMU_ADDR);
  Wire.write(0x3B);

  byte error = Wire.endTransmission(false);

  if (error != 0)
  {
    return false;
  }

  byte received = Wire.requestFrom(
    IMU_ADDR,
    (uint8_t)14
  );

  if (received != 14)
  {
    return false;
  }

  ax = ((int16_t)Wire.read() << 8) | Wire.read();
  ay = ((int16_t)Wire.read() << 8) | Wire.read();
  az = ((int16_t)Wire.read() << 8) | Wire.read();

  // Skip temperature registers
  Wire.read();
  Wire.read();

  gx = ((int16_t)Wire.read() << 8) | Wire.read();
  gy = ((int16_t)Wire.read() << 8) | Wire.read();
  gz = ((int16_t)Wire.read() << 8) | Wire.read();

  return true;
}

// =====================================================
// GYROSCOPE CALIBRATION
// =====================================================

void calibrateGyroscope()
{
  long totalX = 0;
  long totalY = 0;
  long totalZ = 0;

  int goodSamples = 0;

  Serial.println();
  Serial.println("Keep MPU6050 completely still.");
  Serial.println("Calibrating gyroscope...");

  for (int i = 0; i < 100; i++)
  {
    int16_t ax, ay, az;
    int16_t gx, gy, gz;

    if (readIMU(ax, ay, az, gx, gy, gz))
    {
      totalX += gx;
      totalY += gy;
      totalZ += gz;

      goodSamples++;
    }

    delay(10);
  }

  if (goodSamples > 0)
  {
    gyroBiasX = totalX / (float)goodSamples;
    gyroBiasY = totalY / (float)goodSamples;
    gyroBiasZ = totalZ / (float)goodSamples;
  }
  else
  {
    Serial.println("WARNING: IMU calibration failed!");
  }

  Serial.println("Gyroscope calibration complete.");

  Serial.print("Bias X: ");
  Serial.println(gyroBiasX);

  Serial.print("Bias Y: ");
  Serial.println(gyroBiasY);

  Serial.print("Bias Z: ");
  Serial.println(gyroBiasZ);
}

// =====================================================
// MQ-3 CALIBRATION
// =====================================================

void calibrateMQ3()
{
  Serial.println();
  Serial.println("MQ-3 warming up...");

  delay(MQ3_WARMUP_TIME);

  long total = 0;

  Serial.println("Calculating MQ-3 baseline...");

  for (int i = 0; i < 100; i++)
  {
    total += analogRead(MQ3_PIN);
    delay(100);
  }

  mq3Baseline = total / 100;

  Serial.print("MQ-3 baseline = ");
  Serial.println(mq3Baseline);

  Serial.println("MQ-3 ready.");
}

// =====================================================
// EXISTING HELMET IR SENSOR
// =====================================================

bool irDetected()
{
  int state = digitalRead(IR_PIN);

  if (IR_ACTIVE_LOW)
  {
    return state == LOW;
  }

  return state == HIGH;
}

// =====================================================
// NEW EYE-CLOSURE / DROWSINESS SENSOR
// =====================================================

void updateEyeDrowsiness(unsigned long now)
{
  int eyeState = digitalRead(EYE_IR_PIN);

  bool eyeClosedRaw;

  if (EYE_CLOSED_ACTIVE_LOW)
  {
    eyeClosedRaw = (eyeState == LOW);
  }
  else
  {
    eyeClosedRaw = (eyeState == HIGH);
  }

  if (eyeClosedRaw)
  {
    if (eyeClosedStartTime == 0)
    {
      // Record the time eye closure begins
      eyeClosedStartTime = now;
    }

    // Trigger only if closure continues for 1.5 seconds
    if (now - eyeClosedStartTime >= EYE_CLOSED_TIME_MS)
    {
      if (!eyeDrowsy)
      {
        Serial.println();
        Serial.println("********************************");
        Serial.println(" DROWSINESS / EYE CLOSURE ALERT");
        Serial.println("********************************");
      }

      eyeDrowsy = true;
    }
  }
  else
  {
    // Eye opened: clear eye-closure timer and alarm
    if (eyeDrowsy)
    {
      Serial.println("Eye opened: drowsiness alert cleared.");
    }

    eyeClosedStartTime = 0;
    eyeDrowsy = false;
  }
}

// =====================================================
// SETUP
// =====================================================

void setup()
{
  Serial.begin(115200);
  delay(300);

  // WiFi first so ESP-NOW uses the router channel
  connectWiFi();

  // Initialize ESP-NOW
  initializeESPNow();

  // Initialize I2C
  Wire.begin(SDA_PIN, SCL_PIN);
  Wire.setClock(100000);

  // Output pins
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(RED_LED_PIN, OUTPUT);
  pinMode(STRAP_LED_PIN, OUTPUT);

  // Input pins
  pinMode(CANCEL_BUTTON_PIN, INPUT_PULLUP);
  pinMode(STRAP_SWITCH_PIN, INPUT_PULLUP);
  pinMode(IR_PIN, INPUT);
  pinMode(EYE_IR_PIN, INPUT);

  // MQ-3 ADC
  analogReadResolution(12);

  // Initial output states
  digitalWrite(BUZZER_PIN, LOW);
  digitalWrite(RED_LED_PIN, LOW);
  digitalWrite(STRAP_LED_PIN, HIGH);

  // Initialize MPU6050
  Serial.println();
  Serial.println("================================");
  Serial.println("      SMART SAFETY HELMET");
  Serial.println("================================");

  Serial.println("Initializing MPU6050...");

  bool imuInitialized = writeRegister(0x6B, 0x00);
  delay(100);

  imuInitialized &= writeRegister(0x1C, 0x00);
  imuInitialized &= writeRegister(0x1B, 0x08);
  imuInitialized &= writeRegister(0x1A, 0x03);

  if (imuInitialized)
  {
    Serial.println("MPU6050 registers configured.");
  }
  else
  {
    Serial.println("WARNING: Check MPU6050 wiring.");
  }

  // Calibrate sensors
  calibrateGyroscope();
  calibrateMQ3();

  // Read initial cancel button state
  previousCancelState = digitalRead(CANCEL_BUTTON_PIN);

  // Send initial OFF command to relay receiver
  sendRelayCommand(false);

  Serial.println();
  Serial.println("================================");
  Serial.println("          SYSTEM READY");
  Serial.println("================================");

  Serial.println("Cancel button:");
  Serial.println("LOW  = SAFE / RESET");
  Serial.println("HIGH = MONITORING ACTIVE");

  Serial.println("Eye sensor: GPIO 15");
  Serial.println("Eye closure threshold: 1.5 seconds");

  if (!espNowReady)
  {
    Serial.println("WARNING: RELAY WIRELESS LINK NOT READY");
  }

  Serial.print("Firebase device: ");
  Serial.println(DEVICE_ID);
}

// =====================================================
// MAIN LOOP
// =====================================================

void loop()
{
  unsigned long now = millis();

  // ===================================================
  // 1. CANCEL BUTTON / SAFE MODE
  // ===================================================

  int cancelState = digitalRead(CANCEL_BUTTON_PIN);

  if (cancelState == LOW)
  {
    if (accidentAlarm || accidentEpisodeOpen)
    {
      requestAccidentPush(2);
    }

    safeMode = true;
    accidentAlarm = false;
    accidentEpisodeOpen = false;
    impactCandidateUntil = 0;

    digitalWrite(RED_LED_PIN, LOW);
    digitalWrite(BUZZER_PIN, LOW);
    digitalWrite(STRAP_LED_PIN, HIGH);
  }

  // Release button: resume monitoring
  if (
    previousCancelState == LOW &&
    cancelState == HIGH
  )
  {
    safeMode = false;
    accidentAlarm = false;
    impactCandidateUntil = 0;

    Serial.println();
    Serial.println("================================");
    Serial.println("ACCIDENT DETECTION ACTIVE");
    Serial.println("================================");
  }

  previousCancelState = cancelState;

  // ===================================================
  // 2. READ MPU6050
  // ===================================================

  int16_t rawAx = 0;
  int16_t rawAy = 0;
  int16_t rawAz = 0;

  int16_t rawGx = 0;
  int16_t rawGy = 0;
  int16_t rawGz = 0;

  bool imuOK = readIMU(
    rawAx, rawAy, rawAz,
    rawGx, rawGy, rawGz
  );

  float ax = 0;
  float ay = 0;
  float az = 0;
  float totalAcceleration = 0;

  float gx = 0;
  float gy = 0;
  float gz = 0;

  long gyroMovement = 0;

  if (imuOK)
  {
    // Acceleration in G
    ax = rawAx / ACCEL_SCALE;
    ay = rawAy / ACCEL_SCALE;
    az = rawAz / ACCEL_SCALE;

    totalAcceleration = sqrt(
      ax * ax + ay * ay + az * az
    );

    // Gyroscope readings corrected by calibration bias
    gx = rawGx - gyroBiasX;
    gy = rawGy - gyroBiasY;
    gz = rawGz - gyroBiasZ;

    gyroMovement =
      abs((long)gx) +
      abs((long)gy) +
      abs((long)gz);

    // ================================================
    // 3. ACCIDENT DETECTION
    // ================================================

    if (!safeMode)
    {
      if (totalAcceleration >= IMPACT_THRESHOLD_G)
      {
        impactCandidateUntil = now + IMPACT_WINDOW_MS;

        Serial.println();
        Serial.println("!!! STRONG IMPACT DETECTED !!!");
      }

      if (
        impactCandidateUntil != 0 &&
        (long)(impactCandidateUntil - now) > 0 &&
        gyroMovement >= GYRO_THRESHOLD_RAW
      )
      {
        // One RTDB episode per eventId; do not re-fire while open.
        bool newAccident = !accidentEpisodeOpen;

        accidentAlarm = true;
        impactCandidateUntil = 0;

        if (newAccident)
        {
          accidentEpisodeOpen = true;
          accidentStartTime = now;
          severityForImpact(
            totalAcceleration,
            currentSeverity,
            sizeof(currentSeverity)
          );
          makeEventId(currentEventId, sizeof(currentEventId));

          Serial.println();
          Serial.println("********************************");
          Serial.println("       ACCIDENT DETECTED");
          Serial.print("       severity=");
          Serial.println(currentSeverity);
          Serial.print("       eventId=");
          Serial.println(currentEventId);
          Serial.println("       local alarm: 60s (Flutter countdown owns email)");
          Serial.println("********************************");

          requestAccidentPush(1);
        }
        else
        {
          // Extend local alarm only; same eventId stays on RTDB.
          accidentStartTime = now;

          Serial.println();
          Serial.println("Accident still open — local alarm extended, no RTDB re-fire");
        }
      }

      // Expire impact candidate
      if (
        impactCandidateUntil != 0 &&
        (long)(now - impactCandidateUntil) >= 0
      )
      {
        impactCandidateUntil = 0;
      }
    }
  }

  // ===================================================
  // 4. LOCAL ACCIDENT ALARM ONLY (no RTDB timer clear)
  // ===================================================

  if (accidentAlarm &&
      (now - accidentStartTime >= ACCIDENT_ALARM_MS))
  {
    accidentAlarm = false;

    Serial.println();
    Serial.println("================================");
    Serial.println("LOCAL ACCIDENT ALARM COMPLETED");
    Serial.println("RTDB stays active until cancel or notificationSent");
    Serial.println("================================");
  }

  // ===================================================
  // 5. MQ-3 ALCOHOL DETECTION
  // ===================================================

  if (now - lastMQ3Read >= 300)
  {
    lastMQ3Read = now;

    int mq3Value = analogRead(MQ3_PIN);
    int mq3Change = mq3Value - mq3Baseline;

    alcoholDetected =
      (mq3Change > MQ3_ALCOHOL_CHANGE);

    Serial.print("MQ3: ");
    Serial.print(mq3Value);

    Serial.print(" | Change: ");
    Serial.print(mq3Change);

    Serial.println(
      alcoholDetected
        ? " | ALCOHOL DETECTED"
        : " | NORMAL"
    );
  }

  // ===================================================
  // 6. STRAP SWITCH
  // ===================================================

  bool strapSwitchOn =
    (digitalRead(STRAP_SWITCH_PIN) == LOW);

  bool strapSwitchOff = !strapSwitchOn;

  // ===================================================
  // 7. EXISTING IR SENSOR
  // ===================================================

  bool irNear = irDetected();

  bool strapIRAlarm =
    irNear && strapSwitchOff;

  // ===================================================
  // 8. NEW EYE-CLOSURE DETECTION
  // ===================================================

  updateEyeDrowsiness(now);

  // ===================================================
  // 9. ESP-NOW RELAY TRIGGER
  // ===================================================
  //
  // Relay ON if:
  // - Accident detected
  // - Alcohol detected
  // - Existing IR + strap alarm
  // - Drowsiness / prolonged eye closure
  //
  // Safe mode overrides these conditions.
  // ===================================================

  bool relayTrigger =
    !safeMode &&
    (
      accidentAlarm ||
      alcoholDetected ||
      strapIRAlarm ||
      eyeDrowsy
    );

  sendRelayCommand(relayTrigger);

  // ===================================================
  // 10. BUZZER AND RED LED
  // ===================================================

  if (safeMode)
  {
    digitalWrite(RED_LED_PIN, LOW);
    digitalWrite(BUZZER_PIN, LOW);
  }
  else if (
    accidentAlarm ||
    alcoholDetected ||
    strapIRAlarm ||
    eyeDrowsy
  )
  {
    digitalWrite(RED_LED_PIN, HIGH);
    digitalWrite(BUZZER_PIN, HIGH);
  }
  else
  {
    digitalWrite(RED_LED_PIN, LOW);
    digitalWrite(BUZZER_PIN, LOW);
  }

  // ===================================================
  // 11. STRAP LED
  // ===================================================

  if (safeMode)
  {
    digitalWrite(STRAP_LED_PIN, HIGH);
  }
  else if (strapSwitchOn)
  {
    digitalWrite(STRAP_LED_PIN, HIGH);
  }
  else if (strapIRAlarm)
  {
    digitalWrite(STRAP_LED_PIN, LOW);
  }
  else
  {
    digitalWrite(STRAP_LED_PIN, HIGH);
  }

  // ===================================================
  // 12. SERIAL MONITOR
  // ===================================================

  if (now - lastPrint >= 500)
  {
    lastPrint = now;

    Serial.println();
    Serial.println("--------------------------------");

    // MPU6050
    if (imuOK)
    {
      Serial.print("ACC X: ");
      Serial.print(ax, 2);

      Serial.print(" G | Y: ");
      Serial.print(ay, 2);

      Serial.print(" G | Z: ");
      Serial.print(az, 2);

      Serial.print(" G | TOTAL: ");
      Serial.print(totalAcceleration, 2);
      Serial.println(" G");

      Serial.print("GYRO X: ");
      Serial.print(gx, 0);

      Serial.print(" | Y: ");
      Serial.print(gy, 0);

      Serial.print(" | Z: ");
      Serial.println(gz, 0);
    }
    else
    {
      Serial.println("MPU6050: DATA READ FAILED");
    }

    // Cancel button
    Serial.print("Cancel Button GPIO23: ");
    Serial.println(
      cancelState == LOW
        ? "LOW - SAFE"
        : "HIGH - ACTIVE"
    );

    // Accident
    Serial.print("Accident: ");
    Serial.println(
      accidentAlarm ? "DETECTED" : "FALSE"
    );

    // Safety mode
    Serial.print("Safety State: ");
    Serial.println(
      safeMode ? "SAFE" : "MONITORING"
    );

    // Alcohol
    Serial.print("Alcohol: ");
    Serial.println(
      alcoholDetected ? "DETECTED" : "NORMAL"
    );

    // Strap
    Serial.print("Strap Switch D5: ");
    Serial.println(
      strapSwitchOn ? "ON" : "OFF"
    );

    // Existing IR
    Serial.print("Existing IR GPIO32: ");
    Serial.println(
      irNear ? "DETECTED / NEAR" : "CLEAR"
    );

    Serial.print("IR + Strap Alarm: ");
    Serial.println(
      strapIRAlarm ? "YES" : "NO"
    );

    // NEW eye sensor
    Serial.print("Eye Sensor GPIO15: ");
    Serial.println(digitalRead(EYE_IR_PIN));

    Serial.print("Eye / Drowsiness: ");
    Serial.println(
      eyeDrowsy ? "DROWSINESS DETECTED" : "NORMAL"
    );

    // Relay
    Serial.print("Relay Trigger: ");
    Serial.println(
      relayTrigger ? "ON" : "OFF"
    );

    Serial.print("ESP-NOW: ");
    Serial.println(
      espNowReady ? "READY" : "NOT READY"
    );

    if (accidentAlarm)
    {
      unsigned long elapsed =
        now - accidentStartTime;

      unsigned long remaining =
        (ACCIDENT_ALARM_MS > elapsed)
          ? ACCIDENT_ALARM_MS - elapsed
          : 0;

      Serial.print("Accident Alarm Remaining: ");
      Serial.print(remaining / 1000);
      Serial.println(" seconds");
    }

    Serial.print("Accident episode open: ");
    Serial.println(accidentEpisodeOpen ? "YES" : "NO");

    Serial.println("--------------------------------");
  }

  // ===================================================
  // 13. FIREBASE
  // ===================================================
  //
  // ignitionAllowed = local permission (strap + hazards).
  // ignitionActive = engine running — NOT available on this
  // board (no RPM/run sense). Relay ON is a cut/hazard command
  // via ESP-NOW, not proof the engine is running.
  // ===================================================

  maintainWiFi(now);

  bool ignitionAllowed =
    strapSwitchOn &&
    !alcoholDetected &&
    !eyeDrowsy &&
    !accidentAlarm &&
    !accidentEpisodeOpen &&
    !strapIRAlarm;

  bool ignitionActive = false;

  bool warningActive =
    !safeMode &&
    (
      accidentAlarm ||
      alcoholDetected ||
      strapIRAlarm ||
      eyeDrowsy
    );

  pushHelmetStatus(
    alcoholDetected,
    eyeDrowsy,
    strapSwitchOn,
    ignitionActive,
    ignitionAllowed,
    warningActive,
    now
  );

  delay(20);
}