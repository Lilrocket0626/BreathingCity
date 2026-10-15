/**
 * Creates the short-lived particles and elliptical ripples above the harbour.
 * Both systems are bounded so a long or loud input cannot grow memory use
 * forever. All rates, delays and lifetimes are measured in seconds rather than
 * frames, so the behaviour remains similar when the frame rate changes.
 */
class VisualEffects {
  /** Hard performance limit for simultaneously visible particles. */
  final int MAX_PARTICLES = 180;

  /** Hard performance limit for simultaneously visible ripple objects. */
  final int MAX_RIPPLES = 8;

  /** Active particles; expired objects are removed during reverse iteration. */
  ArrayList<BreathParticle> particles = new ArrayList<BreathParticle>();

  /** Active water ripples, stored from oldest to newest. */
  ArrayList<BreathWave> ripples = new ArrayList<BreathWave>();

  /** Fractional particles carried between frames for frame-rate-independent emission. */
  float emissionRemainder = 0;

  /** Seconds since the most recent ripple was created. */
  float sinceRipple = 10;

  /** True while the current visual sound event remains above its closing level. */
  boolean eventActive = false;

  /** Ripple whose strength is still being updated by the current sound event. */
  BreathWave currentWave;

  /** Clears all temporary effects when the input mode or test stage changes. */
  void reset() {
    particles.clear(); ripples.clear(); emissionRemainder = 0;
    sinceRipple = 10; eventActive = false; currentWave = null;
  }

  /**
   * Updates effect state and draws every active particle and ripple.
   *
   * @param energy processed control value from SignalEnvelope, from 0 to 1
   * @param dt elapsed frame time in seconds
   */
  void updateAndDraw(float energy, float dt) {
    sinceRipple += dt;

    // A second hysteresis pair separates visual breath events from noise gating.
    // Below 0.06 closes the event; above 0.12 can open a new event. The gap
    // prevents one fluctuating input from creating many ripples at the boundary.
    if (energy < 0.06) { eventActive = false; currentWave = null; }
    if (energy > 0.12 && !eventActive && sinceRipple >= 0.6) {
      currentWave = addRipple(energy);
      eventActive = true;
      sinceRipple = 0;
    }
    // Preserve the peak of the current event instead of freezing at its threshold.
    if (currentWave != null) currentWave.strength = max(currentWave.strength, energy);

    // A sustained strong input may create another ripple, but the 0.95-second
    // cooldown prevents an uncontrolled ripple on every rendered frame.
    if (eventActive && energy > 0.55 && sinceRipple >= 0.95) {
      currentWave = addRipple(energy);
      sinceRipple = 0;
    }

    // Convert an emission rate (particles per second) into a whole number for
    // this frame. Keeping the fractional remainder avoids dependence on FPS.
    if (energy > 0.025) emissionRemainder += (12 + 95 * energy) * dt;
    else emissionRemainder = 0;
    int emit = min(int(emissionRemainder), MAX_PARTICLES - particles.size());
    for (int i = 0; i < emit; i++) particles.add(new BreathParticle(energy));
    // Drop excess emission when full. Never save a burst of deferred particles.
    emissionRemainder = emissionRemainder % 1;

    // Update newest-to-oldest so removing an expired object cannot shift an
    // unprocessed object into the index that the loop has already passed.
    for (int i = ripples.size() - 1; i >= 0; i--) {
      BreathWave wave = ripples.get(i);
      wave.updateAndDraw(dt);
      if (wave.age >= wave.duration) {
        if (currentWave == wave) currentWave = null;
        ripples.remove(i);
      }
    }
    for (int i = particles.size() - 1; i >= 0; i--) {
      BreathParticle particle = particles.get(i);
      particle.updateAndDraw(energy, dt);
      // Reverse iteration avoids skipping elements when ArrayList indices shift.
      if (particle.life <= 0 || particle.y < -20) particles.remove(i);
    }
  }

  /**
   * Adds one ripple and returns it so the current event can continue increasing
   * its recorded peak strength. If full, the oldest ripple is discarded first.
   */
  BreathWave addRipple(float energy) {
    if (ripples.size() >= MAX_RIPPLES) ripples.remove(0);
    BreathWave wave = new BreathWave(energy);
    ripples.add(wave);
    return wave;
  }
}

/** One glowing point that rises from the harbour and fades over time. */
class BreathParticle {
  /** Position, motion, lifetime, size and Perlin-noise sampling state. */
  float x, y, drift, life, initialLife, diameter, seed;

  /** Creates a particle near the water with controlled random variation. */
  BreathParticle(float energy) {
    // Spawn between the bridge and Opera House region, close to the shoreline.
    x = random(width * 0.16, width * 0.87);
    y = random(height * 0.715, height * 0.76);

    // A stored initial lifetime makes it possible to calculate fade percentage.
    initialLife = life = random(1.8, 3.2);
    diameter = random(1.5, 4.0);
    drift = random(-9, 9); seed = random(1000);
  }

  /** Moves, colours and draws the particle for one frame. */
  void updateAndDraw(float energy, float dt) {
    life -= dt;

    // Slowly advance through Perlin noise for organic horizontal movement.
    seed += dt * 0.5;
    x += (drift + (noise(seed) - 0.5) * 22) * dt;

    // Stronger input raises particles faster and makes them slightly larger.
    y -= (12 + 95 * energy) * dt;
    int tint = lerpColor(color(118, 212, 225), color(255, 211, 157), energy);
    noStroke();

    // Alpha decreases from 195 to zero as remaining life approaches zero.
    fill(red(tint), green(tint), blue(tint), max(0, life / initialLife) * 195);
    circle(x, y, diameter + energy * 3.5);
  }
}

/** One flattened expanding ellipse representing a wave from a sound event. */
class BreathWave {
  /** Radius and age change over time; strength stores the event's peak energy. */
  float radius = 12, age = 0, duration = 2.3, strength;

  /** Starts the ripple with the energy that opened the event. */
  BreathWave(float energy) { strength = energy; }

  /** Expands the ripple, fades its alpha, and draws it for one frame. */
  void updateAndDraw(float dt) {
    age += dt;

    // Stronger events expand faster and use a thicker line.
    radius += (55 + 150 * strength) * dt;
    noFill(); strokeWeight(0.8 + strength * 2.2);

    // Colour warms with strength while alpha falls linearly over its lifetime.
    stroke(154 + strength * 85, 215, 225 - strength * 60,
           max(0, 1 - age / duration) * (100 + 140 * strength));

    // A wide, shallow ellipse reads as a perspective ripple on the harbour.
    ellipse(width * 0.55, height * 0.79, radius * 2.5, radius * 0.29);
    strokeWeight(1);
  }
}
