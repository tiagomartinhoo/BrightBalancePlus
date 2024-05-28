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
int redValue, greenValue, blueValue;

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
//bool blowing = false;

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

  // Setup color as an example... to be modified based on user preference
  setColor(50, 0, 150);

  // Connect to WiFi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to WiFi");
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

    int fanState;
    if (Firebase.RTDB.getInt(&fbdo, "/fan/state", &fanState)) {
      digitalWrite(FAN_PIN, fanState);
    } else {
      Serial.println(fbdo.errorReason().c_str());
    }
  }
  
  //digitalWrite(FAN_PIN, blowing ? HIGH : LOW);

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

  if (Serial.available()) {
    String command = Serial.readStringUntil('\n');
    adjustBlinds(command);
  }

  analogWrite(RED_PIN, (redValue * brightness) / 255);
  analogWrite(GREEN_PIN, (greenValue * brightness) / 255);
  analogWrite(BLUE_PIN, (blueValue * brightness) / 255);
  
  Serial.println("-----------------------------");
  delay(1000);
  
}

void setColor(int red, int green, int blue) {
  redValue = red;
  greenValue = green;
  blueValue = blue;
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

void adjustBlinds(String command) {
  command.trim();
  command.toLowerCase();
  if (command == "raise") {
    currentAngle = 180;
  } else if (command == "mid") {
    currentAngle = 90;
  } else if (command == "lower") {
    currentAngle = 0;
  } /*else if (command == "fan") {
    blowing = !blowing;
  }*/
  motor.write(currentAngle);
}
