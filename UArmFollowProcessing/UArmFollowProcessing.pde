import processing.serial.*;
import processing.video.*;

/**
 * Follow the first true red pixel and send to arduino.
 * by Dan Bercht. 
 *
 * Identify the first red object and send it over serial port to arduino.
 */ 


// Thresholds for finding the red object in the screen
int RED_TRESHOLD = 250;
int OTHER_THRESHOLD = 140;

// Throttle messages going to serial so we don't overload the Arduino.
int counter = 0;
int FRAME_RATE_LIMIT = 45;

// The Arduino object to send serial data to
Arduino arduino;
String PORT_NAME = "/dev/cu.usbserial-A600CQJ9";  // this is the name of the uArm device
int BAUD_RATE = 9600;  // Low baud rate, just bc.

// Related to video capture
int numPixels;
Capture video;
boolean update = true;

class Arduino {
  /**
   * Simple wrapper around the Arduino serial connection.
   */

  String portName;
  int baudRate;
  Serial arduinoPort;
  boolean connected;
  
  public Arduino(PApplet ref, String portName, int baudRate) {
    this.portName = portName;
    this.baudRate = baudRate;
    this.connected = false;

    this._connect(ref);
  }
  
  void _connect(PApplet ref) {
    /**
     * Finds the defined Serial port by name and tries to connect to it.
     */
    println("Searching for: " + this.portName);
 
    int ardPort = -1;
    String [] ports = Serial.list();
    
    println("Found following serial ports:");
    for (int i = 0; i < ports.length; i++) {
      if (ports[i].contains(this.portName)) {
        ardPort = i;
        println("* " + i + ": " + ports[i]);
      } else {
        println(i + ": " + ports[i]);
      }
    }
    if (ardPort == -1) {
      println("Could not find arduino: " + this.portName);  
      return;
    }
    println("Connecting to : " + this.portName);
    println("Baud rate : " + this.baudRate);
    
    this.arduinoPort = new Serial(ref, this.portName, this.baudRate);
  }
  

  void send(Point p) {
    /**
     * Sends point to the Arduino in the format <x>x<y>y
     * so the arduino can properly de-serialize the point.
     */
    int w = p.getPercentageWidth();
    int h = p.getPercentageHeight();
    String pos = str(w) + "x" + str(h) + "y";
    println("Sending to Arduino: " + pos);
    this.arduinoPort.write(pos);
  }

}
class Point {
  int x, y, maxWidth, maxHeight;
  boolean empty;
  
  public Point() {
    this.x = -1;
    this.y = -1;
  }

  public Point(int position, int vWidth, int vHeight) {
    this.y = (int) (position / vWidth);
    this.x = position % vWidth;
    this.maxWidth = vWidth;
    this.maxHeight = vHeight;
  }
  
  int getPercentageWidth() {
    return 100 - (int) ((float)100*this.x / (float)this.maxWidth);
  }
  
  int getPercentageHeight() {
    return 100 - (int) ((float)100*this.y / (float)this.maxHeight);
  }
  
  boolean isEmpty() {
    return this.y == -1 || this.x == -1;
  }
}

void setup() {
  arduino = new Arduino(this, PORT_NAME, BAUD_RATE);  
  if (!arduino.connected) {
    exit();
  }
  size(640, 480); // Processing requires to hardcode w/h in this function
  
  // This the default video input, see the GettingStartedCapture 
  // example if it creates an error
  video = new Capture(this, width, height);
  // Start capturing the images from the camera
  video.start(); 
  
  numPixels = video.width * video.height;
}

void draw() {

  // Listen to the arduino for some debugging.
  if ( arduino.arduinoPort.available() > 0) {
     String val = arduino.arduinoPort.readStringUntil('\n');
     println(val);
  }
  
  if (video.available()) {
    video.read(); // Read the new frame from the camera
    video.loadPixels(); // Make its pixels[] array available
    set(0, 0, video);
    Point firstRed = findFirstRed(video);
    // If we actually found it
    if (!firstRed.isEmpty()) {
      // Paint so we can see it in the Processing canvas
      paint(firstRed);
      // Send the serial value to the arduino
      if (counter>FRAME_RATE_LIMIT) {
        arduino.send(firstRed);  
        counter = 0;
      }
    }
  }
  counter++;
}

Point findFirstRed(Capture video) {
    for (int i = 0; i < numPixels; i++) { // For each pixel in the video frame...
      color currColor = video.pixels[i];
      // Extract the red, green, and blue components from current pixel
      int currR = (currColor >> 16) & 0xFF; // Like red(), but faster
      int currG = (currColor >> 8) & 0xFF;
      int currB = currColor & 0xFF;
      // Check if this is true red pixel.
      if (currR > RED_TRESHOLD && currG < OTHER_THRESHOLD && currB < OTHER_THRESHOLD) {
        return new Point(i, video.width, video.height);
      }
    }
    return new Point();
}


Point paint(Point p) {
  /**
   * Paints a box in relation to p (left and down, not around)
   */

  int sHeight = p.y;
  int sWidth = p.x;

  for (int i = 0; i < 10 && i + sHeight < video.height; i++) {
    for (int j = 0; j < 10 && j + sWidth < video.width; j++) {
      set(sWidth + j, sHeight + i, color(0));
    }
  }
  return p;
}