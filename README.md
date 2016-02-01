# Simple UArm Follow

Simple module to move a UArm [UArm](http://developer.ufactory.cc/) via Serial.

There's a Processing IDE that interacts with [UArm](http://developer.ufactory.cc/quickstart/processing/),

But the decision was to make two separate modules nonetheless:
1. Arduino Module
..* Module receives serial entry in the format <x>x<y>y and moves the UArm's x/h component accordingly.
2. Processing Module
..* Module uses the video capture library to find the first red pixel of a screen and send the coordinate of the point over to UArm's serial port as a normalized position on the screen [0 - 100].

