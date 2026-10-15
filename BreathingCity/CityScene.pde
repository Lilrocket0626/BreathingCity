/**
 * Draws the permanent Sydney Harbour scene: sky, moon, stars, skyline, bridge,
 * Opera House, harbour and foreshore. No photograph, texture or external font
 * is loaded; every shape is generated with Processing drawing commands.
 *
 * Coordinates use a fixed 1280 x 720 design space. display() scales that design
 * to the current window, which keeps the composition proportional.
 */
class CityScene {
  /** Y coordinate separating the skyline from the harbour in design space. */
  final float SHORE = 518.4f; // 0.72 * 720; particles and ripples sit in front.

  /** Reusable building objects containing fixed window activation patterns. */
  CityBuilding[] buildings;

  /** Reusable stars with fixed positions and individual twinkle phases. */
  CityStar[] stars;

  /** Integrated phase shared by water waves and reflections. */
  float wavePhase = 0;

  /** Total scene time in seconds, used for slow star animation. */
  float sceneTime = 0;

  /** Pre-generates a repeatable skyline and star field once at startup. */
  CityScene() {
    // A private generator keeps the composition repeatable without changing
    // the random sequence used by the interactive particle system.
    java.util.Random rng = new java.util.Random(52685);
    stars = new CityStar[88];
    for (int i = 0; i < stars.length; i++) {
      // seed is stored by each star to vary size, opacity and twinkle phase.
      stars[i] = new CityStar(rng.nextFloat() * 1280,
        35 + rng.nextFloat() * 290, rng.nextFloat());
    }

    // The first building group forms the wider distant skyline.
    buildings = new CityBuilding[32];
    float x = -15;
    for (int i = 0; i < 21; i++) {
      float w = 29 + rng.nextFloat() * 25;
      float h = 52 + rng.nextFloat() * 115;
      // The CBD rises behind the bridge's right approach.
      if (x > 540 && x < 770) h += 30;
      buildings[i] = new CityBuilding(x, SHORE, w, h, true, rng);
      x += w - 4;
    }

    // The second group overlaps the first to add depth behind the bridge.
    x = 310;
    for (int i = 21; i < buildings.length; i++) {
      float w = 30 + rng.nextFloat() * 20;
      float h = 70 + rng.nextFloat() * 150;
      buildings[i] = new CityBuilding(x, SHORE, w, h, false, rng);
      x += w + 3;
    }
  }

  /** Restarts time-based scene animation without regenerating the composition. */
  void reset() {
    wavePhase = 0;
    sceneTime = 0;
  }

  // Energy is the already calibrated, gated and smoothed 0..1 audio signal.
  // Integrating speed over dt avoids phase jumps when the input changes and
  // keeps motion independent of rendering frame rate.
  /**
   * Draws one complete frame from back to front.
   *
   * @param energy stable control signal: 0 is calm and 1 is fully active
   * @param dt elapsed frame time in seconds
   */
  void display(float energy, float dt) {
    // Defensive clamping keeps all colour and movement interpolation valid.
    energy = constrain(energy, 0, 1);
    sceneTime += dt;

    // lerp selects wave speed between 0.35 and 1.65 radians per second.
    wavePhase = (wavePhase + dt * lerp(0.35f, 1.65f, energy)) % TWO_PI;

    // Save and restore Processing transform/style state so this class does not
    // accidentally change the interface or particle rendering that follows.
    pushMatrix();
    pushStyle();
    scale(width / 1280.0f, height / 720.0f);
    rectMode(CORNER);
    ellipseMode(CENTER);
    drawSky(energy);
    for (CityStar star : stars) star.display(energy, sceneTime);
    drawMoon(energy);
    for (CityBuilding building : buildings) building.display(energy);
    drawHarbour(energy);
    drawBridge(energy);
    drawOperaHouse(energy);
    drawForeshore(energy);
    popStyle();
    popMatrix();
  }

  /** Blends a cool calm gradient toward a warmer active night sky. */
  void drawSky(float energy) {
    int top = lerpColor(color(6, 13, 29), color(26, 20, 56), energy);
    int horizon = lerpColor(color(25, 55, 71), color(153, 91, 99), energy);
    strokeWeight(2);

    // Horizontal two-pixel lines form a lightweight vertical colour gradient.
    for (int y = 0; y <= 520; y += 2) {
      float t = y / 520.0f;
      // t squared holds the darker top colour for longer before the horizon.
      stroke(lerpColor(top, horizon, t * t));
      line(0, y, 1280, y);
    }
    // Low, translucent haze makes the distant shoreline recede.
    noStroke();
    for (int i = 7; i >= 1; i--) {
      fill(152, 127, 120, 2 + energy * 2);
      ellipse(710, SHORE, 1500, 26 + i * 17);
    }
  }

