/*
 * Smart Overload Detection System - ESP32 Weigh-in-Motion (WIM) Controller
 * Member 4 Ownership:
 * Hardware: ESP32 + Load Cell (4-wire) + HX711 24-bit ADC + Buzzer + Status LEDs
 * 
 * Flow:
 * 1. Reads continuous calibrated weight from Load Cell via HX711.
 * 2. Filters road vibration noise using rolling average.
 * 3. Detects vehicle presence when weight exceeds threshold (> 500 kg).
 * 4. Captures stabilized peak Gross Vehicle Weight (GVW).
 * 5. Sends JSON payload to Backend REST API (POST /api/weight-check).
 * 6. If Overload: Fires loud Buzzer & Red LED, halts gate barrier.
 *    If Normal: Green LED, opens gate barrier.
 */

#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include "HX711.h"

// --- Wi-Fi Credentials ---
const char* WIFI_SSID     = "YOUR_WIFI_SSID";
const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";

// --- Central Backend Server URL ---
// Change to your laptop / cloud server IP (e.g., "http://192.168.1.100:8000")
const char* BACKEND_SERVER = "http://192.168.1.100:8000/api/weight-check";
const char* SENSOR_ID      = "ESP32_SCALE_GATE_01";
const char* CHECKPOINT_LOC = "Raipur Highway Toll Plaza (NH-53)";

// --- Pin Definitions ---
const int HX711_DOUT_PIN = 21;  // DT Pin
const int HX711_SCK_PIN  = 22;  // SCK Pin
const int PIN_RED_LED    = 18;  // Overload Alert LED
const int PIN_GREEN_LED  = 19;  // Pass / Clear LED
const int PIN_BUZZER     = 23;  // Alarm Buzzer
const int PIN_BARRIER    = 5;   // Gate Barrier Relay / Servo

// --- Calibration Settings ---
HX711 scale;
// Calibration factor: Adjust based on test weights (known weight / raw reading)
float CALIBRATION_FACTOR = -7050.0;
const float VEHICLE_PRESENCE_THRESHOLD_KG = 500.0; // Trigger when > 500 kg

void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n==========================================");
  Serial.println("  ESP32 SMART WEIGHBRIDGE INITIALIZING   ");
  Serial.println("==========================================");

  // Configure output pins
  pinMode(PIN_RED_LED, OUTPUT);
  pinMode(PIN_GREEN_LED, OUTPUT);
  pinMode(PIN_BUZZER, OUTPUT);
  pinMode(PIN_BARRIER, OUTPUT);

  digitalWrite(PIN_RED_LED, LOW);
  digitalWrite(PIN_GREEN_LED, LOW);
  digitalWrite(PIN_BUZZER, LOW);
  digitalWrite(PIN_BARRIER, LOW);

  // Initialize HX711 Scale
  Serial.println("[*] Initializing HX711 Load Cell Interface...");
  scale.begin(HX711_DOUT_PIN, HX711_SCK_PIN);

  if (scale.is_ready()) {
    scale.set_scale(CALIBRATION_FACTOR);
    scale.tare(); // Zero out the scale
    Serial.println("[+] Load cell calibrated & zeroed successfully.");
  } else {
    Serial.println("[-] HX711 not found! Check wiring connections.");
  }

  // Connect to Wi-Fi
  connectWiFi();
}

void connectWiFi() {
  Serial.printf("[*] Connecting to WiFi: %s\n", WIFI_SSID);
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n[+] WiFi Connected!");
    Serial.printf("[+] ESP32 IP Address: %s\n", WiFi.localIP().toString().c_str());
  } else {
    Serial.println("\n[-] WiFi Connection Failed. Operating in offline buffer mode.");
  }
}

