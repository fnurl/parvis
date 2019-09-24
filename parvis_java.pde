import java.util.Map;

// postfx
import ch.bildspur.postfx.builder.*;
import ch.bildspur.postfx.pass.*;
import ch.bildspur.postfx.*;

PostFX fx;

/**
 * Global context variables are accessible from all classes.
 */

// debug level. 0 is none, 5 is alot.
final static int ERRORS = 1;
final static int INFO = 2;
final static int DEBUG = 3;
final static int DEBUG_VERBOSE = 4;

final static int LOGLEVEL = INFO;

JSONObject settings;          // will load settings.json into settings
JSONObject colorSettings;     // will load colors.json into colorSettings
int idCounter;

// keyboard controls
HashMap<Character,String> keybindings;
StringBuilder helpText;

// some colors
HashMap<String,Integer> colors;        // color names as keys, colors as values (ints)
HashMap<String,String> currentTheme;   // GUI element names as keys, and color names as values
HashMap<String,String> lightTheme;     // light theme
HashMap<String,String> darkTheme;      // dark theme
//String bgColor;
//String textColor;
String colorStyle;
final int inactiveAlpha = 128;
final int activeAlpha = 192;

// font
PFont font;

// UI
GUIContainer guiContainer;
//Slider testSlider;
//SettingSlider frictionSlider;

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

/**
 * Return a theme (HashMap<String,String> of element names and color names)
 * loaded from a JSON file.
 */
HashMap<String,String> loadTheme(String filename) {
  HashMap<String,String> theme = new HashMap<String,String>();
  JSONObject json = loadJSONObject(filename);
  String[] elementNames = (String[]) json.keys().toArray(new String[json.size()]);
  for (String elementName : elementNames) {
    theme.put(elementName, json.getString(elementName));
  }
  return theme;
}

/**
 * Return a HashMap<String,Integer> of color names and colors loaded from
 * a JSON file.
 */
HashMap<String,Integer> loadColors(String filename) {
  HashMap<String,Integer> loadedColors = new HashMap<String,Integer>();
  JSONObject json = loadJSONObject(filename);
  String[] colorNames = (String[]) json.keys().toArray(new String[json.size()]);
  int unhexed;

  colorMode(RGB, 255, 255, 255);
  for (String colorName : colorNames) {
    unhexed = unhex(json.getString(colorName));
    loadedColors.put(colorName, color(red(unhexed), green(unhexed), blue(unhexed)));
  }
  return loadedColors;
}

/**
 * Return the color value associated with a specific theme element using the
 * current theme and the currently loaded colors/color names
 */
int getThemeColor(String elementName) {
  return colors.get(currentTheme.get(elementName));
}

void setup() {
  //fullScreen(P3D);
  //fullScreen(P2D);

  size(1280, 800, P3D);
  //size(1280, 800, P2D);

  //size(800, 600, P3D);
  //size(800, 600, P2D);

  logMsg(INFO, "Loading settings...");
  settings = loadJSONObject("settings.json");
  
  logMsg(INFO, "Preparing shaders...");
  fx = new PostFX(this);
 
  // load and set up colors
  logMsg(INFO, "Loading colors...");
  colors = loadColors("colors.json");

  // color themes
  logMsg(INFO, "Loading themes...");
  lightTheme = loadTheme("light-theme.json");
  darkTheme = loadTheme("dark-theme.json");
  currentTheme = lightTheme;

  // color style
  colorStyle = "random";

  // font
  logMsg(INFO, "Loading font...");
  font = createFont("FantasqueSansMono-Regular", 15, true);
  textFont(font, 15);

  // keybindings
  logMsg(INFO, "Binding keys...");
  keybindings = new HashMap<Character,String>();
  keybindings.put('a', "apply attraction");
  keybindings.put('r', "apply repell");
  keybindings.put('l', "limit velocity");
  keybindings.put('w', "wrap around");
  keybindings.put('t', "draw attracts");
  keybindings.put('e', "draw repells");
  keybindings.put('p', "draw preferred distance");
  keybindings.put('i', "draw particles");
  keybindings.put('m', "draw wall markers");
  keybindings.put('v', "draw velocity line");
  keybindings.put('V', "reverse velocity line");
  keybindings.put('z', "draw speedsize");
  keybindings.put('Z', "invert speedsize");
  keybindings.put('u', "show ui");
  keybindings.put('n', "show info");
  keybindings.put('h', "show help");
  keybindings.put('f', "show FPS");
  keybindings.put('s', "use shaders");
  
  // UI
  logMsg(INFO, "Initializing GUI...");
  guiContainer = new GUIContainer();
  guiContainer.addSettingSlider("friction", 5);
  guiContainer.addSettingSlider("velocity limit", 0);
  guiContainer.addSettingSlider("particle energy", 2);
  guiContainer.addSettingSlider("attract distance", 0);
  guiContainer.addSettingSlider("attract factor", 0);
  guiContainer.addSettingSlider("repell distance", 0);
  guiContainer.addSettingSlider("repell factor", 0);
  //guiContainer.addSettingSlider("preferred reach", 0);
  guiContainer.addSettingSlider("particle size", 0);
  guiContainer.addSettingSlider("speed magnification", 0);
  guiContainer.addSettingSlider("velocity line scale", 0);

  logMsg(INFO, "Creating particles...");
  // particle container
  particleContainer = new ParticleContainer();
  
  // add particles
  idCounter = 0;
  int numParticles = settings.getInt("number of particles");
  for(int i=0; i < numParticles; i++) {
    particleContainer.createAndAddParticle();
  }
  logMsg(INFO, "Starting!");

  // calling frameRate to early produces a crash
  frameRate(60);
}

