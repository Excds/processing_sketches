class Rotation {
  float maxRotation;
  float minRotation;
  
  float currentX = 0;
  float currentY = 0;
  
  int xDirection = 1;
  int yDirection = 1;
  
  float xInc = 0;
  float yInc = 0;
  float increment;
  
  // Initialize with max value of how "far" we can turn and twist this and increment in movements...
  Rotation(float maxRotation, float increment) {
    this.maxRotation = maxRotation;
    this.minRotation = maxRotation * -1;
    
    this.increment = increment;
    this.xInc = increment;
    this.yInc = increment;
  }
  
  // Calculate movement updates
  void update() {
    currentX += xInc;
    currentY += yInc;
    
    if (currentX > maxRotation || currentX < minRotation) {
      xDirection *= -1;
      xInc *= xDirection;
      
      yDirection *= randomize();
    }
    
    if (currentY > maxRotation || currentY < minRotation) {
      yDirection *= -1;
      yInc *= yDirection;
      
      xDirection *= randomize();
    }
  }
  
  float getX() {
    return currentX;
  }
  
  float getY() {
    return currentY;
  }
  
  // For each triggered beat, instantly shift the animation to a corner.
  void triggerBeat() {
    int corner = int(random(8) / 1);
    
    switch(corner) {
      case 0:
        currentX = maxRotation;
        currentY = maxRotation;
        xInc = increment * -1;
        xDirection = 1;
      break;
      case 1:
        currentX = minRotation;
        currentY = minRotation;
        xInc = increment;
        xDirection = -1;
      break;
      case 2:
        currentY = maxRotation;
        currentX = maxRotation;
        yInc = increment * -1;
        yDirection = 1;
      break;
      case 3:
        currentY = minRotation;
        currentX = minRotation;
        yInc = increment;
        yDirection = -1;
      break;
      case 4:
        currentX = maxRotation;
        currentY = minRotation;
        xInc = increment * -1;
        xDirection = 1;
      break;
      case 5:
        currentX = minRotation;
        currentY = maxRotation;
        xInc = increment;
        xDirection = -1;
      break;
      case 6:
        currentY = maxRotation;
        currentX = minRotation;
        yInc = increment * -1;
        yDirection = 1;
      break;
      case 7:
        currentY = minRotation;
        currentX = maxRotation;
        yInc = increment;
        yDirection = -1;
      break;
    }
  }
  
  private int randomize() {
    float num = random(10);
    return num < 5 ? -1 : 1;
  }
}
