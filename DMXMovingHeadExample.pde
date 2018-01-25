import dmxP512.*;
import processing.serial.*;

//import controlP5.*;
//ControlP5 cp5;

DmxP512   dmxOutput;

int      universeSize = 60;
boolean  LANBOX       = false;
String   LANBOX_IP    = "192.168.1.77";
boolean  DMXPRO=true;
//String DMXPRO_PORT="/dev/tty.usbserial-EN167768";
String   DMXPRO_PORT ="/dev/cu.usbserial-EN167768";//case matters ! on windows port must be upper cased.
int      DMXPRO_BAUDRATE = 115000;

MovingHead[] heads = new MovingHead[4];


PVector targetPosition = new PVector();
float   ang, ang2;


void setup() {
  
  size(1280, 800, P3D);  
  
  //parent    = this;
  dmxOutput = new DmxP512(this,universeSize,false);
  //cp5       = new ControlP5(this);
  
  try {
    if(LANBOX){
      dmxOutput.setupLanbox(LANBOX_IP);
    }
    if(DMXPRO){
      dmxOutput.setupDmxPro(DMXPRO_PORT,DMXPRO_BAUDRATE);
    }
  } catch(Exception e) {}
  
  
  // Create our MovingHeads
  for(int i=0; i<heads.length; ++i) {
    heads[i] = new MovingHead();    
  }
  
  // Set the start addresses for each
  heads[0].startAddress = 1;
  heads[1].startAddress = 15;
  heads[2].startAddress = 30;
  heads[3].startAddress = 45;
  
  
  //cp5.addColorWheel("c" , 250 , 10 , 200 ).setRGB(color(128,0,255));
  
  frameRate = 60;
}



void draw() {
  
  final float s1 = 0.1f; // scale of the color wave
  final float s2 = 0.8f; // scale of the brightness wave
  
  ang  += 0.01;
  ang2 += 0.03;
  
  // Set up the background and directional lighting
  background(0);
  ambientLight(20,20,20);
  colorMode(HSB,255);
  directionalLight(255,0,100,0.5,0,-0.5);
  
  // Update the target position using the mouse position
  targetPosition.x = (mouseX - width/2)*4 + width/2;
  targetPosition.y = (mouseY - height/2)*4 + height/2;
  targetPosition.z = sin(ang)*500-400; // Move the z back and forth
  
  
  drawTargetPosition();

  
  for(int i=0; i<heads.length; ++i) {
    int hue = (int)map(sin(ang + i*s1),-1,1,0,255);
    int val = (int)map(sin(ang2 + i*s2),-1,1,0,255);

    // Dynamically change the light color
    heads[i].lightColor = color(hue, 255, val);

    // Set the light position according to it's index, we don't really 
    //  need to do this every frame but this is easy.
    heads[i].lightPosition.x = 200 + i*300;
    heads[i].lightPosition.y = 420; 
    heads[i].lightPosition.z = 0;
    heads[i].updateLight();
    
    drawLightTargetingVector(heads[i].lightPosition);
    
    // Here is where we calculate the pan/tilt angles for each moving head light
    //  based on it's position and the target position
    PVector dirToTarget    = PVector.sub(targetPosition, heads[i].lightPosition);
    PVector dirToTargetPan = new PVector(-dirToTarget.z, dirToTarget.x);
    float   tilt = PVector.angleBetween(dirToTarget, new PVector(0,1,0)) - PI*0.5f;
    float   pan  = PI - dirToTargetPan.heading();
    
    // The MovingHead data structure expects the pan and tilt values to be normalized
    //  (Between 0 and 1)
    heads[i].panAngle  = map(pan,  0, 3*PI, 0,1);
    heads[i].tiltAngle = map(tilt, 0,   PI, 0,1);
    
    // Update the moving head and send the data out over DMX
    heads[i].update();
    
    // Draw the MovingHead preview
    noStroke();
    pushMatrix();
      heads[i].draw();
    popMatrix();
  }
  
  drawBackground();
}

void drawLightTargetingVector(PVector pos)
{
    stroke(255);
    line(
      targetPosition.x,targetPosition.y,targetPosition.z, 
      pos.x,pos.y,pos.z
    );
}

void drawTargetPosition()
{
  pushMatrix();
    translate(targetPosition.x,targetPosition.y,targetPosition.z);
    fill(255);
    box(5,5,5);
  popMatrix();
}
void drawBackground()
{
  // We draw a grid of boxes because the lighting in procesing works on a per-vertex level
  //  so if we throw a lot of even geometric detail in the background we can see the lights better.
  
  emissive(0,0,0);
  fill(255);
  
  int c = 50;
  int r = 20;
  for(int x=0; x<c; ++x)
    for(int y=0; y<r; ++y) {
      pushMatrix();
        translate(map(x,0,c-1,0,width),map(y,0,r-2,0,height),-300);
        rotateY(PI/4);
        rotateX(PI/4);
        box(20);
      popMatrix();
    }
}