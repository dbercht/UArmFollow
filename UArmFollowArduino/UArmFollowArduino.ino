/**
 * Module that receives a message containing a point in a 2-dimensional plane in the format:
 * <x>x<y>y
 * from serial in and translated it to the x, h position of the uArm.
 * 
 * Expanded from the `moveTo` example provided by the uArm project, see more at:
 *   http://developer.ufactory.cc/
 * 
 * by Dan Bercht
 */

#include <linreg.h>
#include <uarm_calibration.h>
#include <uarm_library.h>

#include <EEPROM.h>
#include <Wire.h>
#include <uArm_library.h>
#include <Servo.h>

void setup() {
      Wire.begin();        // join i2c bus (address optional for master)
      Serial.begin(9600);  // start serial port at 9600 bps

      // Initialize uArm to start position
      uarm.moveTo(0,-20,10);
}

int theta4Offset = 90;              // the angle between the 4th servo and 1st servo
double y1 = -22;                    // the distance along the y axis


// Frame the movement to these positions (in cm, as per the moveTo function)
double minX = -15;
double maxX = 15;
double minH = 10;
double maxH = 30;

void loop() {
    while(!Serial.available()) {
    }
    String readX = Serial.readStringUntil('x');      // read serial input
    while(!Serial.available()) {
    }
    String readH = Serial.readStringUntil('y');      // read serial input from y, uArm's translation is the `h` direction
    Serial.println("Received: " + readX + " " + readH);

    int valX = readX.toInt();
    int x = calculateX(valX);
    int valH = readH.toInt();
    int h = calculateH(valH);

    // Move the calculated x,y position
    moveToPosition(x, y1, h);
    
    Serial.println("Moved to: x" + String(x) + " y" + String(y1) + " h" + String(h));
}

int calculateX(int percentage) {
  return ((maxX - minX) * (percentage)/ 100) + minX;
}

int calculateH(int percentage) {
  return ((maxH - minH) * (percentage)/ 100) + minH;
}

// move uarm to the point
void moveToPosition(int posX, int posY, int posH) {
  uarm.calAngles(posX, posY, posH);      // calculate the angle need to be executed by implement inverse kinematics  
  uarm.writeAngle(uarm.getTheta1(), uarm.getTheta2(), uarm.getTheta3(), uarm.getTheta1() + theta4Offset);    // execute calculated angles by getting each angle
}

