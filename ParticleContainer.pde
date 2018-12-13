import java.util.List;

class ParticleContainer {

  ArrayList<Particle> particles;
  PVector gravity;
  float wallEnergy;
  float wallPushDistance;
  int wallPadding;
  
  int top;
  int bottom;
  int left;
  int right;
  
  /**
   * Create a particle container.
   * Settings and default values are fetched from settings.json
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
    
    // only load non-global settings into instance variables
    this.wallEnergy = settings.getFloat("wall energy");
    this.wallPushDistance = settings.getFloat("wall push distance");
    this.wallPadding = settings.getInt("wall padding");
  }
  
  void addParticle(Particle particle) {
    this.particles.add(particle);
  }

  // create, add and return new Particle (for further customization)
  Particle createAndAddParticle() {
    Particle particle = new Particle();
    this.particles.add(particle);
    logMsg(DEBUG_VERBOSE, "Created particle.");
    return particle;
  }

  void removeRandomParticle() {
    int numParticles = this.particles.size();
    if (numParticles > 0) {
      //this.particles.remove(random(0, numParticles));
      this.particles.remove(0);
      logMsg(DEBUG_VERBOSE, "Deleted particle.");
    }
  }

  int getNumberOfParticles() {
    return this.particles.size();
  }

  void updateColorStyle() {
    for (Particle p : this.particles) {
      p.updateColorStyle();
    }
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
      if (settings.getBoolean("apply friction"))
        this.applyFriction(p);
      if (settings.getBoolean("apply gravity"))
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
  
  /**
   * Wrap a particle around container edges if necessary
   */
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
  
  /**
   * Prevent particle from leaving the container bounds.
   */
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

  /**
   * Reduce the velocity of a particle by a percentage (friction)
   * stored in settings.
   */
  void applyFriction(Particle p) {
    PVector frictionForce = PVector.mult(p.vel, settings.getFloat("friction"));
    p.vel = PVector.sub(p.vel, frictionForce);
  }
  
  /**
   * Add gravitational force to particel velocity
   */
  void applyGravity(Particle p) {
    p.vel.add(this.gravity);
  }
  