  /** Draws a crescent moon plus a soft glow that strengthens slightly with energy. */
  void drawMoon(float energy) {
    noStroke();

    // Several large transparent circles create the glow without image assets.
    for (int i = 10; i > 0; i--) {
      fill(240, 220, 181, 2 + energy);
      ellipse(1078, 137, 39 + i * 10, 39 + i * 10);
    }

    // Draw a bright disc, then cover an offset portion with the matching sky
    // colour. The remaining visible section becomes the crescent.
    fill(235, 227, 199, 220);
    ellipse(1078, 137, 43, 43);
    int top = lerpColor(color(6, 13, 29), color(26, 20, 56), energy);
    int horizon = lerpColor(color(25, 55, 71), color(153, 91, 99), energy);
    fill(lerpColor(top, horizon, sq(128.0f / 520)));
    ellipse(1088, 128, 39, 39);
  }

  /** Draws the water gradient, light reflections and moving wave lines. */
  void drawHarbour(float energy) {
    int near = lerpColor(color(5, 20, 31), color(15, 31, 48), energy);
    int far = lerpColor(color(15, 42, 54), color(76, 64, 76), energy);
    strokeWeight(2);

    // Darken colour from the distant shoreline toward the lower foreground.
    for (int y = int(SHORE); y < 722; y += 2) {
      stroke(lerpColor(far, near, (y - SHORE) / (720 - SHORE)));
      line(0, y, 1280, y);
    }

    // Broken vertical reflections follow the same integrated water phase.
    // Both the number of strips and their lifespan are fixed: no accumulation.
    noStroke();
    for (int source = 0; source < 21; source++) {
      float originX = 105 + source * 52;
      for (int strip = 0; strip < 23; strip++) {
        float depth = strip / 22.0f;
        float y = SHORE + 4 + depth * 184;

        // Deeper strips drift farther and become longer, suggesting perspective.
        float drift = sin(wavePhase * 2 + source + strip * 0.8f) * (2 + depth * 10);
        float length = (4 + depth * 22) * (0.6f + energy * 0.8f);
        float brightness = (1 - depth) * (10 + energy * 42);
        if (source > 13) fill(226, 206, 159, brightness);
        else fill(235, 171, 109, brightness * 0.65f);
        rect(originX + drift - length / 2, y, length, 1 + depth);
      }
    }

    // Perspective spacing and amplitude make foreground waves broader.
    // Calm -> active: speed 0.35 -> 1.65 rad/s; amplitude 0.65 -> 5.15 px,
    // multiplied by depth. Input affects both motion and shape.
    noFill();
    strokeWeight(1);
    for (int row = 0; row < 18; row++) {
      float depth = row / 17.0f;
      float y = SHORE + 5 + pow(depth, 1.4f) * 204;
      float amplitude = (0.65f + energy * 4.5f) * (0.2f + depth);
      stroke(115 + energy * 35, 169, 180, 17 + depth * 20 + energy * 20);
      beginShape();
      for (int x = -8; x <= 1290; x += 12) {
        // Combining two sine waves avoids a perfectly regular mechanical pattern.
        float displacement = sin(x * 0.018f + wavePhase + row * 1.23f) * amplitude;
        displacement += sin(x * 0.037f - wavePhase * 2 + row) * amplitude * 0.3f;
        vertex(x, y + displacement);
      }
      endShape();
    }
  }

