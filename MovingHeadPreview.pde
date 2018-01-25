
private final float timeScale = 5.0f;


boolean  modelsLoaded = false;
PShape   movingWashBase;
PShape   movingWashArm;
PShape   movingWashLight;


void loadModels()
{
  if (modelsLoaded) return;
  
  movingWashBase  = loadShape(sketchPath("model/movingHeadBase.obj"));
  movingWashArm   = loadShape(sketchPath("model/movingHeadArm.obj"));
  movingWashLight = loadShape(sketchPath("model/movingHeadLight.obj"));
  
  modelsLoaded = true;
}

class AngleFollowerPID implements PIDProvider
{
  public  float minAngle, maxAngle;
  public  float maxAccel;
  
  public  float targetAngle;
    
  public  float getInput()              { return angle; }
  public  float getSetpoint()           { return targetAngle; }
  public  float getOutput()             { return angAccel; }    
  public  void  setOutput(float output) { angAccel = output; }
  
  public  PID   pid = new PID();

  
  private float angle;
  private float angVel;
  private float angAccel;

  
  public AngleFollowerPID()
  {
    pid.SampleTime = 100;
    pid.provider = this;
    pid.setMode(AUTOMATIC);
  }
  
  public void update(float dt)
  {
    pid.setOutputLimits(-maxAccel,maxAccel);
    pid.compute();
    
    //angAccel = constrain(angAccel,);
    
    angVel += angAccel * dt;
    angle  += angVel   * dt;
  }
}

class MovingHeadPreview 
{
  public  AngleFollowerPID pan  = new AngleFollowerPID();
  public  AngleFollowerPID tilt = new AngleFollowerPID();
  public  color            lightColor;
  public  PVector          dirToTarget; // This is set by the preview draw
  private float            lastTime;
  
  public MovingHeadPreview()
  {
    loadModels();
    
    dirToTarget = new PVector();

    pan.pid.kp = 0.75; // * (P)roportional Tuning Parameter
    pan.pid.ki = 0.15; // * (I)ntegral Tuning Parameter
    pan.pid.kd = 2.0;  // * (D)erivative Tuning Parameter
    
    tilt.pid.kp = 1.01; // * (P)roportional Tuning Parameter
    tilt.pid.ki = 0.25; // * (I)ntegral Tuning Parameter
    tilt.pid.kd = 3.0;  // * (D)erivative Tuning Parameter
  }
  
  public void update() {
    float currentTime = millis() / 1000.0f;
    float dt = (currentTime - lastTime) * timeScale;
    
    //println(dt);
    pan.update(dt);
    tilt.update(dt);
    
    lastTime = currentTime;
  }
  public void draw() {
    float orgX = modelX(0,0,0);
    float orgY = modelY(0,0,0);
    float orgZ = modelZ(0,0,0);
    
    pushMatrix();
      scale(10,10,10);
      
      rotateZ(PI);
      shape(movingWashBase,0,0);
      pushMatrix();
        rotateY(-pan.getInput());
        pushMatrix();
          rotateX(-tilt.getInput());
          dirToTarget.x = modelX(0,1,0) - orgX;
          dirToTarget.y = modelY(0,1,0) - orgY;
          dirToTarget.z = modelZ(0,1,0) - orgZ;
        popMatrix();
        
        translate(0,5,0);
        shape(movingWashArm,0,0);
        translate(0,8,0);
        pushMatrix();
          rotateX(-tilt.getInput());
          shape(movingWashLight,0,0);
          fill(lightColor);
          emissive(lightColor);
          translate(0,1,0);
          box(8,8,8);
        popMatrix();
      popMatrix();
    popMatrix();
  }
}