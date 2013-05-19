/*
To run this, set your "sketchbook location" to the base directory of the repository.
*/

import processing.opengl.*;
import gifAnimation.*;
import ddf.minim.analysis.*;
import ddf.minim.*;
import java.awt.Color;

Minim minim;
//AudioInput in; // Uncomment this for microphone input
AudioPlayer in;  // If we want to test using an mp3 instead of sound input...
FFT fft;
BeatDetect beat;
Animation[] animations;

int currentAnimation = 0;
float[] fftValues = new float[1024];
Rotation rotation = new Rotation(0.3, 0.04);
boolean fullscreen = true;
int fftMultiplier = 20;

float trSize = 0;
int borderMargin = 10;

int numToSum = 1;
int specDivider = 2;

color black = color(0, 0, 0);

public void setup() {
  frame.setBackground(new Color(0,0,0));
  size(displayWidth, displayHeight, P3D);
  frameRate(24);
  
  minim = new Minim(this);
  minim.debugOn();
  
  // Use this if you want to use microphone/line input.
  //in = minim.getLineIn(Minim.MONO, 512);
  
  // If we want to use an mp3 wee need these lines instead of the one above
  // The mp3 is from: http://www.remix64.com/track/peter-w/spy-vs-spy-instrumental-version/
  in = minim.loadFile("spy_vs_spy.mp3");
  in.loop();
  
  // Initialize beat detection
  beat = new BeatDetect();
  
  // Create FFT object for frequency spectrum
  fft = new FFT(in.bufferSize(), in.sampleRate());
  fft.logAverages(22, 3);
  fft.window(FFT.HAMMING);
  
  for (int i = 0; i < 1024; i++) {
    fftValues[i] = 0;
  }
  
  readGifs();
  noStroke();
}

boolean sketchFullScreen() {
  return fullscreen;
}

// Retrieve next animation sequentially
void nextAnimation() {
  if (currentAnimation == animations.length - 1) {
    currentAnimation = 0;
  } else {
    currentAnimation++;
  }
}

// Get random animation (excludes the current one if we have a few of them)
void randomAnimation() {
  if (animations.length == 1) {
    currentAnimation = 0;
    return;
  }
  
  int num = -1;
  
  while(true) {
    num = int(random(animations.length / 1));
    if (num != currentAnimation) {
      currentAnimation = num;
      break;
    }
  }  
}

void draw() {
  background(black);
  
  if (animations[currentAnimation].getRepeatCount() > 1) {
    animations[currentAnimation].pause();
    //nextAnimation();
    randomAnimation();
    numToSum = int(fft.specSize() / specDivider / animations[currentAnimation].getHeight());
    PImage tmpFrame = animations[currentAnimation].getPImages()[0];
    trSize = getTrSize(tmpFrame.width, tmpFrame.height);
    animations[currentAnimation].play();
  }

  PImage frame = animations[currentAnimation].getPImages()[animations[currentAnimation].getCurrentFrame()];
  updateFft();
  checkBeat();
  rotation.update();
  
  float size = trSize * 0.75;;
  
  pushMatrix();  
  translate(0, 0, -40);
  translate(width / 2, height / 2);
  rotateX(rotation.getX());
  rotateY(rotation.getY());
  
  translate((frame.width * trSize) / -2, (frame.height * trSize) / -2);
  for (int y = 0; y < frame.height; y++) {
    float boxHeight = getAverage(y, numToSum) * fftMultiplier;
    for (int x = 0; x < frame.width; x++) {
      color px = frame.pixels[x + y * frame.width];
      
      if (compareColor(px, black)) {
        continue;
      }
      
      float xTr = x * trSize;
      float yTr = y * trSize;
      pushMatrix();
      translate(xTr, yTr);
      fill(px);
      box(size, size, boxHeight);
      popMatrix();
    }
  }
  popMatrix();
}

// Calculate the maximum "pixel" size for the current animation
float getTrSize(int fWidth, int fHeight) {
  float size = (width / fWidth + fHeight / height);
  float increment = 1;
  float minIncrement = 0.001;
  boolean done = false;
  
  float maxHeight = height - borderMargin;
  float maxWidth = width - borderMargin; 

  while(!done) {
    float w = size * fWidth;
    float h = size * fHeight;
    
    if (w < maxWidth && h < maxHeight) {
      if (increment > minIncrement) {
        increment /= 10;
      } else {
        done = true;
        break;
      }
    }
    size -= increment;
  }
  
  return size;
}

void keyReleased()
{
  if (key == 'p') {
    animations[currentAnimation].togglePause();
  }
  
  if (key == '+') {
    fftMultiplier++;
  }
  
  if (key == '-') {
    fftMultiplier--;
  }
  
  println("fftMultiplier: " + fftMultiplier);
}

// Read all gif animations
void readGifs() {
  String path = sketchPath + "/gifs";
  String[] filenames = null;
  File file = new File(path);
  if (file.isDirectory()) {
    filenames = file.list();
  } else {
    println("Bad data supplied, probably crashing now...");
  }
  
  animations = new Animation[filenames.length];
  println("\nListing info about all files in a directory: ");
  File[] files = listFiles(path);
  for (int i = 0; i < files.length; i++) {
    File f = files[i];    
    println("Name: " + f.getName());
    println("Is directory: " + f.isDirectory());
    println("Size: " + f.length());
    println("-----------------------");
    animations[i] = new Animation(this, path + "/" + f.getName());  
  }
  animations[0].play();
}

File[] listFiles(String dir) {
  File file = new File(dir);
  if (file.isDirectory()) {
    File[] files = file.listFiles();
    return files;
  } else {
    // If it's not a directory
    return null;
  }
}

void updateFft() {
  fft.forward( in.mix );
  for (int i = 0; i < 1024; i++) {
    fftValues[i] = fft.getBand(i);
  }
}

void checkBeat() {
  beat.detect(in.mix);
  if (beat.isOnset()) {
    rotation.triggerBeat();
  }
}

// Get average from a number of fft values. Depends on how many y-pixels the
// animation consists of.
float getAverage(int column, int num) {
  float sum = 0;
  
  for (int i = 0; i < num; i++) {
    sum += fftValues[column * num + i];
  }
  return sum / (1.0 * num);
}

boolean compareColor(color c1, color c2) {
  float r1 = red(c1);
  float g1 = green(c1);
  float b1 = blue(c1);
  float r2 = red(c2);
  float g2 = green(c2);
  float b2 = blue(c2);
  
  return r1 == r2 && g1 == g2 && b1 == b2;
}

// always close Minim audio classes when you finish with them
void stop() {
  in.close();
  minim.stop();
  super.stop();
}
