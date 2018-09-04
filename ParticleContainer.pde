import java.util.List;

class ParticleContainer {

  ArrayList<Particle> particles;
  PVector gravity;
  Float velocityLimit;
  Float wallEnergy;
  Float wallPushDistance;
  Integer wallPadding;
  
  int top;
  int bottom;
  int left;
  int right;
  
  /**
   * Create a particle container.
   * - width/height: width and height of the container
   * - gravity: Vector() for the environmental gravitational force to be applied to all particles.
   * - friction: float with the friction of the container
   * - velocity_limit: limit particle velocities
   * - max_interaction_dist: distance which particles stop effecting each other
   * - wall_energy: the energy the walls have to use for pushing
   * - wall_push_distance: the distance at which the container walls start pushing particles
   * - wrap: boolean whether particles wrap around the edges of the container
   * - wall_padding: safety distance applied to walls
   */
  ParticleContainer() {
    this.particles = new ArrayList<Particle>();
    this.top = 0;
    this.bottom = height;
    this.left = 0;
    this.right = width;
    this.initWithDefaults();
  }

  void initWithDefaults() {
    this.gravity = new PVector(0, 0);
    this.velocityLimit = settings.getFloat("velocity limit");
    println(""+this.velocityLimit);
    this.wallEnergy = settings.getFloat("wall energy");
    println(""+this.wallEnergy);
    this.wallPushDistance = settings.getFloat("wall push distance");
    println(""+this.wallPushDistance);
    this.wallPadding = settings.getInt("wall padding");
    println(""+this.wallPadding);
  }
  
  void addParticle(Particle particle) {
    this.particles.add(particle);
  }
  
  void updateAndDraw() {
    // let particles interact with each other (no positions updated, just their velocities)
    this.applyParticleInteractions();
    
    // now apply wall bounce (+ limit to container) or let them wrap around
    for (Particle p : this.particles) {
      // bounce if not wrap around
      if (!settings.getBoolean("wrap around")) {
        this.bounceParticleOffWalls(p);
      }
      
      // apply environmental forces: friction, gravity, velocity limit
      this.applyFriction(p);
      this.applyGravity(p);
      if (settings.getBoolean("limit velocity"))
        this.limitParticleVelocity(p);
      
      // let each particle update its position based on its acceleration and velocity
      p.update();
      
      // restrict particle to container or let it wrap around
      if (settings.getBoolean("wrap around")) {
        this.wrapParticle(p);
      } else {
        this.restrictParticleToContainer(p);
      }
      
      // finally, draw the particle
      p.draw();
    }
  }
  
  void wrapParticle(Particle p) {
    if (p.pos.x < this.left) {
      p.pos.x = this.right - this.wallPadding;
    } else if (p.pos.x > this.right) {
      p.pos.x = this.left + this.wallPadding;
    }
    
    if (p.pos.y < this.top) {
      p.pos.x = this.bottom - this.wallPadding;
    } else if (p.pos.y > this.bottom) {
      p.pos.y = this.top + this.wallPadding;
    }
  }
  
  void restrictParticleToContainer(Particle p) {
    if (p.pos.x <= this.left) {
      p.pos.x = this.left + this.wallPadding;
    } else if (p.pos.x >= right) {
      p.pos.x = this.right - this.wallPadding;
    }
    
    if (p.pos.y <= this.top) {
      p.pos.y = this.top + this.wallPadding;
    } else if (p.pos.y >= this.bottom) {
      p.pos.y = this.bottom - this.wallPadding;
    }
  }
  
  void applyFriction(Particle p) {
    PVector frictionForce = PVector.mult(p.vel, settings.getFloat("friction"));
    p.vel = PVector.sub(p.vel, frictionForce);
  }
  
  void applyGravity(Particle p) {
    p.vel.sub(this.gravity);
  }
  
  void limitParticleVelocity(Particle p) {
    p.vel.limit(this.velocityLimit);
  }

  /**
   * a sinus shaped down slope function  
   * slopeLength is the length of the slope, i.e. at what x value does the slope value hit 0
   * maxHeight is the highest slope value (top of slope)
   * slopeXpos is the x value to get the slope value from
   */
  float sinusDownSlope(float slopeLength, float maxHeight, float slopeXpos) {
    // anything equal to or beyond slopeLength gets the value 0
    if (slopeXpos >= slopeLength) {
      return 0;
    }
    
    // return max value at slopXpos 0 or less
    if (slopeXpos <= 0) {
      return maxHeight;
    }
    
    // calculate slopeValue
    float angle = (slopeXpos*PI)/slopeLength + HALF_PI;
    float halfHeight = maxHeight * 0.5;
    return sin(angle) * halfHeight + halfHeight;
  }
  
