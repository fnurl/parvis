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

  int fillColor;
  int strokeColor;
  
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
    colorMode(HSB, 360, 100, 100, 100);
    //this.fillColor = color(random(0,360), 73, 78, 60);
    float hue = idCounter/settings.getFloat("number of particles")*360;
    this.fillColor = color(hue, 80, 80, 60);
    //this.fillColor = color(0, 100, 100, 100);
    this.strokeColor = color(hue(this.fillColor),
                             saturation(this.fillColor),
                             //brightness(this.fillColor) - 30,
                             0,
                             80);
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
    this.speedSize = this.size - (this.vel.mag() * settings.getFloat("speed magnification"));
  }

  void update() {
    this.applyAcceleration();
    this.applyVelocity();
    this.updateSpeedSize();
  }

  void draw() {
    fill(this.fillColor);
    stroke(this.strokeColor);
    strokeWeight(2);
    
    // body
    ellipseMode(CENTER);
    ellipse(this.pos.x, this.pos.y, this.speedSize, this.speedSize);
    
    // velocity line
    float lineScale = settings.getFloat("velocity line scale");
    if (settings.getBoolean("draw velocity line")) {
      line(this.pos.x, this.pos.y,
           this.pos.x + this.vel.x*lineScale, this.pos.y + this.vel.y*lineScale);
    }

    // acceleration line
    // TODO
    
  }

}
