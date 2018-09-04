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

// the particle container
ParticleContainer particleContainer;

// some colors
HashMap<String,Integer> colors;
int bgColor;

// directional unit vectors for convenience
final PVector upVector = new PVector(0, -1);
final PVector downVector = new PVector(0, 1);
final PVector leftVector = new PVector(-1, 0);
final PVector rightVector = new PVector(1, 0);

void setup() {
  settings = loadJSONObject("settings.json");
  //settings.setBoolean("wrap around", true);
  //size(800, 600);
  //size(1200, 800, P2D);
  fullScreen(P2D);
  frameRate(60);
  
  fx = new PostFX(this);
  
  // set up colors
  colors = new HashMap<String,Integer>();
  colors.put("white", #ffffff);
  colors.put("black", #000000);
  bgColor = colors.get("white");
  background(bgColor);
  
  // particle container
  particleContainer = new ParticleContainer();
  
  // add particles
  idCounter = 0;
  int numParticles = settings.getInt("number of particles");
  for(int i=0; i < numParticles; i++) {
    particleContainer.addParticle(new Particle()); 
  }
}


void draw() {
  background(bgColor);
  particleContainer.updateAndDraw();
  
  
  // add bloom filter
  if(true) {
    fx.render()
      .blur(10, 0.8)
      //.blur(10, 1.5)
      //.sobel()
      //.pixelate(150.0)
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
