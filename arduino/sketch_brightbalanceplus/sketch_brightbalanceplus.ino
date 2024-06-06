#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <ESP32Servo.h>

#define API_KEY "AIzaSyAYb6AzYYBf8jgmgK253XZK4uNz0GEuM_w"
#define PROJECT_ID "brightbalance-b0412"
#define DATABASE_URL "brightbalance-b0412.firebaseapp.com"
#define WIFI_SSID "Stabs A35"
#define WIFI_PASSWORD "4instance"
#define USER_EMAIL "aas.correia@campus.fct.unl.pt"
#define USER_PASSWORD "scmu2324"

// Firebase
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// RGB
const int RED_PIN = 4;
const int GREEN_PIN = 5;
const int BLUE_PIN = 6;

// Light
const int OUT_PHOTO_PIN = 2;
const int IN_PHOTO_PIN = 7;
int outdoorLightLevel, indoorLightLevel;
int brightness;

// Temperature
const int OUT_THERM_PIN = 3;
const int IN_THERM_PIN = 8;
const float BETA = 3950;
float outdoorTemperature, indoorTemperature;

// Fan
const int FAN_PIN = 1;

// Servo
Servo motor;
const int SERVO_PIN = 15;
int currentAngle = 0;

void setup() {
  
  Serial.begin(115200);

  // Initialize Pins
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
  Serial.printf("Connected with IP: %s\n", WiFi.localIP());

  // Connect to Firebase
  config.api_key = API_KEY;
  auth.user.email = USER_EMAIL;
  auth.user.password = USER_PASSWORD;
  config.database_url = DATABASE_URL;
  Firebase.begin(&config, &auth);
  
}

void loop() {

  brightness = calculateLightingAdjustment();
  getOutdoorsLighting();
  indoorTemperature = getIndoorsTemperature();
  outdoorTemperature = getOutdoorsTemperature();

  Serial.println("\n----- Readings -----\n");

  // Update lighting readings
  String documentPathLight = "readingsLight/lighting";
  FirebaseJson contentLight;
  contentLight.set("fields/indoor/integerValue", String(indoorLightLevel).c_str());
  contentLight.set("fields/outdoor/integerValue", String(outdoorLightLevel).c_str());
  if (Firebase.Firestore.patchDocument(&fbdo, PROJECT_ID, "", documentPathLight.c_str(), contentLight.raw(), "indoor,outdoor")) {
    //Serial.printf("\n%s\n", fbdo.payload().c_str());
    Serial.println("Lighting readings were sent to the database");
  } else {
    Serial.println(fbdo.errorReason().c_str());
  }

  // Update temperature readings
  String documentPathTemp = "readingsTemp/temperature";
  FirebaseJson contentTemp;
  contentTemp.set("fields/indoor/doubleValue", String(indoorTemperature).c_str());
  contentTemp.set("fields/outdoor/doubleValue", String(outdoorTemperature).c_str());
  if (Firebase.Firestore.patchDocument(&fbdo, PROJECT_ID, "", documentPathTemp.c_str(), contentTemp.raw(), "indoor,outdoor")) {
    //Serial.printf("\n%s\n", fbdo.payload().c_str());
    Serial.println("Temperature readings were sent to the database");
  } else {
    Serial.println(fbdo.errorReason().c_str());
  }

  Serial.println("----- Devices -----\n");

  // Get blinds level
  String documentPathBlinds = "devices/blinds";
  if (Firebase.Firestore.getDocument(&fbdo, PROJECT_ID, "", documentPathBlinds.c_str())) {
    FirebaseJson contentBlinds;
    FirebaseJsonData blindsLevel;
    contentBlinds.setJsonData(fbdo.payload().c_str());
    contentBlinds.get(blindsLevel, "fields/percentage/integerValue");
    // Raise or lower blinds according to state
    Serial.printf("\nBlinds are leveled at %d%%\n", blindsLevel.intValue);
    currentAngle = map(blindsLevel.intValue, 0, 100, 0, 180);
    motor.write(currentAngle);
  } else {
    Serial.println(fbdo.errorReason().c_str());
  }
  
  // Get fan state
  String documentPathFan = "devices/fan";
  if (Firebase.Firestore.getDocument(&fbdo, PROJECT_ID, "", documentPathFan.c_str())) {
    FirebaseJson contentFan;
    FirebaseJsonData fanState;
    contentFan.setJsonData(fbdo.payload().c_str());
    contentFan.get(fanState, "fields/state/booleanValue");
    // Turn fan ON or OFF according to state
    Serial.printf("Fan is turned on? %s\n", fanState.boolValue ? "Yes" : "No");
    digitalWrite(FAN_PIN, fanState.boolValue);
  } else {
    Serial.println(fbdo.errorReason().c_str());
  }

  // Get RGB state
  String documentPathRGB = "devices/rgb";
  if (Firebase.Firestore.getDocument(&fbdo, PROJECT_ID, "", documentPathRGB.c_str())) {
    FirebaseJson contentRGB;
    FirebaseJsonData rgbState, rgbR, rgbG, rgbB;
    contentRGB.setJsonData(fbdo.payload().c_str());
    contentRGB.get(rgbState, "fields/state/booleanValue");
    contentRGB.get(rgbR, "fields/red/integerValue");
    contentRGB.get(rgbG, "fields/green/integerValue");
    contentRGB.get(rgbB, "fields/blue/integerValue");
    // Turn RGB ON or OFF according to state and color values
    Serial.printf("RGB is turned on? %s\n", rgbState.boolValue ? "Yes" : "No");
    if (rgbState.boolValue == 1) {
      Serial.printf("Decimal code is RGB(%d, %d, %d)\n", rgbR.intValue, rgbG.intValue, rgbB.intValue);
      analogWrite(RED_PIN, (rgbR.intValue * brightness) / 255);
      analogWrite(GREEN_PIN, (rgbG.intValue * brightness) / 255);
      analogWrite(BLUE_PIN, (rgbB.intValue * brightness) / 255);
    } else {
      analogWrite(RED_PIN, LOW);
      analogWrite(GREEN_PIN, LOW);
      analogWrite(BLUE_PIN, LOW);
    }
  } else {
    Serial.println(fbdo.errorReason().c_str());
  }

  Serial.println("----- Looping -----\n");
  delay(1000);
  
}

int calculateLightingAdjustment() {
  indoorLightLevel = analogRead(IN_PHOTO_PIN);
  int result = map(indoorLightLevel, 0, 1023, 255, 0);
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