  /**
   * a sinus shaped up slope function  
   * slopeLength is the length of the slope, i.e. at what x value does the slope value hit maxHeight
   * maxHeight is the highest slope value (top of slope)
   * slopeXpos is the x value to get the slope value from
   */
  float sinusUpSlope(float slopeLength, float maxHeight, float slopeXpos) {
    // anything equal to or beyond slopeLength gets the value maxHeight
    if (slopeXpos >= slopeLength) {
      return maxHeight;
    }
    
    // return 0 value at slopXpos 0 or less
    if (slopeXpos <= 0) {
      return 0;
    }
    
    // calculate slopeValue
    float angle = (slopeXpos*PI)/slopeLength - HALF_PI;
    float halfHeight = maxHeight * 0.5;
    return sin(angle) * halfHeight + halfHeight;
  }
  
  /**
   * linear down slope
   * slopeLength is the length of the slope, i.e. at what x value does the slope value hit 0
   * maxHeight is the highest slope value (top of slope)
   * slopeXpos is the x value to get the slope value from
   */
   float linearDownSlope(float slopeLength, float maxHeight, float slopeXpos) {
    // anything equal to or beyond slopeLength gets the value 0
    if (slopeXpos >= slopeLength) {
      return 0;
    }
    
    // return maxHeight value at slopXpos 0 or less
    if (slopeXpos <= 0) {
      return maxHeight;
    }
    
    // calculate slopeValue
    return maxHeight - (slopeXpos*maxHeight/slopeLength);
  }
  
  /**
   * quadratic down slope
   * slopeLength is the length of the slope, i.e. at what x value does the slope value hit 0
   * maxHeight is the highest slope value (top of slope)
   * slopeXpos is the x value to get the slope value from
   */
  float quadraticDownSlope(float slopeLength, float maxHeight, float slopeXpos) {
    // anything equal to or beyond slopeLength gets the value 0
    if (slopeXpos >= slopeLength) {
      return 0;
    }
    
    // return maxHeight value at slopXpos 0 or less
    if (slopeXpos <= 0) {
      return maxHeight;
    }
    
    // calculate slopeValue
    return maxHeight - (sq(slopeXpos)*maxHeight/sq(slopeLength));
  }
  
