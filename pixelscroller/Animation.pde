import java.awt.image.BufferedImage;
import java.io.*;

class Animation extends Thread {

  boolean running;           // Is the thread running?  Yes or no?
  int wait = 5;              // How many milliseconds should we wait in between executions?
  String id;                 // Thread name
  int repeatCount;           // counter
  String filename;

  // the current frame number
  private int currentFrame;
  // array containing the frames as PImages
  private PImage[] frames;
  // array containing the delay in ms of every frame
  private int[] delays;
  // last time the frame changed
  private int lastJumpTime;

  boolean paused = true;

  private int width;
  private int height;
  
  // Parent PApplet
  PApplet parent;

  // Constructor, create the thread
  // It is not running by default
  Animation (PApplet parent, String filename) {
    this.parent = parent;
    this.filename = filename;
    
    // create the GifDecoder
    GifDecoder gifDecoder = createDecoder(parent, filename);
    // fill up the PImage and the delay arrays
    frames = extractFrames(gifDecoder);
    delays = extractDelays(gifDecoder);
    
    // Set animation dimensions
    width = frames[0].width;
    height = frames[0].height;
    
    this.start();
    repeatCount = 0;
  }
  
  public int getHeight() {
    return height;
  }
  
  public int getWidth() {
    return width;
  }
  
  /*
   * creates a GifDecoder object and loads a gif file
   */
  private GifDecoder createDecoder(PApplet parent, String filename) {
    GifDecoder gifDecoder = new GifDecoder();
    gifDecoder.read(createInputStream(parent, filename));
    return gifDecoder;
  }

  /*
   * creates a PImage-array of gif frames in a GifDecoder object
   */
  private PImage[] extractFrames(GifDecoder gifDecoder) {
    int n = gifDecoder.getFrameCount();

    PImage[] theFrames = new PImage[n];

    for (int i = 0; i < n; i++) {
      BufferedImage frame = gifDecoder.getFrame(i);
      theFrames[i] = new PImage(frame.getWidth(), frame.getHeight(), ARGB);
      System.arraycopy(frame.getRGB(0, 0, frame.getWidth(), frame
        .getHeight(), null, 0, frame.getWidth()), 0,
      theFrames[i].pixels, 0, frame.getWidth() * frame.getHeight());
    }
    return theFrames;
  }

  /*
   * creates an int-array of frame delays in the gifDecoder object
   */
  private int[] extractDelays(GifDecoder gifDecoder) {
    int n = gifDecoder.getFrameCount();
    int[] delays = new int[n];
    for (int i = 0; i < n; i++) {
      delays[i] = gifDecoder.getDelay(i); // display duration of frame in
      // milliseconds
      }
      return delays;
   }

   /*
    * creates an input stream using processings openStream() method to read
    * from the sketch data-directory
    */
  private InputStream createInputStream(PApplet parent, String filename) {
    InputStream inputStream = parent.openStream(filename);
    return inputStream;
  }

  /*
   * probably someone wants all the frames even if he has a playback-gif...
   */
  public PImage[] getPImages() {
    return frames;
  }
  
  public int getCurrentFrame() {
    return currentFrame;
  }
  
  public int getRepeatCount() {
    return repeatCount;
  }
  
  // Overriding "start()"
  void start () {
    // Reset to first frame
    currentFrame = 0;
    // Set running equal to true
    running = true;
    // Print messages
    println("Starting thread (will execute every " + wait + " milliseconds.)"); 
    // Do whatever start does in Thread, don't forget this!
    super.start();
  }


  // We must implement run, this gets triggered by start()
  void run() {
    repeatCount = 0;
    while (running) {
      if (paused) {
        try {
          sleep((long)(100000));
        } catch (Exception e) {
        }
        continue;
      }
      // Ok, let's wait for however long we should wait
      try {
        sleep((long)(wait));
      } catch (Exception e) {
      }
      if (parent.millis() - lastJumpTime >= delays[currentFrame]) {
        // we need to jump
        if (currentFrame == frames.length - 1) {
	  // its the last frame
          jump(0); // rewind
          repeatCount++;
	} else {
	  // go to the next frame
	  jump(currentFrame + 1);
	}
      }
    }
  }

  /**
   * Jump to a specific location (in frames). if the frame does not exist, go
   * to last frame
   */
  public void jump(int where) {
    if (frames.length > where) {
      currentFrame = where;
      // set the jump time
      lastJumpTime = parent.millis();
    }
  }

  public void pause() {
    paused = true;
  }
  
  public void unpause() {
    paused = false;
    interrupt();
  }
  
  public void togglePause() {
    if (paused) {
      unpause();
    } else {
      pause();
    }
  }
  
  public void play() {
    paused = false;
    currentFrame = 0;
    repeatCount = 0;
    interrupt();
  }

  // Our method that quits the thread
  void quit() {
    System.out.println("Quitting."); 
    running = false;  // Setting running to false ends the loop in run()
    // IUn case the thread is waiting. . .
    interrupt();
  }
  
  public String getFilename() {
    return filename;
  }
}

