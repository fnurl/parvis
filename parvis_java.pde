import java.util.Map;

// postfx
import ch.bildspur.postfx.builder.*;
import ch.bildspur.postfx.pass.*;
import ch.bildspur.postfx.*;

PostFX fx;

// debug level. 0 is none, 5 is alot.
final int DEBUG = 0;

JSONObject settings;
int idCounter;

// keyboard controlls
HashMap<Character,String> keybindings;

// the particle container
ParticleContainer particleContainer;

// some colors
HashMap<String,Integer> colors;
String bgColor;

// directional unit vectors for convenience
final PVector upVector = new PVector(0, -1);
final PVector downVector = new PVector(0, 1);
final PVector leftVector = new PVector(-1, 0);
final PVector rightVector = new PVector(1, 0);

void setup() {
  settings = loadJSONObject("settings.json");
  //size(800, 600);
  //fullScreen(P2D);
  size(1280, 800, P2D);
  
  frameRate(60);
  
  fx = new PostFX(this);
  
  // set up colors
  colors = new HashMap<String,Integer>();
  colors.put("white", #ffffff);
  colors.put("black", #000000);
  
  // load color settings
  bgColor = settings.getString("background");
  background(colors.get(bgColor));
  
  // keybindings
  keybindings = new HashMap<Character,String>();
  keybindings.put('p', "draw preferred distance");
  keybindings.put('i', "draw interactions");
  keybindings.put('w', "wrap around");
  keybindings.put('a', "apply attraction");
  keybindings.put('r', "apply repell");
  keybindings.put('v', "draw velocity line");
  keybindings.put('m', "draw wall markers");
  keybindings.put('l', "limit velocity");
  
  // particle container
  particleContainer = new ParticleContainer();
  
  // add particles
  idCounter = 0;
  int numParticles = settings.getInt("number of particles");
  for(int i=0; i < numParticles; i++) {
    particleContainer.addParticle(new Particle()); 
  }
}

void keyPressed() {
  println("key pressed: " + key);
  
  boolean boolSetting;
  String settingName;

  if (keybindings.containsKey(key)) {
    settingName = keybindings.get(key);
    boolSetting = settings.getBoolean(settingName);
    settings.setBoolean(settingName, !boolSetting);
  }
  
  if (key == 'b') {
    if (bgColor == "white") {
      bgColor = "black";
    } else {
      bgColor = "white";
    }
  }
}


void draw() {
  //if (frameCount % 10 == 0)
  background(colors.get(bgColor));
  particleContainer.updateAndDraw();
    
  // add shader
  if(true) {
    fx.render()
      //.blur(10, 0.8)
      .blur(10, 1.3)
      //.sobel()
      //.pixelate(500.0)
      //.brightPass(0.1)
      //.bloom(0.8, 100, 20)
      //.toon()
      //.noise(0.3, 0.2)
      //.blur(10, 2.0)
      .rgbSplit(20.0)
      .vignette(0.45, 0.4)
      .compose();
  } 
}