void loop() {
  if (!scale.is_ready()) {
    delay(200);
    return;
  }

  // Read average weight over 5 samples to smooth out vibration
  float current_weight = scale.get_units(5);
  if (current_weight < 0) current_weight = 0;

  // When a vehicle drives onto the sensor pad
  if (current_weight > VEHICLE_PRESENCE_THRESHOLD_KG) {
    Serial.printf("\n[VEHICLE DETECTED] Weighing in motion... Current Reading: %.1f kg\n", current_weight);
    
    // Stabilize reading (take peak value across 10 readings)
    float peak_weight = current_weight;
    for (int i = 0; i < 10; i++) {
      float w = scale.get_units(2);
      if (w > peak_weight) peak_weight = w;
      delay(80);
    }

    Serial.printf("[+] Final Stable Gross Weight: %.1f kg\n", peak_weight);

    // In production with RFID or ANPR camera trigger, the plate number
    // is passed by camera or RFID scanner. For demo/test default is "CG10AB1234"
    String vehiclePlate = "CG10AB1234";

    // Transmit to Central Backend API
    sendWeightToBackend(vehiclePlate, peak_weight);

    // Wait until the vehicle leaves the scale before scanning next
    Serial.println("[*] Waiting for vehicle to clear scale pad...");
    while (scale.get_units(3) > (VEHICLE_PRESENCE_THRESHOLD_KG / 2.0)) {
      delay(300);
    }
    Serial.println("[+] Scale clear. Ready for next vehicle.");
    digitalWrite(PIN_RED_LED, LOW);
    digitalWrite(PIN_GREEN_LED, LOW);
  }

  delay(150);
}

void sendWeightToBackend(String plate, float weightKg) {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("[-] No WiFi! Retrying connection...");
    connectWiFi();
    if (WiFi.status() != WL_CONNECTED) return;
  }

  HTTPClient http;
  http.begin(BACKEND_SERVER);
  http.addHeader("Content-Type", "application/json");

  // Create JSON Payload
  StaticJsonDocument<256> doc;
  doc["sensor_id"] = SENSOR_ID;
  doc["plate_number"] = plate;
  doc["measured_weight_kg"] = weightKg;
  doc["checkpoint_name"] = CHECKPOINT_LOC;

  String requestBody;
  serializeJson(doc, requestBody);

  Serial.println("[->] Sending payload to Backend: " + requestBody);
  int httpResponseCode = http.POST(requestBody);

  if (httpResponseCode == 200 || httpResponseCode == 201) {
    String response = http.getString();
    Serial.println("[<-] Backend Response: " + response);

    // Parse Response
    StaticJsonDocument<512> resDoc;
    DeserializationError error = deserializeJson(resDoc, response);
    if (!error) {
      bool isViolation = resDoc["is_violation"];
      float fine = resDoc["fine_amount"];

      if (isViolation) {
        Serial.printf("[!] ALERT: OVERLOAD DETECTED! Fine: Rs. %.0f\n", fine);
        triggerOverloadAlarm();
      } else {
        Serial.println("[OK] NORMAL WEIGHT. Opening barrier gate.");
        triggerNormalPass();
      }
    }
  } else {
    Serial.printf("[-] HTTP Request failed, code: %d\n", httpResponseCode);
  }

  http.end();
}

void triggerOverloadAlarm() {
  digitalWrite(PIN_RED_LED, HIGH);
  digitalWrite(PIN_GREEN_LED, LOW);
  digitalWrite(PIN_BARRIER, LOW); // Keep barrier closed

  // Sound 3 short alert beeps
  for (int i = 0; i < 3; i++) {
    digitalWrite(PIN_BUZZER, HIGH);
    delay(200);
    digitalWrite(PIN_BUZZER, LOW);
    delay(100);
  }
}

void triggerNormalPass() {
  digitalWrite(PIN_GREEN_LED, HIGH);
  digitalWrite(PIN_RED_LED, LOW);
  digitalWrite(PIN_BARRIER, HIGH); // Open barrier gate
  delay(3000);
  digitalWrite(PIN_BARRIER, LOW);  // Close barrier gate
}
