static int componentCounter = 0;

class GUIComponent {

  String name;
  PGraphics widget;
  PVector pos;
  int width;
  int height;
  PGraphics label;
  String labelText;
  int labelHeight;
  int labelPadding;
  boolean visible;
  
  int mousePressedX;
  int mousePressedY;
  boolean trackMouseButton;
  boolean trackMouseEnter;
  boolean trackDragging;
  PVector dragVector;
  PVector deltaVector;
 
  int bgColor;
  int activeBgColor;
  int inactiveBgColor;
  int labelBgColor;
  int labelBgInactiveColor;
  int labelBgActiveColor;
  int labelTextColor;
  int labelTextInactiveColor;
  int labelTextActiveColor;
  
  GUIComponent() {
    this.pos = new PVector(0, 0);
    this.name = "component" + componentCounter;
    componentCounter++;
    
    this.dragVector = null;
    this.deltaVector = null;
    
    this.pos = new PVector(0, 0);
    this.bgColor = colors.get("light gray");
    
    this.trackMouseButton = false;
    this.trackMouseEnter = false;
    this.trackDragging = false;

    this.visible = true;
  }

  /**
   * Return the width of the component
   */
  int getComponentWidth() {
    return this.width;
  }

  boolean isMouseOver() {
    if (mouseX >= this.pos.x && mouseX <= this.pos.x + this.width &&
        mouseY >= this.pos.y && mouseY <= this.pos.y + this.height) {
      return true;
    } else {
      return false;
    }
  }
  
  // mouse entered component
  void componentEntered() {
    logMsg(DEBUG_VERBOSE, this.name + " entered.");
  }
  
  // mouse exited component
  void componentExited() {
    logMsg(DEBUG_VERBOSE, this.name + " exited.");
  }
  
  // mouse pressed on component
  void componentPressed() {
    logMsg(DEBUG_VERBOSE, this.name + " pressed.");
  }
  
  // mouse released inside component after being pressed inside component
  void componentReleasedInside() {
    logMsg(DEBUG_VERBOSE, this.name + " released inside.");
  }
  
  // mouse released outside component after being pressed inside component
  void componentReleasedOutside() {
    logMsg(DEBUG_VERBOSE, this.name + " released outside.");
  }

  // mouse clicked, i.e. pressed and relased without moving mouse
  void componentClicked() {
    logMsg(DEBUG_VERBOSE, this.name + " clicked.");
  }

  // during drag, except first (.componentDragStart())
  void componentDragged() {
      logMsg(DEBUG_VERBOSE,
             this.name + " is being dragged from (" +
             this.mousePressedX + ", " + this.mousePressedY + ") to (" +
             mouseX + ", " + mouseY + "). delta: (" +
             this.deltaVector.x + ", " + this.deltaVector.y + ")");
  }

  // first drag event
  void componentDragStart() {
    logMsg(DEBUG, "First drag");
  }

  // drag stopped
  void componentDragEnded() {
    logMsg(DEBUG, "Dragging stopped");
  }
    
  /**
   * Always override GUIComponent.draw() in subclasses.
   */
  void draw() {
    this.widget.beginDraw();
    this.widget.background(this.bgColor);
    this.widget.endDraw();
    
    // show component
    image(this.widget, this.pos.x, this.pos.y);
  }
  
}


class Slider extends GUIComponent {

  float value;
  float minValue;
  float maxValue;
  float valueScopeSize;         // number of values slider can represent
  float markerPos2ValueFactor;  // factor to multiply markerPos with to scale to possible values
  float value2markerPosFactor;  // factor to multiply value with to scale to possible markerPos:es
  float sliderLength;
  float sliderMin;

  float markerPos;
  int markerWidth;
  int markerHeight;
  int markerColor;
  int markerActiveColor;
  int markerInactiveColor;

  Slider(int size, float minValue, float maxValue, float value) {
    super();

    // value stuff
    this.minValue = minValue;
    this.maxValue = maxValue;
    this.valueScopeSize = this.maxValue - this.minValue;
    this.value = value;
    
    // widget stuff
    this.width = 16;
    this.height = size;
    this.sliderLength = size;
    this.sliderMin = 0;
    this.markerPos2ValueFactor = this.valueScopeSize / this.sliderLength;  // scale drag to valueScopeSize
    this.value2markerPosFactor = this.sliderLength / this.valueScopeSize;  // scale value to sliderLength

    // label
    this.labelHeight = 14;
    this.labelPadding = 1;
    this.labelText = "Slider";

    // draggable marker 
    this.markerWidth = this.width;
    this.markerHeight = 5;
    this.updateMarkerPosFromValue();

    // colors
    this.activeBgColor = modifyAlpha(colors.get("white"), activeAlpha);
    this.inactiveBgColor = modifyAlpha(colors.get("light gray"), inactiveAlpha);
    this.bgColor = this.inactiveBgColor;

    this.labelBgActiveColor = modifyAlpha(colors.get("white"), activeAlpha);
    this.labelBgInactiveColor = modifyAlpha(colors.get("light gray"), inactiveAlpha);
    this.labelBgColor = this.labelBgInactiveColor;
    this.labelTextActiveColor = modifyAlpha(colors.get("light black"), activeAlpha);
    this.labelTextInactiveColor = modifyAlpha(colors.get("lighter black"), activeAlpha);;
    this.labelTextColor = this.labelTextInactiveColor;

    this.markerActiveColor = modifyAlpha(colors.get("light red"), activeAlpha);
    this.markerInactiveColor = modifyAlpha(colors.get("dark red"), inactiveAlpha);
    this.markerColor = this.markerInactiveColor;

    // create graphics objects to draw on
    this.widget = createGraphics(this.width, this.height);
    this.label = createGraphics(this.height, this.labelHeight);
  }

