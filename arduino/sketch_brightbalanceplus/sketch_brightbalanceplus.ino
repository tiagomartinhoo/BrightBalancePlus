#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <ESP32Servo.h>

#define API_KEY "AIzaSyAYb6AzYYBf8jgmgK253XZK4uNz0GEuM_w"
#define DATABASE_URL "https://brightbalance-b0412-default-rtdb.europe-west1.firebasedatabase.app/"
#define WIFI_SSID "Stabs A35"
#define WIFI_PASSWORD "4instance"
#define USER_EMAIL "aas.correia@campus.fct.unl.pt"
#define USER_PASSWORD "scmu2324"

// Firebase
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;
unsigned long sendDataPrevMillis = 0;

// RGB
const int RED_PIN = 4;
const int GREEN_PIN = 5;
const int BLUE_PIN = 6;
int redValue, greenValue, blueValue, rgbState = 0;

// Light
const int OUT_PHOTO_PIN = 2;
const int IN_PHOTO_PIN = 7;
const int THRESHOLD = 1000;
int brightness, indoorLightLevel, outdoorLightLevel;

// Temperature
const int OUT_THERM_PIN = 3;
const int IN_THERM_PIN = 8;
const float BETA = 3950;
float outTemp, inTemp;

// Fan
const int FAN_PIN = 1;

// Servo
Servo motor;
const int SERVO_PIN = 15;
int currentAngle = 0;

void setup() {

  // Initialize Pins
  Serial.begin(115200);
  pinMode(RED_PIN, OUTPUT);
  pinMode(GREEN_PIN, OUTPUT);
  pinMode(BLUE_PIN, OUTPUT);
  pinMode(OUT_PHOTO_PIN, INPUT);
  pinMode(IN_PHOTO_PIN, INPUT);
  pinMode(OUT_THERM_PIN, INPUT);
  pinMode(IN_THERM_PIN, INPUT);
  pinMode(FAN_PIN, OUTPUT);
  motor.attach(SERVO_PIN);

  // Connect to WiFi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.println("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(300);
  }
  Serial.println("Connected with IP: ");
  Serial.println(WiFi.localIP());

  // Connect to Firebase
  config.api_key = API_KEY;
  auth.user.email = USER_EMAIL;
  auth.user.password = USER_PASSWORD;
  config.database_url = DATABASE_URL;
  Firebase.reconnectNetwork(true);
  fbdo.setBSSLBufferSize(4096, 1024);
  fbdo.setResponseSize(2048);
  Firebase.begin(&config, &auth);
  Firebase.setDoubleDigits(5);
  config.timeout.serverResponse = 10 * 1000;
  
}

void loop() {

  if (Firebase.ready() && (millis() - sendDataPrevMillis > 1000 || sendDataPrevMillis == 0)) {
    sendDataPrevMillis = millis();

    // Listening to RGB turning ON or OFF
    if (!Firebase.RTDB.getInt(&fbdo, "/rgb/state", &rgbState)) {
      Serial.println(fbdo.errorReason().c_str());
    }

    // Listening to RGB color changes
    int rgbUpdate;
    if (Firebase.RTDB.getInt(&fbdo, "/rgb/color/update", &rgbUpdate) && rgbUpdate) {
      if (Firebase.RTDB.getInt(&fbdo, "/rgb/color/red", &redValue) &&
      Firebase.RTDB.getInt(&fbdo, "/rgb/color/green", &greenValue) &&
      Firebase.RTDB.getInt(&fbdo, "/rgb/color/blue", &blueValue)) {
        Firebase.RTDB.setInt(&fbdo, "/rgb/color/update", 0);
      }
    } else {
      Serial.println(fbdo.errorReason().c_str());
    }

    // Listening to fan turning ON or OFF
    int fanState;
    if (Firebase.RTDB.getInt(&fbdo, "/fan/state", &fanState)) {
      digitalWrite(FAN_PIN, fanState);
    } else {
      Serial.println(fbdo.errorReason().c_str());
    }

    // Listening to blinds opening or shutting down
    int blindsUpdate;
    if (Firebase.RTDB.getInt(&fbdo, "/blinds/update", &blindsUpdate) && blindsUpdate) {
      if (Firebase.RTDB.getInt(&fbdo, "/blinds/percentage", &currentAngle)) {
        currentAngle = map(currentAngle, 0, 100, 0, 180);
        motor.write(currentAngle);
        Firebase.RTDB.setInt(&fbdo, "/blinds/update", 0);
      }
    } else {
      Serial.println(fbdo.errorReason().c_str());
    }
  }

  brightness = calculateLightingAdjustment();
  inTemp = getIndoorsTemperature();
  outTemp = getOutdoorsTemperature();
  
  Serial.print("Temperature indoors: ");
  Serial.print(inTemp);
  Serial.println(" °C");
  Serial.print("Temperature outside: ");
  Serial.print(outTemp);
  Serial.println(" °C");

  if (inTemp > outTemp) {
    Serial.println("It appears to be warmer indoors");
  } else if (inTemp < outTemp) {
    Serial.println("It appears to be warmer outside");
  } else {
    Serial.println("It is just as warm inside and outside");
  }

  getOutdoorsLighting();
  if (outdoorLightLevel > THRESHOLD) {
    Serial.println("It is daytime");
  } else {
    Serial.println("It is nighttime");
  }

  emit(rgbState);
  
  Serial.println("-----------------------------");
  delay(1000);
  
}

void emit(int state) {
  if (state) {
    analogWrite(RED_PIN, (redValue * brightness) / 255);
    analogWrite(GREEN_PIN, (greenValue * brightness) / 255);
    analogWrite(BLUE_PIN, (blueValue * brightness) / 255);
  } else {
    analogWrite(RED_PIN, LOW);
    analogWrite(GREEN_PIN, LOW);
    analogWrite(BLUE_PIN, LOW);
  }
}

int calculateLightingAdjustment() {
  indoorLightLevel = analogRead(IN_PHOTO_PIN);
  int result = map(indoorLightLevel, 0, 4095, 255, 0);
  return constrain(result, 0, 255);
}

void getOutdoorsLighting() {
  outdoorLightLevel = analogRead(OUT_PHOTO_PIN);
}

float getIndoorsTemperature() {
  int reading = analogRead(IN_THERM_PIN);
  float celsius = 1 / (log(1 / (8191. / reading - 1)) / BETA + 1.0 / 298.15) - 273.15 + 10.0; // +10ºC as error compensation
  return celsius;
}

float getOutdoorsTemperature() {
  int reading = analogRead(OUT_THERM_PIN);
  float celsius = 1 / (log(1 / (8191. / reading - 1)) / BETA + 1.0 / 298.15) - 273.15 + 10.0; // +10ºC as error compensation
  return celsius;  
}