  /**
   * Limit a particles velocity.
   * value is fetched from settings.
   */
  void limitParticleVelocity(Particle p) {
    p.vel.limit(settings.getFloat("velocity limit"));
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
  
  /**
   * Repell particle from walls.
   */
  void bounceParticleOffWalls(Particle p) {
    // distances from walls to particle
    float wallDistance;
    PVector wallForce;
    
    // cache using local variables for faster access
    float speedSize = p.speedSize;
    float halfSpeedSize = speedSize/2;
    float markerSize = p.speedSize*3;
    float halfSize = markerSize/2;
    float xpos = p.pos.x;
    float ypos = p.pos.y;
    float wallPushDistance =  this.wallPushDistance;
    boolean drawMarker = settings.getBoolean("draw wall markers");
    int fc = p.particleColor;
    
    // marker style
    float wallCloseness;
    float markerThickness;
    int markerFillColor;
    
    // set up drawing
    rectMode(CORNER); // upperleft x, upperleft y, width, height
    colorMode(RGB, 1.0, 1.0, 1.0, 1.0);
    noStroke();
    
    // bottom
    wallDistance = abs(this.bottom - ypos);
    if (wallDistance < wallPushDistance) {
      if(drawMarker) {
        markerThickness = wallDistance - halfSpeedSize;
        wallCloseness = (wallPushDistance - wallDistance) / wallPushDistance;
        markerFillColor = color(red(fc), green(fc), blue(fc), wallCloseness);

        fill(markerFillColor);
        rect(xpos - halfSize, this.bottom - markerThickness, markerSize, markerThickness);
      }
      wallForce = this.getPushForce(upVector, this.wallEnergy, wallDistance);
      p.vel.add(wallForce);
    }
    
    // top
    wallDistance = abs(this.top - ypos);
    if (wallDistance < wallPushDistance) {
      if (drawMarker) {
        markerThickness = wallDistance - halfSpeedSize;
        wallCloseness = (wallPushDistance - wallDistance) / wallPushDistance;
        markerFillColor = color(red(fc), green(fc), blue(fc), wallCloseness);

        fill(markerFillColor);
        rect(xpos - halfSize, this.top, markerSize, markerThickness);
      }
      wallForce = this.getPushForce(downVector, this.wallEnergy, wallDistance);
      p.vel.add(wallForce);
    }
    
    // left
    wallDistance = abs(this.left - xpos);
    if (wallDistance < wallPushDistance) {
      if (drawMarker) {
        markerThickness = wallDistance - halfSpeedSize;
        wallCloseness = (wallPushDistance - wallDistance) / wallPushDistance;

        markerFillColor = color(red(fc), green(fc), blue(fc), wallCloseness);
        fill(markerFillColor);
        rect(this.left, ypos - halfSize, markerThickness, markerSize);
      }
      wallForce = this.getPushForce(rightVector, this.wallEnergy, wallDistance);
      p.vel.add(wallForce);
    }
    
    // right
    wallDistance = abs(this.right - xpos);
    if (wallDistance <  wallPushDistance) {
      if (drawMarker) {
        markerThickness = wallDistance - halfSpeedSize;
        wallCloseness = (wallPushDistance - wallDistance) / wallPushDistance;
        markerFillColor = color(red(fc), green(fc), blue(fc), wallCloseness);

        fill(markerFillColor);
        rect(this.right - markerThickness, ypos - halfSize, markerThickness, markerSize);
      }
      wallForce = this.getPushForce(leftVector, this.wallEnergy, wallDistance);
      p.vel.add(wallForce);
    }
    
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
    
    float amount = this.linearDownSlope(maxDistance, settings.getFloat("particle energy"), distance);
    PVector attractForce = PVector.mult(direction, amount * settings.getFloat("attract factor"));
    trg.vel.add(attractForce);
  }
  
  /**
   * Repell target particle based on source particle energy and repellfactor
   */
  void repellTarget(Particle src, Particle trg, float maxDistance) {
    // to trg from src
    PVector repellVector = PVector.sub(trg.pos, src.pos);
    PVector direction = repellVector.copy().normalize();
    float distance = repellVector.mag();
    
    float amount = this.quadraticDownSlope(maxDistance,
                                           settings.getFloat("particle energy") *
                                           settings.getFloat("repell factor"),
                                           distance);
    PVector repellForce = PVector.mult(direction, amount * settings.getFloat("repell factor"));
    trg.vel.add(repellForce);
  }
  
  /**
   * Apply interactions between particles.
   *
   * The current model for interactions is that each particle only moves
   * itself.
   *   
   * Dual model where some interactions are:
   *  1) active (particle applies forces to itself) TODO
   *  2) passive (forces applied by other particles) DONE!
   */
  void applyParticleInteractions() {

    // cache settings locally
    float attractDistance = settings.getFloat("attract distance");
    float repellDistance = settings.getFloat("repell distance");

    for(Particle src : this.particles) {
      for(Particle trg : this.particles) {
        
        // neither attracted or repelled by self.
        if(trg == src)
          continue;

        float absDist = src.pos.dist(trg.pos);
        
        // process attract/repell within range
        if (absDist <= attractDistance || absDist <= repellDistance) {
        
          // show repells
          if (settings.getBoolean("draw repells") && absDist <= repellDistance) {
            colorMode(RGB, 255, 255, 255);
            float repellStr = 255 * (repellDistance-absDist)/repellDistance;
            //int repellColor = modifyAlpha(colors.get("dark red"), int(repellStr));
            int repellColor = modifyAlpha(getThemeColor("repell line"), int(repellStr));
            stroke(repellColor);
            strokeWeight(3);
            line(src.pos.x, src.pos.y, trg.pos.x, trg.pos.y);
          }
        
          // show attracts
          if (settings.getBoolean("draw attracts") && absDist <= attractDistance) {
            colorMode(RGB, 255, 255, 255);
            float attractStr = 255 * (attractDistance-absDist)/attractDistance;
            //int attractColor = modifyAlpha(colors.get("dark green"), int(attractStr));
            int attractColor = modifyAlpha(getThemeColor("attract line"), int(attractStr));
            stroke(attractColor);
            strokeWeight(1);
            line(src.pos.x, src.pos.y, trg.pos.x, trg.pos.y);
          }
        
          // Each particle attracts all other particles. One at the time.
          if (settings.getBoolean("apply attraction"))
            this.attractTarget(src, trg, attractDistance);
          
          // Each particle wants its own space. Is repelled by one target at the time.
          if (settings.getBoolean("apply repell"))
            this.repellTarget(src, trg, repellDistance);
        }
       
        // particle initiated interaction
        src.interactWith(trg);

      }
    }
  }
}