  // A deck, stone pylons, arch ribs, vertical hangers and cross-bracing provide
  // the Harbour Bridge's distinctive silhouette rather than a generic bridge.
  /** Draws the Harbour Bridge and brightens its structure and lights with energy. */
  void drawBridge(float energy) {
    // These design-space anchors control the span and road-deck height.
    float left = 168, right = 760, deck = 472;
    noStroke();
    fill(16, 28, 38);

    // Road deck and approach supports.
    rect(0, deck - 3, 807, 13);
    for (int i = 0; i < 6; i++) rect(20 + i * 29, deck, 6, 44);

    // Two related arch ribs create the bridge's heavy steel silhouette.
    stroke(79 + energy * 66, 91 + energy * 51, 91 + energy * 40);
    strokeWeight(5);
    noFill();
    for (int rib = 0; rib < 2; rib++) {
      beginShape();
      for (int i = 0; i <= 64; i++) {
        float t = i / 64.0f;
        vertex(lerp(left, right, t), bridgeArchY(t) + rib * 13);
      }
      endShape();
    }

    // Vertical hangers and diagonal lines visually connect arch and deck.
    strokeWeight(1.3f);
    for (int i = 1; i < 25; i++) {
      float t = i / 25.0f;
      float x = lerp(left, right, t);
      float y = bridgeArchY(t);
      line(x, y + 13, x, deck);
      float nextT = (i + 1) / 25.0f;
      line(x, y, lerp(left, right, nextT), bridgeArchY(nextT) + 13);
    }
    stroke(85 + energy * 94, 102 + energy * 71, 105 + energy * 46);
    strokeWeight(1);
    line(0, deck - 3, 805, deck - 3);

    // Fine deck marks and lamps become more visible as the input strengthens.
    for (int i = 0; i < 64; i++) line(i * 13, deck - 9, i * 13, deck - 3);
    drawPylon(left - 12, energy);
    drawPylon(right - 10, energy);
    noStroke();
    for (int i = 0; i < 48; i++) {
      float x = i * 17;
      fill(255, 202, 126, 38 + energy * 122);
      ellipse(x, deck - 2, 2.5f, 2.5f);
    }
  }

  /**
   * Returns the Y coordinate of a parabolic bridge arch.
   * t moves from 0 at the left anchor to 1 at the right anchor.
   */
  float bridgeArchY(float t) {
    return 466 - 166 * (1 - sq(2 * t - 1));
  }

  /** Draws one layered stone pylon, with colour responding to energy. */
  void drawPylon(float x, float energy) {
    noStroke();
    fill(lerpColor(color(42, 47, 46), color(123, 104, 82), energy));
    rect(x, 411, 27, 103);
    fill(lerpColor(color(62, 62, 54), color(166, 143, 108), energy));
    rect(x + 4, 416, 9, 95);
    fill(36 + energy * 50, 41 + energy * 40, 41 + energy * 26);
    rect(x - 3, 408, 33, 8);
    rect(x + 1, 400, 25, 9);
    fill(13, 27, 36);
    rect(x + 16, 427, 5, 12);
  }

  /** Draws the Opera House podium, glazing, overlapping shells and seams. */
  void drawOperaHouse(float energy) {
    noStroke();
    // Warm podium and dark glass anchor the luminous concrete sail roofs.
    fill(63 + energy * 69, 62 + energy * 48, 57 + energy * 29);
    quad(800, 500, 1193, 500, 1216, 518, 789, 518);
    fill(18, 38, 44);
    rect(821, 473, 359, 30);

    // Rear roofs first, then overlapping foreground shells.
    // shade changes each shell's base brightness to create depth.
    drawShell(876, 1016, 941, 354, 492, energy, 0.67f);
    drawShell(975, 1127, 1034, 381, 496, energy, 0.75f);
    drawShell(807, 916, 854, 422, 499, energy, 0.86f);
    drawShell(847, 999, 908, 381, 501, energy, 1.0f);
    drawShell(951, 1101, 1018, 413, 503, energy, 0.94f);
    drawShell(1060, 1190, 1121, 430, 502, energy, 1.0f);
    stroke(209, 184, 134, 48 + energy * 108);
    strokeWeight(1);
    for (int i = 0; i < 5; i++) line(803 - i * 3, 504 + i * 3, 1197 + i * 3, 504 + i * 3);
  }

  // An asymmetric curved shell plus radial seams suggests the tiled vaults.
  // The silhouette is hand-authored geometry, not traced from a source image.
  /**
   * Draws one Opera House shell from two base points and one roof tip.
   * energy blends cool concrete toward warm illuminated concrete; shade makes
   * rear shells darker than foreground shells.
   */
  void drawShell(float x1, float x2, float tipX, float tipY,
                 float baseY, float energy, float shade) {
    int calm = color(95 * shade, 122 * shade, 132 * shade);
    int active = color(248 * shade, 222 * shade, 175 * shade);

    // Two cubic Bezier curves form the asymmetric outer shell silhouette.
    fill(lerpColor(calm, active, 0.16f + energy * 0.84f));
    stroke(197, 208, 196, 60 + energy * 70);
    strokeWeight(1);
    beginShape();
    vertex(x1, baseY);
    bezierVertex(x1 + 4, baseY - 23, tipX - 13, tipY + 35, tipX, tipY);
    bezierVertex(tipX + 6, tipY + 47, x2 - 26, baseY - 39, x2, baseY);
    endShape(CLOSE);

    // A transparent inner wedge suggests shadow and curvature.
    noStroke();
    fill(15, 35, 45, 60);
    beginShape();
    vertex(tipX, tipY + 3);
    bezierVertex(tipX + 5, tipY + 47, x2 - 24, baseY - 39, x2, baseY);
    vertex(lerp(x1, x2, 0.56f), baseY);
    endShape(CLOSE);

    // Fine Bezier seams suggest the roof's tiled rib structure.
    noFill();
    stroke(225, 227, 209, 24 + energy * 34);
    strokeWeight(0.8f);
    for (int i = 1; i < 7; i++) {
      float endX = lerp(x1 + 8, x2 - 8, i / 7.0f);
      bezier(tipX, tipY + 5, tipX, tipY + 40, endX - 8, baseY - 25, endX, baseY - 2);
    }
  }

