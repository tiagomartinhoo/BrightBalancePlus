#include <ESP32Servo.h>

// RGB
const int RED_PIN = 3;
const int GREEN_PIN = 4;
const int BLUE_PIN = 5;
int redValue, greenValue, blueValue;

// Light
const int PHOTO_PIN = 6;
int brightness, lightLevel;

// Temperature
const int OUT_THERM_PIN = 2;
const int IN_THERM_PIN = 7;
const float BETA = 3950;
float outTemp, inTemp;

// Servo
Servo motor;
const int SERVO_PIN = 15;
int currentAngle = 0;

void setup() {
  pinMode(RED_PIN, OUTPUT);
  pinMode(GREEN_PIN, OUTPUT);
  pinMode(BLUE_PIN, OUTPUT);
  motor.attach(SERVO_PIN);
  Serial.begin(115200);
  setColor(75, 0, 150); // Example, to be modified based on user preference
}

void loop() {

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
  lightLevel = analogRead(PHOTO_PIN);
  int result = map(lightLevel, 0, 4095, 255, 0);
  return constrain(result, 0, 255);
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
  }
  motor.write(currentAngle);
}