void keyPressed() {
  logMsg(INFO, "key pressed: " + key);
  boolean boolSetting;
  String settingName;

  // setting toggles bound to keys
  if (keybindings.containsKey(key)) {
    settingName = keybindings.get(key);
    boolSetting = settings.getBoolean(settingName);
    settings.setBoolean(settingName, !boolSetting);
    logMsg(INFO, "setting toggled: " + settingName);
    return;
  }
  
  // non-boolean toggle keybindings
  switch(key) {
    case 'b':
      logMsg(INFO, "Toggle theme.");
      if (currentTheme == lightTheme) {
        currentTheme = darkTheme;
      } else if (currentTheme == darkTheme) {
        currentTheme = lightTheme;
      }
      guiContainer.updateColors();
      break;
    case 'c':
      logMsg(INFO, "Add particle.");
      particleContainer.createAndAddParticle();
      break;
    case 'd':
      logMsg(INFO, "Delete particle.");
      particleContainer.removeRandomParticle();
      break;
    case 'S':
      logMsg(INFO, "Toggle color style.");
      if (colorStyle.equals("pinkish")) {
        colorStyle = "random";
      } else {
        colorStyle = "pinkish";
      }
      particleContainer.updateColorStyle();
      break;
    case 'q':
      logMsg(INFO, "Byebye.");
      exit();
  }

}

void showHelp() {
  if (helpText == null) {
    helpText = new StringBuilder();
    for (char keyBinding : keybindings.keySet()) {
      helpText.append(keyBinding);
      helpText.append(" - ");
      helpText.append(keybindings.get(keyBinding));
      helpText.append("\n");
    }
    // help for non-setting toggles
    helpText.append("b - toggle background light/dark background\n");
    helpText.append("c - create a new particle\n");
    helpText.append("d - delete a random particle\n");
  }

  //textSize(14);
  //textFont(font, 14);
  textAlign(LEFT, TOP);
  //fill(colors.get(textColor));
  fill(getThemeColor("text"));
  rectMode(CORNER);
  text(helpText.toString(), 20, 20, 400, height-20);
}

void showInfo() {
  StringBuilder infoText = new StringBuilder();
  for (char keyBinding : keybindings.keySet()) {
    infoText.append(keybindings.get(keyBinding));
    infoText.append(": ");
    if (settings.getBoolean(keybindings.get(keyBinding))) {
      infoText.append(" *\n");
    } else {
      infoText.append("  \n");
    }
  }
  //infoText.append("background: ");
  //infoText.append(bgColor);
  //infoText.append("\n");
  infoText.append("#particles: ");
  infoText.append(String.valueOf(particleContainer.getNumberOfParticles()));
  infoText.append("\n");

  int boxWidth = 300;
  int boxMargin = 20;
  //textSize(14);
  //textFont(font, 14);
  textAlign(RIGHT, TOP);
  //fill(colors.get(textColor));
  fill(getThemeColor("text"));
  rectMode(CORNER);
  text(infoText.toString(), width-boxMargin-boxWidth, boxMargin, boxWidth, height-boxMargin);
}

void showFPS() {
  fill(getThemeColor("text"));
  rectMode(CORNER);
  textAlign(LEFT, BOTTOM);
  text(frameRate, 0, height);
}

void draw() {
  //background(colors.get(bgColor));
  background(getThemeColor("background"));
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

  if (settings.getBoolean("show help")) {
    showHelp();
  }

  if (settings.getBoolean("show info")) {
    showInfo();
  }

  if (settings.getBoolean("show FPS")) {
    showFPS();
  }

}