  /**
   * linearly decreasing force based on distance (d): force = -d
   * force f at absolute distance d, with max force at d=0 : force = -d+f
   * direction of force, unit vector in direction, u_d: u_d * (-d+f)
   */
  PVector getPushForce(PVector direction, float maxPush, float distance) {
    //float force = (0-abs(distance)) + maxPush;
    //float force = this.sinusDownSlope(this.wallPushDistance, this.wallEnergy, distance);
    float force = this.linearDownSlope(this.wallPushDistance, this.wallEnergy, distance);
    return PVector.mult(direction, force); 
  }
  
  
  void bounceParticleOffWalls(Particle p) {
    // distances from walls to particle
    float wallDistance;
    
    // if particle is within wall_push_dist, apply a force inversely proportional to the distance
    // linearly decreasing wallPush effect -> y = -x
    // if energy is the max contribution when distance is 0 -> y = -x + energy
    
    // force intensity = 1/distance
    // to raise the intensity 
    //float forceIntensity;
    PVector wallForce;
    
    // cache using local variables for faster access
    float speedSize = p.speedSize;
    float halfSpeedSize = speedSize/2;
    float markerSize = p.speedSize*3;
    float halfSize = markerSize/2;
    float xpos = p.pos.x;
    float ypos = p.pos.y;
    float wallPushDistance =  this.wallPushDistance;
    
    // marker style
    rectMode(CORNER); // upperleft x, upperleft y, width, height
    colorMode(RGB, 1.0, 1.0, 1.0, 1.0);
    float wallCloseness;
    int fc = p.fillColor;
    int markerFillColor;
    //fill(p.fillColor);
    //stroke(p.strokeColor);
    noStroke();
    
    // thickness of wall marker
    //float markerThickness = settings.getFloat("wall marker thickness");
    float markerThickness;
    
    // draw marker?
    boolean drawMarker = settings.getBoolean("draw wall markers");
    
    // bottom
    wallDistance = abs(this.bottom - ypos);
    if (wallDistance < wallPushDistance) {
      if(drawMarker) {
        markerThickness = wallDistance-halfSpeedSize;
        wallCloseness = (wallPushDistance-wallDistance)/wallPushDistance;
        markerFillColor = color(red(fc), green(fc), blue(fc), wallCloseness);
        fill(markerFillColor);
        rect(xpos-halfSize, this.bottom-markerThickness, markerSize, markerThickness);
      }
      wallForce = this.getPushForce(upVector, this.wallEnergy, wallDistance);
      p.vel.add(wallForce);
    }
    
    // top
    wallDistance = abs(this.top - ypos);
    if (wallDistance < wallPushDistance) {
      if (drawMarker) {
        markerThickness = wallDistance-halfSpeedSize;
        wallCloseness = (wallPushDistance-wallDistance)/wallPushDistance;
        markerFillColor = color(red(fc), green(fc), blue(fc), wallCloseness);
        fill(markerFillColor);
        rect(xpos-halfSize, this.top, markerSize, markerThickness);
      }
      wallForce = this.getPushForce(downVector, this.wallEnergy, wallDistance);
      p.vel.add(wallForce);
    }
    
    // left
    wallDistance = abs(this.left - xpos);
    if (wallDistance < wallPushDistance) {
      if (drawMarker) {
        markerThickness = wallDistance-halfSpeedSize;
        wallCloseness = (wallPushDistance-wallDistance)/wallPushDistance;
        markerFillColor = color(red(fc), green(fc), blue(fc), wallCloseness);
        fill(markerFillColor);
        rect(this.left, ypos-halfSize, markerThickness, markerSize);
      }
      wallForce = this.getPushForce(rightVector, this.wallEnergy, wallDistance);
      p.vel.add(wallForce);
    }
    
    // right
    wallDistance = abs(this.right - xpos);
    if (wallDistance <  wallPushDistance) {
      if (drawMarker) {
        markerThickness = wallDistance-halfSpeedSize;
        wallCloseness = (wallPushDistance-wallDistance)/wallPushDistance;
        markerFillColor = color(red(fc), green(fc), blue(fc), wallCloseness);
        fill(markerFillColor);
        rect(this.right-markerThickness, ypos-halfSize, markerThickness, markerSize);
      }
      wallForce = this.getPushForce(leftVector, this.wallEnergy, wallDistance);
      p.vel.add(wallForce);
    }
    
  }
  
  PVector calculatePushForce(PVector distanceToTrg, float pushRange, float pushEnergy) {
    return null;
  }
  
  /**
   * The source particle attracts the target particle.
   *
   * The source particle attracts the target particle and applies a force
   * directed towards the source particle to the target particle. The
   * length of the force is proportional to the size of the source and
   * inversely proportional to the distance between source and target.
   */
  void attractTarget(Particle src, Particle trg, float maxDistance) {
    // towards src from trg
    PVector attractVector = PVector.sub(src.pos, trg.pos);
    PVector direction = attractVector.copy().normalize();
    float distance = attractVector.mag();
    
    float amount = this.linearDownSlope(maxDistance, src.energy, distance);
    PVector attractForce = PVector.mult(direction, amount);
    trg.vel.add(attractForce);
  }
  
  void repelledByTarget(Particle src, Particle trg, float maxDistance, float repellFactor) {
    // from src away from trg, i.e. to src from trg
    PVector repellVector = PVector.sub(src.pos, trg.pos);
    PVector direction = repellVector.copy().normalize();
    float distance = repellVector.mag();
    
    float amount = this.quadraticDownSlope(maxDistance, trg.energy*repellFactor, distance);
    PVector attractForce = PVector.mult(direction, amount);
    src.vel.add(attractForce);
  }
  
  /**
   * Return the tuple (pref_pos, rel_pref_pos).
   *
   * - pref_pos is the absolute preferred position for src_p
   * - rel_pref_pos is the preferred position of src_p, relative to src_p
   */
  PVector calculatePreferredPos(Particle src, Particle trg) {
    PVector toTrgFromSrc = PVector.sub(trg.pos, src.pos);
    PVector direction = toTrgFromSrc.copy().normalize();
    return PVector.mult(direction, src.preferredDistance).add(src.pos);
  }
  
