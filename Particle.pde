class Particle {
  
  // particle instance variables
  PVector pos;
  PVector acc;
  PVector vel;
  Float energy;
  Float preferredDistance;
  Float size;
  String name;
  Float repellFactor;
  Float attractFactor;

  int particleColor;
  int strokeColor;
  int velocityLineColor;
  
  float speedSize;
  
  Particle() {
    this("p" + String.valueOf(idCounter++));
  }
  
  Particle(String name) {
    this.name = name;
    this.initWithDefaults();
  }
  
  void initWithDefaults() {
    // position
    this.pos = new PVector(random(0, width), random(0, height));

    // acceleration
    this.acc = new PVector(0, 0);

    // velocity
    this.vel = new PVector(random(0, settings.getFloat("velocity limit")), 0);
    this.vel.rotate(random(0, PI));

    // energy
    this.energy = settings.getFloat("particle energy");

    // preferred distance
    this.preferredDistance = settings.getFloat("preferred distance");

    // size
    this.size = settings.getFloat("particle size");
    this.updateSpeedSize();
    
    // repell factor
    this.repellFactor = settings.getFloat("repell factor");
    
    // attract factor
    this.attractFactor = settings.getFloat("attract factor");

    // colors
    this.updateColorStyle();
  }

  /**
   * Update particle color config based on current value of global colorStyle
   * variable.
   */
  void updateColorStyle() {
    colorMode(HSB, 360, 100, 100, 100);
    float randomHue = random(0, 360);
    float randomSaturation = random(10, 70);
    float randomBrightness = random(40, 100);

    //float hue = idCounter/settings.getFloat("number of particles")*360;
    //this.particleColor = color(180, 50, randomBrightness, 90);
    //this.particleColor = color(0, 100, 100, 100);

    switch(colorStyle) {
      case "pinkish":
        this.particleColor = color(300, randomSaturation, 90, 90);
        break;
      default:
        this.particleColor = color(randomHue, 70, 90, 90);
    }

    this.strokeColor = color(hue(this.particleColor),
                             saturation(this.particleColor),
                             //brightness(this.particleColor) - 30,
                             0,
                             80);
  }

  /**
   * Return a src particle's preferred position relative to a
   * target particle and the source particle's preferredDistance 
   */
  PVector calculatePreferredPos(Particle trg) {
    PVector toTrgFromSrc = PVector.sub(trg.pos, this.pos);
    PVector direction = toTrgFromSrc.copy().normalize();
    return PVector.mult(direction, this.preferredDistance).add(this.pos);
  }
  
  // this is where the particle decides how to interact with other particles
  void interactWith(Particle trg) {
    if (settings.getBoolean("draw preferred distance")) {
      PVector preferredPos = this.calculatePreferredPos(trg);
      colorMode(RGB, 1.0, 1.0, 1.0, 1.0);
      float absDist = this.pos.dist(trg.pos);
      float preferredReach = settings.getFloat("preferred reach");
      float transparency = (preferredReach-absDist)/preferredReach*0.6;
      int strokeColor = color(red(trg.strokeColor),
                              green(trg.strokeColor),
                              blue(trg.strokeColor),
                              transparency);
      int trgParticleColor = color(red(trg.particleColor),
                            green(trg.particleColor),
                            blue(trg.particleColor),
                            transparency);

      // draw preferred distance line
      strokeWeight(2);
      stroke(trgParticleColor);
      line(preferredPos.x, preferredPos.y, this.pos.x, this.pos.y);
      float prefMarkerSize = settings.getFloat("preferred marker size");

      // draw preferred distance end dot
      fill(trgParticleColor);
      noStroke();
      ellipseMode(CENTER);
      ellipse(preferredPos.x, preferredPos.y, prefMarkerSize, prefMarkerSize);
    }
  }

  void applyAcceleration() {
    this.vel.add(acc);
    this.acc = this.acc.mult(settings.getFloat("acceleration decay"));
  }

  void applyVelocity() {
    this.pos.add(this.vel);
  }

  void updateSpeedSize() {
    //this.speedSize = this.vel.mag() * settings.getFloat("speed magnification") + this.size;
    if (settings.getBoolean("draw speedsize")) {
      this.speedSize = settings.getFloat("particle size") -
                       (this.vel.mag() * settings.getFloat("speed magnification"));
    } else {
      this.speedSize = settings.getFloat("particle size");
    }
  }

  void update() {
    this.applyAcceleration();
    this.applyVelocity();
    this.updateSpeedSize();
  }

  void draw() {
    
    // body
    if (settings.getBoolean("draw particles")) {
      fill(this.particleColor);
      strokeWeight(1);
      //stroke(this.strokeColor);
      noStroke();
      ellipseMode(CENTER);
      ellipse(this.pos.x, this.pos.y, this.speedSize, this.speedSize);
    }
    
    // velocity line
    float lineScale = settings.getFloat("velocity line scale");
    if (settings.getBoolean("draw velocity line")) {
      colorMode(RGB, 255, 255, 255);
      int velocityLineColorValue = getThemeColor("velocity line");
      //stroke(this.strokeColor);
      stroke(velocityLineColorValue);
      //stroke(getThemeColor("velocity line"));
      //stroke(colors.get("pale blue"));
      strokeWeight(2);
      if (settings.getBoolean("reverse velocity line")) {
        line(this.pos.x, this.pos.y,
             this.pos.x + this.vel.x*lineScale, this.pos.y + this.vel.y*lineScale);
      } else {
        PVector velocityLine = PVector.mult(this.vel, -1);
        line(this.pos.x, this.pos.y,
            this.pos.x + velocityLine.x*lineScale, this.pos.y + velocityLine.y*lineScale);
      }
    }

    // acceleration line
    // TODO
    
  }

}
