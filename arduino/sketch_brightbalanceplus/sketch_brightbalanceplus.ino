#include <ESP32Servo.h>

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
bool blowing = false;

// Servo
Servo motor;
const int SERVO_PIN = 15;
int currentAngle = 0;

void setup() {
  pinMode(RED_PIN, OUTPUT);
  pinMode(GREEN_PIN, OUTPUT);
  pinMode(BLUE_PIN, OUTPUT);
  pinMode(OUT_PHOTO_PIN, INPUT);
  pinMode(IN_PHOTO_PIN, INPUT);
  pinMode(OUT_THERM_PIN, INPUT);
  pinMode(IN_THERM_PIN, INPUT);
  pinMode(FAN_PIN, OUTPUT);
  motor.attach(SERVO_PIN);
  Serial.begin(115200);
  setColor(50, 0, 150); // Example, to be modified based on user preference
}

void loop() {

  digitalWrite(FAN_PIN, blowing ? HIGH : LOW);

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
  } else if (command == "fan") {
    blowing = !blowing;
  }
  motor.write(currentAngle);
}
