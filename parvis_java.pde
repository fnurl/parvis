import java.util.Map;

// postfx
import ch.bildspur.postfx.builder.*;
import ch.bildspur.postfx.pass.*;
import ch.bildspur.postfx.*;

PostFX fx;

// debug level. 0 is none, 5 is alot.
final static int ERRORS = 1;
final static int INFO = 2;
final static int DEBUG = 3;
final static int DEBUG_VERBOSE = 4;
final static int LOGLEVEL = DEBUG;

JSONObject settings;
int idCounter;

// keyboard controlls
HashMap<Character,String> keybindings;

// some colors
HashMap<String,Integer> colors;
String bgColor;
final int inactiveAlpha = 64;
final int activeAlpha = 186;

// UI
GUIContainer guiContainer;
Slider testSlider;
SettingSlider frictionSlider;

// the particle container
ParticleContainer particleContainer;

// directional unit vectors for convenience
final PVector upVector = new PVector(0, -1);
final PVector downVector = new PVector(0, 1);
final PVector leftVector = new PVector(-1, 0);
final PVector rightVector = new PVector(1, 0);

// log message to console if message level is equal to or lower than current log
// level
static void logMsg(int msgLevel, String msg) {
  if (msgLevel <= LOGLEVEL)
    println(msg);
}

// return a new color value with newAlpha as alpha (0-255)
static int modifyAlpha(int colorValue, int newAlpha) {
  // from https://processing.org/discourse/beta/num_1261125421.html
  return (colorValue & 0xffffff) | (newAlpha << 24); 
}

void setup() {
  settings = loadJSONObject("settings.json");
  //size(800, 600);
  //fullScreen(P2D);
  size(1280, 800, P2D);
  
  frameRate(60);
  
  fx = new PostFX(this);
 
  /* Pencil colors from vim-colors-pencil
  black         = #212121
  medium_gray   = #767676
  white         = #F1F1F1
  actual_white  = #FFFFFF
  light_black   = #424242
  lighter_black = #545454

  Default: darker shadow and whiter grays
  subtle_black  = #262626
  light_gray    = #D9D9D9
  lighter_gray  = #E5E6E6

  High Contrast: lighter shadows and darker grays
  subtle_black  = #303030
  light_gray    = #B2B2B2
  lighter_gray  = #C6C6C6

  pink          = #fb007a
  dark_red      = #C30771
  light_red     = #E32791
  orange        = #D75F5F
  darker_blue   = #005F87
  dark_blue     = #008EC4
  blue          = #20BBFC
  light_blue    = #b6d6fd
  dark_cyan     = #20A5BA
  light_cyan    = #4FB8CC
  dark_green    = #10A778
  light_green   = #5FD7A7
  dark_purple   = #523C79
  light_purple  = #6855DE
  yellow        = #F3E430
  dark_yellow   = #A89C14
  */ 

  // set up colors
  colors = new HashMap<String,Integer>();
  // pencil palette
  colors.put("black",         #212121);
  colors.put("medium gray",   #767676);
  colors.put("white",         #f1f1f1);
  colors.put("actual white",  #ffffff);
  colors.put("light black",   #424242);
  colors.put("lighter black", #545454);

  if (!settings.getBoolean("high contrast")) {
    colors.put("subtle black", #262626);
    colors.put("light gray",   #d9d9d9);
    colors.put("lighter gray", #e5e6e6);
  } else {
    colors.put("subtle black", #303030);
    colors.put("light gray",   #b2b2b2);
    colors.put("lighter gray", #c6c6c6);
  }
 
  colors.put("pink",         #fb007a);
  colors.put("dark red",     #c30771);
  colors.put("light red",    #e32791);
  colors.put("orange",       #d75f5f);
  colors.put("darker blue",  #005f87);
  colors.put("dark blue",    #008ec4);
  colors.put("light blue",   #20bbfc);  // pencil calls this blue
  colors.put("pale blue",    #b6d6fd);  // pencil calls this light blue
  colors.put("dark cyan",    #20a5ba);
  colors.put("light cyan",   #4fb8cc);
  colors.put("dark green",   #10a778);
  colors.put("light green",  #5fd7a7);
  colors.put("dark purple",  #523c79);
  colors.put("light purple", #6855de);
  colors.put("yellow",       #f3e430);
  colors.put("dark yellow",  #a89c14);


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
  keybindings.put('u', "show ui");
  keybindings.put('s', "use shaders");
  
  // UI
  guiContainer = new GUIContainer();

  // setting sliders
  int sliderHeight = 200;
  int sliderMargin = 30;
  int nextSliderXPos = 50;

  testSlider = new Slider(sliderHeight, 50, 200, 100);
  testSlider.pos.x = nextSliderXPos;
  testSlider.pos.y = height - sliderMargin - sliderHeight;
  nextSliderXPos += sliderMargin + testSlider.getComponentWidth();
  guiContainer.add(testSlider);

  frictionSlider = new SettingSlider("Friction", "friction", sliderHeight,
                                     settings.getFloat("min friction"),
                                     settings.getFloat("max friction"), 5);
  frictionSlider.pos.x = nextSliderXPos;
  frictionSlider.pos.y = height - sliderMargin  - sliderHeight;
  nextSliderXPos += sliderMargin + frictionSlider.getComponentWidth();
  guiContainer.add(frictionSlider);
  
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
  logMsg(DEBUG, "key pressed: " + key);
  boolean boolSetting;
  String settingName;

  // setting toggles bound to keys
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
  if(settings.getBoolean("use shaders")) {
    fx.render()
      .blur(10, 0.5)
      //.blur(10, 1.3)
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
  
  // draw the UI
  if (settings.getBoolean("show ui")) {
    guiContainer.updateGUI();
  }

}