  // set marker colors to dark basename (inactive) and light basename (active)
  void setMarkerColors(String baseName) {
    this.markerActiveColor = modifyAlpha(colors.get("light " + baseName), activeAlpha);
    this.markerInactiveColor = modifyAlpha(colors.get("dark " + baseName), inactiveAlpha);
  }

  @Override
  void componentDragged() {
    super.componentDragged();

    this.markerPos += this.deltaVector.y;

    // marker gets dragged. limit its position.
    if (this.markerPos < this.sliderMin)
      this.markerPos = this.sliderMin;
    else if (this.markerPos > this.sliderLength)
      this.markerPos = this.sliderLength;

    // Update value (also fires valueChanged())
    this.updateValueFromMarkerPos();
  }

  /**
   * Update value based on markerPos, fire valueChanged()
   */
  void updateValueFromMarkerPos() {
    // first calculate based on UI to value factor
    float relValue = this.valueScopeSize - this.markerPos2ValueFactor * this.markerPos;

    // then set value taking minValue into account
    this.value = relValue + this.minValue;
    logMsg(DEBUG_VERBOSE, "value updated from markerPos. value: " + this.value + ". markerPos: " + this.markerPos);
    this.valueChanged();
  }

  /**
   * Update markerPos based on current value
   */
  void updateMarkerPosFromValue() {
    // first remove minValue
    float relValue = this.value - this.minValue;
    
    // then convert to markerPos
    this.markerPos = this.sliderLength - this.value2markerPosFactor * relValue;
    logMsg(DEBUG, "markerPos updated. markerPos: " + this.markerPos + ". value: " + this.value);
  }

  // this is run when value changes. nice for subclassing
  void valueChanged() {
    // this does nothing but is used in e.g. the SettingSlider subclass
  }

  // used during draw to format text for label, override when subclassing
  String getLabelDisplayText() {
    return String.format(this.labelText + ": %.1f", this.value);
  }

  @Override
  int getComponentWidth() {
    return this.width + this.labelHeight;
  }

  @Override
  void draw() {
    // less verbose code
    PGraphics g;

    // colors depends on mouse over/drag
    if (this.trackMouseEnter || this.trackMouseButton) {
      this.bgColor = this.activeBgColor;
      this.markerColor = this.markerActiveColor;
      this.labelBgColor = this.labelBgActiveColor;
      this.labelTextColor = this.labelTextActiveColor;
    }
    else {
      this.bgColor = this.inactiveBgColor;
      this.markerColor = this.markerInactiveColor;
      this.labelBgColor = this.labelBgInactiveColor;
      this.labelTextColor = this.labelTextInactiveColor;
    }

    // draw slider
    g = this.widget;
    g.beginDraw();
    g.background(this.bgColor);

    // and its marker
    g.fill(this.markerColor);
    g.noStroke();

    // handle slider
    //g.rectMode(CENTER);
    //g.rect(this.width/2, markerPos, this.markerWidth, this.markerHeight);

    // bar slider
    g.rectMode(CORNER);
    g.rect(0, markerPos, this.markerWidth, this.height-this.markerPos);
    g.endDraw();    

    // draw label
    // TODO: center label vertically
    g = this.label;
    g.beginDraw();
    g.background(this.labelBgColor);
    g.fill(this.labelTextColor);
    g.textSize(this.labelHeight-this.labelPadding*2);
    g.textAlign(LEFT, TOP);
    g.rectMode(CORNER);
    g.text(this.getLabelDisplayText(), this.labelPadding, this.labelPadding);
    g.endDraw();

    // save current coordinate system
    pushMatrix();
    
    // show slider relative to external position
    g = this.widget;
    translate(this.pos.x, this.pos.y);
    image(g, 0, 0);
   
    // show slider label, to the left of slider rotated 90 deg clockwise
    g = this.label;
    translate(this.width, 0);        // move right of slider
    rotate(HALF_PI);                 // rotate 90 deg clockwise
    translate(0, -this.labelHeight); // out from slider
    image(g, 0, 0);

    // restore coordinate system
    popMatrix();
    
  }
}


/**
 * Slider for settings that are floats
 */
class SettingSlider extends Slider {

  String settingKey;
  int precision;

  SettingSlider(String settingKey, int size, int precision) {
    super(size,
          settings.getFloat("min " + settingKey),
          settings.getFloat("max " + settingKey),
          settings.getFloat(settingKey));
    this.settingKey = settingKey;
    this.labelText = settingKey;
    this.precision = precision;
  }

  @Override
  String getLabelDisplayText() {
    String formatString = this.labelText + ": %." + this.precision + "f";
    return String.format(formatString, this.value);
  }

  @Override
  void valueChanged() {
    logMsg(DEBUG, "Changing setting value '" + this.settingKey + "' to " + this.value);
    settings.setFloat(this.settingKey, this.value);
  }

}

// vim:fdm=syntax
