 

/**********************************************************************************************
 * Arduino PID Library - Version 1.2.1
 * by Brett Beauregard <br3ttb@gmail.com> brettbeauregard.com
 *
 * This Library is licensed under the MIT License
 *
 * Ported to Processing by Jack Kern <jack.w.kern@gmail.com>
 **********************************************************************************************/

public interface PIDProvider
{
  public float getInput();
  public float getSetpoint();
  public float getOutput();
  public void  setOutput(float output);
}

//Constants used in some of the functions below
public final int AUTOMATIC = 1;
public final int MANUAL = 0;
public final int DIRECT = 0;
public final int REVERSE = 1;
public final int P_ON_M = 0;
public final int P_ON_E = 1;


public class PID {
    
  float dispKp;        // * we'll hold on to the tuning parameters in user-entered 
  float dispKi;        //   format for display purposes
  float dispKd;        //
    
  public float kp;                  // * (P)roportional Tuning Parameter
  public float ki;                  // * (I)ntegral Tuning Parameter
  public float kd;                  // * (D)erivative Tuning Parameter

  public int controllerDirection;
  public int pOn;

  
  PIDProvider provider;
  
  float   getInput()              { return provider.getInput(); }
  float   getOutput()             { return provider.getOutput(); }
  void    setOutput(float output) { provider.setOutput(output); }
  float   getSetpoint()           { return provider.getSetpoint(); }
  
      
  float   lastTime;
  float   outputSum, lastInput;

  float   SampleTime;
  float   outMin, outMax;
  boolean inAuto, pOnE;
  

 


  /* Compute() **********************************************************************
   *     This, as they say, is where the magic happens.  this function should be called
   *   every time "void loop()" executes.  the function will decide for itself whether a new
   *   pid Output needs to be computed.  returns true when the output is computed,
   *   false when nothing has been done.
   **********************************************************************************/
  public boolean compute()
  {
     if (!inAuto) return false;
     
     float now = millis();
     float timeChange = (now - lastTime);
     
     if (timeChange >= SampleTime)
     {
        /*Compute all the working error variables*/
        float input  = getInput();
        float error  = getSetpoint() - input;
        float dInput = (input - lastInput);
        
        outputSum += (ki * error);
  
        /*Add Proportional on Measurement, if P_ON_M is specified*/
        if(!pOnE) outputSum -= kp * dInput;
  
        if      (outputSum > outMax) outputSum = outMax;
        else if (outputSum < outMin) outputSum = outMin;
  
        /*Add Proportional on Error, if P_ON_E is specified*/
        float output;
        if (pOnE) output = kp * error;
        else output = 0;
  
        /*Compute Rest of PID Output*/
        output += outputSum - kd * dInput;
  
        if      (output > outMax) output = outMax;
        else if (output < outMin) output = outMin;
        
        setOutput(output);
  
        /*Remember some variables for next time*/
        lastInput = input;
        lastTime  = now;
        
        return true;
     
     }
     return false;
  }

  /* SetTunings(...)*************************************************************
   * This function allows the controller's dynamic performance to be adjusted.
   * it's called automatically from the constructor, but tunings can also
   * be adjusted on the fly during normal operation
   ******************************************************************************/
  public void setTunings(float Kp, float Ki, float Kd, int POn)
  {
     if (Kp<0 || Ki<0 || Kd<0) return;
  
     pOn = POn;
     pOnE = POn == P_ON_E;
  
     dispKp = Kp; dispKi = Ki; dispKd = Kd;
  
     float SampleTimeInSec = ((float)SampleTime)/1000;
     kp = Kp;
     ki = Ki * SampleTimeInSec;
     kd = Kd / SampleTimeInSec;
  
    if(controllerDirection == REVERSE)
    {
      kp = (0 - kp);
      ki = (0 - ki);
      kd = (0 - kd);
    }
  }

  /* SetTunings(...)*************************************************************
   * Set Tunings using the last-rembered POn setting
   ******************************************************************************/
  public void setTunings(float Kp, float Ki, float Kd) {
      setTunings(Kp, Ki, Kd, pOn); 
  }

  /* SetSampleTime(...) *********************************************************
   * sets the period, in Milliseconds, at which the calculation is performed
   ******************************************************************************/
  public void setSampleTime(int NewSampleTime)
  {
     if (NewSampleTime > 0)
     {
        float ratio  = (float)NewSampleTime
                     / (float)SampleTime;
        ki *= ratio;
        kd /= ratio;
        SampleTime = NewSampleTime;
     }
  }

  /* SetOutputLimits(...)****************************************************
   *     This function will be used far more often than SetInputLimits.  while
   *  the input to the controller will generally be in the 0-1023 range (which is
   *  the default already,)  the output will be a little different.  maybe they'll
   *  be doing a time window and will need 0-8000 or something.  or maybe they'll
   *  want to clamp it from 0-125.  who knows.  at any rate, that can all be done
   *  here.
   **************************************************************************/
  public void setOutputLimits(float Min, float Max)
  {
     if (Min >= Max) return;
     outMin = Min;
     outMax = Max;
  
     float myOutput = getOutput();
     if(inAuto)
     {
       if      (myOutput > outMax) setOutput(outMax);
       else if (myOutput < outMin) setOutput(outMin);
  
       if      (outputSum > outMax) outputSum = outMax;
       else if (outputSum < outMin) outputSum = outMin;
     }
  }

  /* SetMode(...)****************************************************************
   * Allows the controller Mode to be set to manual (0) or Automatic (non-zero)
   * when the transition from manual to auto occurs, the controller is
   * automatically initialized
   ******************************************************************************/
  public void setMode(int Mode)
  {
      boolean newAuto = (Mode == AUTOMATIC);
      if (newAuto && !inAuto)
      {  /*we just went from manual to auto*/
          initialize();
      }
      inAuto = newAuto;
  }

  /* Initialize()****************************************************************
   *  does all the things that need to happen to ensure a bumpless transfer
   *  from manual to automatic mode.
   ******************************************************************************/
  public void initialize()
  {
     outputSum = getOutput(); //@TODO
     lastInput = getInput();
     
     if (outputSum > outMax)
       outputSum = outMax;
     else if(outputSum < outMin)
       outputSum = outMin;
  }

  /* SetControllerDirection(...)*************************************************
   * The PID will either be connected to a DIRECT acting process (+Output leads
   * to +Input) or a REVERSE acting process(+Output leads to -Input.)  we need to
   * know which one, because otherwise we may increase the output when we should
   * be decreasing.  This is called from the constructor.
   ******************************************************************************/
  public void setControllerDirection(int Direction)
  {
     if(inAuto && Direction !=controllerDirection)
     {
        kp = (0 - kp);
        ki = (0 - ki);
        kd = (0 - kd);
     }
     controllerDirection = Direction;
  }

  /* Status Funcions*************************************************************
   * Just because you set the Kp=-1 doesn't mean it actually happened.  these
   * functions query the internal state of the PID.  they're here for display
   * purposes.  this are the functions the PID Front-end uses for example
   ******************************************************************************/
  public float  getKp()       { return  dispKp; }
  public float  getKi()       { return  dispKi; }
  public float  getKd()       { return  dispKd; }
  public int    getMode()     { return  inAuto ? AUTOMATIC : MANUAL; }
  public int    getDirection(){ return controllerDirection; }

}