  /**
   * Apply interactions between particles.
   *
   * The current model for interactions is that each particle only moves
   * itself.
   *   
   * TODO: Dual model where some interactions are:
   *       1) active (particle applies forces to itself) and
   *       2) passive (forces applied by other particles)
   */
  void applyParticleInteractions() {
    for(Particle src : this.particles) {
      for(Particle trg : this.particles) {
        if(trg == src)
          continue;

        float absDist = src.pos.dist(trg.pos);
        
        // cache settings etc locally
        float interactionDistance = settings.getFloat("interaction distance");
        float preferredDistance = settings.getFloat("preferred distance");
        // distance preferred markers show up
        float preferredReach = settings.getFloat("preferred reach");

        // skip interactions outside of range
        // interaction distance 0 means unlimited interaction, i.e. everything interacts
        // preferredReach is the distance preferred markers start being displayed
        // don't skip src/trg pair if absDist is within either interactionDistance or preferredReach
        if (interactionDistance > 0 && absDist > interactionDistance && absDist > preferredReach)
          continue;
        
        // show interactions?
        if (settings.getBoolean("draw interactions")) {
          //colorMode(HSB, 360, 100, 100, 1.0);
          colorMode(RGB, 1.0, 1.0, 1.0, 1.0);
          float interactionStr = (interactionDistance-absDist)/interactionDistance*0.4;
          /*
          int interactionColor = color((hue(src.strokeColor)+hue(trg.strokeColor))/2,
                                       (saturation(src.strokeColor)+saturation(trg.strokeColor))/2,
                                       (brightness(src.strokeColor)+brightness(trg.strokeColor))/2,
                                       interactionStr);
          */
          int interactionColor = color((red(src.strokeColor)+red(trg.strokeColor))/2,
                                       (green(src.strokeColor)+green(trg.strokeColor))/2,
                                       (blue(src.strokeColor)+blue(trg.strokeColor))/2,
                                       interactionStr);
          stroke(interactionColor);
          line(src.pos.x, src.pos.y, trg.pos.x, trg.pos.y);
        }
        
        if (settings.getBoolean("draw preferred distance")) {
          PVector preferredPos = this.calculatePreferredPos(src, trg);
          colorMode(RGB, 1.0, 1.0, 1.0, 1.0);
          int strokeColor = color(red(trg.strokeColor),
                                  green(trg.strokeColor),
                                  blue(trg.strokeColor),
                                  0.20);
          int fillColor = color(red(trg.fillColor),
                                green(trg.fillColor),
                                blue(trg.fillColor),
                                0.20);

          float prefMarkerSize = settings.getFloat("preferred marker size");
          fill(fillColor);
          //stroke(strokeColor);
          noStroke();
          ellipseMode(CENTER);
          ellipse(preferredPos.x, preferredPos.y, prefMarkerSize, prefMarkerSize);
          stroke(fillColor);
          line(preferredPos.x, preferredPos.y, src.pos.x, src.pos.y);
        }
        
        // Each particle attracts all other particles. One at the time.
        if (settings.getBoolean("apply attraction"))
          this.attractTarget(src, trg, interactionDistance);
        
        // Each particle wants its own space. Is repelled by one target at the time.
        if (settings.getBoolean("apply repell"))
          this.repelledByTarget(src, trg, preferredDistance, settings.getFloat("repell factor"));
        
        /* To be implemented later
        // used later for keeping track of if we are to hunt or flee
        boolean fleeFromTrg = false;
        
        // distance towards trg from src, i.e. the vector points towards trg from src
        PVector srcToTrg = PVector.sub(trg.pos, src.pos);
        
        // distance pointing away from trg, i.e. the vector points towards src from trg
        PVector srcAwayFromTrg = PVector.sub(src.pos, trg.pos);
        
        // decide to hunt or flee
        // TODO
        
        // coordinates (as vector) of preferredPosition relative trg 
        PVector preferredPos = this.calculatePreferredPos(src, trg);

        // required change in position of src to reach the preferred position
        // i.e. to preferred position from src position.
        PVector travelVector = PVector.sub(preferredPos, src.pos);
        */
        
      }
    }
  }
}

/*


*/
