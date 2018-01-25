

public class MovingHead
{
  //enum ChanelMode { CHANNEL_MODE_15, CHANNEL_MODE_9 };
  //enum SpeedMode { FAST_MODE, SLOW_MODE };
  
  public int      startAddress;
  public float    panAngle;     // 0-1
  public float    tiltAngle;    // 0-1
  public float    panTiltSpeed; // 0-1
  public color    lightColor;          
  
  //public float    dimmerValue;  // 0-1
  //public boolean  strobe;
  
  public boolean  reset          = false;
  public PVector  lightPosition = new PVector();
  
 
  
  MovingHeadPreview preview;
  
  public MovingHead()                 { this(0); }
  public MovingHead(int startAddress) {
    this.startAddress = startAddress;
    preview = new MovingHeadPreview();
    
    // This is currently specifically set up for the LIXDA pan/tilt wash
    preview.pan.minAngle  = 0;
    preview.pan.maxAngle  = 3*PI;
    preview.pan.maxAccel  = 100.0f;
    
    preview.tilt.minAngle = -PI/2;
    preview.tilt.maxAngle = PI/2;
    preview.tilt.maxAccel = 100.0f;
  }
  
  void draw()
  {
    preview.pan.targetAngle  = map(panAngle,  0,1,   preview.pan.minAngle, preview.pan.maxAngle);
    preview.tilt.targetAngle = map(tiltAngle, 0,1, preview.tilt.minAngle, preview.tilt.maxAngle);

    preview.lightColor = lightColor;
    preview.update();
    pushMatrix();
      translate(lightPosition.x,lightPosition.y + 130,lightPosition.z);
      preview.draw();
    popMatrix();
  }
  
  void update()
  {
    // This is a very basic output of our parameters to
    //  an LIXDA pan/tilt wash in 14 channel mode.
    
    int pan = (int)(constrain(panAngle, 0,1) * 0xFFFF);
    int panHigh = (pan >> 8) & 0xFF;
    int panLow =  pan & 0xFF;
    
    int tilt = (int)(constrain(tiltAngle, 0,1) * 0xFFFF);
    int tiltHigh = (tilt >> 8) & 0xFF;
    int tiltLow =  tilt & 0xFF;

    dmxOutput.set(startAddress+0, panHigh);
    dmxOutput.set(startAddress+1, panLow);
    dmxOutput.set(startAddress+2, tiltHigh);
    dmxOutput.set(startAddress+3, tiltLow);
    
    int panTiltSpeed = 0; // 0 is the fastest, 255 the slowest
    dmxOutput.set(startAddress+4, panTiltSpeed);
    
    
    //@TODO
    // off 0-7
    // dim 8-134
    // strobe 135-239;
    int dimStrobe = 240; 
    dmxOutput.set(startAddress+5, dimStrobe);
    
    
    int red   = (int)red(lightColor);
    int green = (int)green(lightColor);
    int blue  = (int)blue(lightColor);
    int white = (int)((255.0f-saturation(lightColor)) * (brightness(lightColor) / 255.0));
    
    
    dmxOutput.set(startAddress+6, red);
    dmxOutput.set(startAddress+7, green);
    dmxOutput.set(startAddress+8, blue);
    dmxOutput.set(startAddress+9, white);
   
    dmxOutput.set(startAddress+10, 0); // Auto color modes
    dmxOutput.set(startAddress+11, 0); // Auto color mode speed
    dmxOutput.set(startAddress+12, 0); // Auto play modes, 0 for DMX
   
    if (reset) {
      dmxOutput.set(startAddress+13, 255);
      reset = false;
    } else {
      dmxOutput.set(startAddress+13, 0);
    }
  }
  
  void updateLight()
  {
    PVector dirToTarget = preview.dirToTarget.normalize();
    float   h = hue(lightColor);
    float   s = saturation(lightColor);
    float   b = brightness(lightColor);
    spotLight(h,s,b, lightPosition.x,lightPosition.y,lightPosition.z, dirToTarget.x,dirToTarget.y,dirToTarget.z, PI/4.0f, 5.0);
  }
 
}