  /** Draws the foreground shoreline and its small energy-responsive lights. */
  void drawForeshore(float energy) {
    stroke(20, 31, 37);
    strokeWeight(4);
    line(0, SHORE, 802, SHORE);
    noStroke();
    for (int i = 0; i < 35; i++) {
      float x = i * 22;
      fill(255, 202, 135, 35 + energy * 128);
      ellipse(x, SHORE - 1, 2, 2);
    }
  }
}

/**
 * One rectangular skyline building with a repeatable grid of windows.
 * Each window receives a fixed activation threshold during construction, so
 * patterns remain stable instead of flickering randomly on every frame.
 */
class CityBuilding {
  /** Building bounds in the 1280 x 720 design coordinate system. */
  float x, baseY, w, h;

  /** Distant buildings are drawn lighter and with dimmer windows for depth. */
  boolean distant;

  /** Number of window columns and rows that fit within this building. */
  int cols, rows;

  float[] windowLevels; // Fixed thresholds preserve window patterns across frames.

  /** A small group of windows remains lit even when the scene is calm. */
  boolean[] alwaysLit;

  /** Creates building geometry and precomputes all fixed window behaviour. */
  CityBuilding(float x, float baseY, float w, float h,
               boolean distant, java.util.Random rng) {
    this.x = x; this.baseY = baseY; this.w = w; this.h = h;
    this.distant = distant;

    // Derive grid size from building dimensions while always keeping one cell.
    cols = max(1, int((w - 8) / 9));
    rows = max(1, int((h - 10) / 13));
    windowLevels = new float[cols * rows];
    alwaysLit = new boolean[cols * rows];
    for (int i = 0; i < windowLevels.length; i++) {
      // Windows switch on progressively at different energy levels.
      windowLevels[i] = 0.12f + rng.nextFloat() * 0.82f;
      // About 23 percent provide a believable base level of city light.
      alwaysLit[i] = rng.nextFloat() < 0.23f;
    }
  }

  /** Draws the building body and maps current energy to window brightness. */
  void display(float energy) {
    noStroke();

    // Separate tones place distant and foreground buildings on different layers.
    if (distant) fill(22, 38, 48);
    else fill(12, 27, 38);
    rect(x, baseY - h, w, h);
    fill(52, 67, 71, 105);
    rect(x, baseY - h, w, 2);
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        int index = row * cols + col;

        // Subtract each window's threshold and multiply by 3.5 to create a short,
        // smooth transition rather than a binary on/off switch.
        float activation = constrain((energy - windowLevels[index]) * 3.5f, 0, 1);
        float alpha = (alwaysLit[index] ? 40 + energy * 155 : activation * 170);
        if (distant) alpha *= 0.55f;

        // Periodic cool windows break up the dominant warm-light pattern.
        if (index % 5 == 0) fill(149, 198, 207, alpha);
        else fill(252, 205, 129, alpha);
        rect(x + 5 + col * 9, baseY - h + 8 + row * 13, 3, 5);
      }
    }
  }
}

/** One code-generated star with a fixed position, brightness and twinkle phase. */
class CityStar {
  float x, y, seed;

  /** Stores immutable star characteristics created by CityScene's seeded RNG. */
  CityStar(float x, float y, float seed) {
    this.x = x; this.y = y; this.seed = seed;
  }

  /** Draws a subtle slow twinkle while allowing energy to increase brightness. */
  void display(float energy, float time) {
    // Individual phase offsets stop all stars from pulsing together.
    float twinkle = 0.85f + 0.15f * sin(time * 0.55f + seed * TWO_PI);
    noStroke();
    fill(208, 220, 224, (48 + seed * 83 + energy * 48) * twinkle);
    float size = 1 + seed * 1.4f;
    ellipse(x, y, size, size);
  }
}
