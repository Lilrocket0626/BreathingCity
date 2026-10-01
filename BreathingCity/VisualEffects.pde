/** Bounded transient effects. All rates and lifetimes are measured in seconds. */
class VisualEffects {
  final int MAX_PARTICLES = 180;
  final int MAX_RIPPLES = 8;
  ArrayList<BreathParticle> particles = new ArrayList<BreathParticle>();
  ArrayList<BreathWave> ripples = new ArrayList<BreathWave>();
  float emissionRemainder = 0;
  float sinceRipple = 10;
  boolean eventActive = false;
  BreathWave currentWave;

  void reset() {
    particles.clear(); ripples.clear(); emissionRemainder = 0;
    sinceRipple = 10; eventActive = false; currentWave = null;
  }

  void updateAndDraw(float energy, float dt) {
    sinceRipple += dt;
    // A second hysteresis pair separates visual breath events from noise gating.
    if (energy < 0.06) { eventActive = false; currentWave = null; }
    if (energy > 0.12 && !eventActive && sinceRipple >= 0.6) {
      currentWave = addRipple(energy);
      eventActive = true;
      sinceRipple = 0;
    }
    // Preserve the peak of the current event instead of freezing at its threshold.
    if (currentWave != null) currentWave.strength = max(currentWave.strength, energy);
    if (eventActive && energy > 0.55 && sinceRipple >= 0.95) {
      currentWave = addRipple(energy);
      sinceRipple = 0;
    }

    if (energy > 0.025) emissionRemainder += (12 + 95 * energy) * dt;
    else emissionRemainder = 0;
    int emit = min(int(emissionRemainder), MAX_PARTICLES - particles.size());
    for (int i = 0; i < emit; i++) particles.add(new BreathParticle(energy));
    // Drop excess emission when full. Never save a burst of deferred particles.
    emissionRemainder = emissionRemainder % 1;

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

  BreathWave addRipple(float energy) {
    if (ripples.size() >= MAX_RIPPLES) ripples.remove(0);
    BreathWave wave = new BreathWave(energy);
    ripples.add(wave);
    return wave;
  }
}

class BreathParticle {
  float x, y, drift, life, initialLife, diameter, seed;
  BreathParticle(float energy) {
    x = random(width * 0.16, width * 0.87);
    y = random(height * 0.715, height * 0.76);
    initialLife = life = random(1.8, 3.2);
    diameter = random(1.5, 4.0);
    drift = random(-9, 9); seed = random(1000);
  }
  void updateAndDraw(float energy, float dt) {
    life -= dt;
    seed += dt * 0.5;
    x += (drift + (noise(seed) - 0.5) * 22) * dt;
    y -= (12 + 95 * energy) * dt;
    int tint = lerpColor(color(118, 212, 225), color(255, 211, 157), energy);
    noStroke();
    fill(red(tint), green(tint), blue(tint), max(0, life / initialLife) * 195);
    circle(x, y, diameter + energy * 3.5);
  }
}

class BreathWave {
  float radius = 12, age = 0, duration = 2.3, strength;
  BreathWave(float energy) { strength = energy; }
  void updateAndDraw(float dt) {
    age += dt;
    radius += (55 + 150 * strength) * dt;
    noFill(); strokeWeight(0.8 + strength * 2.2);
    stroke(154 + strength * 85, 215, 225 - strength * 60,
           max(0, 1 - age / duration) * (100 + 140 * strength));
    ellipse(width * 0.55, height * 0.79, radius * 2.5, radius * 0.29);
    strokeWeight(1);
  }
}
