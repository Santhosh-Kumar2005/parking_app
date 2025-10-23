#include <WiFi.h>
#include <HTTPClient.h>

const char* ssid = "YOUR_SSID";
const char* password = "YOUR_PASSWORD";
const char* serverUrl = "http://your-backend-url:3000/api/sensors/update";  // Backend endpoint
const int irPin = 2;  // IR sensor OUT pin
const int spotId = 1;  // Unique spot ID (change for each ESP32)

void setup() {
  Serial.begin(115200);
  pinMode(irPin, INPUT);
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.println("Connecting to WiFi...");
  }
  Serial.println("WiFi connected!");
}

void loop() {
  int irValue = digitalRead(irPin);  // LOW if beam broken (occupied)
  String status = (irValue == LOW) ? "O" : "A";

  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    http.begin(serverUrl);
    http.addHeader("Content-Type", "application/json");
    String payload = "{\"spotId\":" + String(spotId) + ",\"status\":\"" + status + "\"}";
    int httpResponseCode = http.POST(payload);
    if (httpResponseCode > 0) {
      Serial.println("Sent: Spot " + String(spotId) + " - " + status);
    } else {
      Serial.println("Error sending data");
    }
    http.end();
  }
  delay(5000);  // Poll every 5 seconds
}