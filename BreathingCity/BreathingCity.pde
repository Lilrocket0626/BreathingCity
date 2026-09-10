// Breathing City
// Student: Jiangpeng Huang
// 52685 Creative Coding - Assessment 2
//
// Breathing City turns live microphone amplitude into a responsive night city.
// The project draws every visual element with code; it does not require image assets.
//
// Controls
// M     toggle microphone / mouse simulation mode
// R     recalibrate the microphone noise floor
// D     show or hide the data panel
// H     show or hide the help panel
// S     save a PNG screenshot

import processing.sound.*;

final int BUILDING_COUNT = 24;
final int STAR_COUNT = 70;
final int MAX_PARTICLES = 180;
final float BREATH_TRIGGER = 0.18;
final int WAVE_COOLDOWN_FRAMES = 42;

Building[] buildings = new Building[BUILDING_COUNT];
Star[] stars = new Star[STAR_COUNT];
ArrayList<BreathParticle> particles = new ArrayList<BreathParticle>();
ArrayList<BreathWave> waves = new ArrayList<BreathWave>();

BreathInput breathInput;
LevelGraph levelGraph;

boolean simulationMode = false;
boolean debugVisible = true;
boolean helpVisible = true;
float intensity = 0;
float previousIntensity = 0;
int lastWaveFrame = -WAVE_COOLDOWN_FRAMES;

void settings() {
  size(1280, 720);
}

void setup() {
  smooth(8);
  frameRate(60);
  surface.setTitle("Breathing City - Jiangpeng Huang");

  // A fixed seed produces the same city on every run, making tests repeatable.
  randomSeed(52685);
  noiseSeed(52685);
  createSkyline();
  createStars();

  breathInput = new BreathInput(this);
  breathInput.begin();
  levelGraph = new LevelGraph(220);
}

void draw() {
  // Mouse simulation is a deliberate fallback for computers that block microphone access.
  if (simulationMode) {
    intensity = lerp(intensity, constrain(map(mouseX, 0, width, 0, 1), 0, 1), 0.10);
  } else {
    intensity = breathInput.update();
  }

  levelGraph.add(intensity);
  triggerBreathWave();
  emitParticles();

  drawSkyGradient(intensity);
  drawStars(intensity);
  drawMoon(intensity);

  for (int i = 0; i < buildings.length; i++) {
    buildings[i].display(intensity);
  }

  drawHarbour(intensity);
  updateAndDrawWaves();
  updateAndDrawParticles();
  drawInterface();

  previousIntensity = intensity;
}

void createSkyline() {
  float x = -20;

  for (int i = 0; i < buildings.length; i++) {
    float buildingWidth = random(45, 85);
    float buildingHeight = random(120, 330);
    buildings[i] = new Building(x, height - 125, buildingWidth, buildingHeight, i);
    x += buildingWidth - 4;
  }
}

void createStars() {
  for (int i = 0; i < stars.length; i++) {
    stars[i] = new Star(random(width), random(height * 0.58), random(1, 3.2));
  }
}

// A rising-edge test creates one wave when the intensity crosses the threshold.
// The cooldown prevents a noisy signal from creating dozens of waves per second.
void triggerBreathWave() {
  boolean crossedThreshold = intensity >= BREATH_TRIGGER && previousIntensity < BREATH_TRIGGER;
  boolean cooldownFinished = frameCount - lastWaveFrame >= WAVE_COOLDOWN_FRAMES;

  if (crossedThreshold && cooldownFinished) {
    waves.add(new BreathWave(width * 0.5, height - 118, intensity));
    lastWaveFrame = frameCount;
  }
}

void emitParticles() {
  if (intensity < 0.035 || particles.size() >= MAX_PARTICLES) {
    return;
  }

  int particlesPerFrame = 1 + int(intensity * 5);
  for (int i = 0; i < particlesPerFrame && particles.size() < MAX_PARTICLES; i++) {
    float startX = random(width * 0.18, width * 0.82);
    float startY = random(height - 138, height - 110);
    particles.add(new BreathParticle(startX, startY, intensity));
  }
}

void updateAndDrawParticles() {
  // Iterate backwards so removing an expired particle does not skip the next item.
  for (int i = particles.size() - 1; i >= 0; i--) {
    BreathParticle particle = particles.get(i);
    particle.update(intensity);
    particle.display(intensity);

    if (particle.isFinished()) {
      particles.remove(i);
    }
  }
}

void updateAndDrawWaves() {
  for (int i = waves.size() - 1; i >= 0; i--) {
    BreathWave wave = waves.get(i);
    wave.update();
    wave.display();

    if (wave.isFinished()) {
      waves.remove(i);
    }
  }
}

// The sky warms as breath intensity increases.
void drawSkyGradient(float energy) {
  int calmTop = color(7, 14, 42);
  int calmBottom = color(27, 60, 88);
  int activeTop = color(34, 20, 65);
  int activeBottom = color(175, 83, 78);

  int topColour = lerpColor(calmTop, activeTop, energy);
  int bottomColour = lerpColor(calmBottom, activeBottom, energy);

  for (int y = 0; y < height; y += 2) {
    float position = map(y, 0, height, 0, 1);
    stroke(lerpColor(topColour, bottomColour, position));
    line(0, y, width, y);
    line(0, y + 1, width, y + 1);
  }
}

void drawStars(float energy) {
  for (int i = 0; i < stars.length; i++) {
    stars[i].display(energy);
  }
}

void drawMoon(float energy) {
  float pulse = 1 + energy * 0.30;
  noStroke();
  fill(165, 224, 242, 22 + energy * 36);
  circle(width * 0.80, height * 0.18, 118 * pulse);
  fill(232, 245, 255, 220);
  circle(width * 0.80, height * 0.18, 70 * pulse);
}

void drawHarbour(float energy) {
  noStroke();
  fill(5, 17, 36, 230);
  rect(0, height - 125, width, 125);

  float waveAmplitude = 2 + energy * 14;
  for (int row = 0; row < 8; row++) {
    int waterColour = lerpColor(color(74, 152, 186, 70), color(255, 152, 114, 135), energy);
    stroke(waterColour);
    noFill();
    beginShape();
    for (int x = 0; x <= width; x += 12) {
      float y = height - 112 + row * 14;
      float wave = sin(x * 0.025 + frameCount * 0.025 + row) * waveAmplitude;
      vertex(x, y + wave);
    }
    endShape();
  }
}

void drawInterface() {
  drawTitleAndStatus();

  if (debugVisible) {
    drawDebugPanel();
  }

  if (helpVisible) {
    drawHelpPanel();
  }
}

void drawTitleAndStatus() {
  fill(238, 248, 255, 230);
  textAlign(LEFT, TOP);
  textSize(28);
  text("BREATHING CITY", 34, 28);

  textSize(13);
  fill(185, 216, 229, 210);

  if (simulationMode) {
    text("SIMULATION MODE  •  move the mouse horizontally", 36, 66);
  } else if (!breathInput.available) {
    fill(255, 179, 145);
    text("MICROPHONE UNAVAILABLE  •  press M for simulation mode", 36, 66);
  } else if (breathInput.calibrating) {
    fill(255, 215, 126);
    text("CALIBRATING  •  stay quiet for " + nf(breathInput.secondsRemaining(), 1, 1) + " seconds", 36, 66);
  } else if (intensity < 0.08) {
    text("CALM  •  breathe towards the microphone", 36, 66);
  } else {
    fill(255, 211, 155);
    text("BREATH DETECTED  •  intensity " + nf(intensity, 1, 2), 36, 66);
  }
}

void drawDebugPanel() {
  float panelX = 34;
  float panelY = 104;
  float panelW = 280;
  float panelH = 128;

  noStroke();
  fill(5, 15, 34, 185);
  rect(panelX, panelY, panelW, panelH, 12);

  fill(205, 229, 239);
  textSize(11);
  textAlign(LEFT, TOP);
  text("LIVE DATA", panelX + 14, panelY + 12);
  text("raw amplitude     " + nf(breathInput.rawLevel, 1, 4), panelX + 14, panelY + 34);
  text("noise floor       " + nf(breathInput.noiseFloor, 1, 4), panelX + 14, panelY + 52);
  text("mapped intensity  " + nf(intensity, 1, 3), panelX + 14, panelY + 70);
  text("particles         " + particles.size(), panelX + 14, panelY + 88);

  levelGraph.display(panelX + 139, panelY + 31, 126, 72, intensity);
}

void drawHelpPanel() {
  String controls = "M  mic/simulation   R  recalibrate   D  data   H  help   S  screenshot";
  textSize(11);
  textAlign(RIGHT, BOTTOM);
  float textWidthValue = textWidth(controls);

  noStroke();
  fill(5, 15, 34, 168);
  rect(width - textWidthValue - 48, height - 51, textWidthValue + 28, 29, 8);
  fill(205, 229, 239, 215);
  text(controls, width - 34, height - 31);
}

void keyPressed() {
  if (key == 'm' || key == 'M') {
    simulationMode = !simulationMode;
    intensity = 0;
    previousIntensity = 0;
  }

  if (key == 'r' || key == 'R') {
    breathInput.startCalibration();
    simulationMode = false;
  }

  if (key == 'd' || key == 'D') {
    debugVisible = !debugVisible;
  }

  if (key == 'h' || key == 'H') {
    helpVisible = !helpVisible;
  }

  if (key == 's' || key == 'S') {
    saveFrame("BreathingCity-####.png");
  }
}

class BreathInput {
  PApplet parent;
  AudioIn microphone;
  Amplitude amplitudeAnalyzer;

  boolean available = false;
  boolean calibrating = false;
  float rawLevel = 0;
  float noiseFloor = 0.004;
  float smoothedIntensity = 0;

  float calibrationTotal = 0;
  int calibrationSamples = 0;
  int calibrationStartedAt = 0;
  final int CALIBRATION_DURATION_MS = 3000;

  BreathInput(PApplet sketch) {
    parent = sketch;
  }

  void begin() {
    try {
      microphone = new AudioIn(parent, 0);
      amplitudeAnalyzer = new Amplitude(parent);
      microphone.start();
      amplitudeAnalyzer.input(microphone);
      available = true;
      startCalibration();
    }
    catch (RuntimeException error) {
      available = false;
      calibrating = false;
      println("Microphone could not start: " + error.getMessage());
      println("Press M to use mouse simulation mode.");
    }
  }

  void startCalibration() {
    if (!available) {
      return;
    }

    calibrationTotal = 0;
    calibrationSamples = 0;
    calibrationStartedAt = millis();
    calibrating = true;
    smoothedIntensity = 0;
  }

  float update() {
    if (!available) {
      rawLevel = 0;
      return 0;
    }

    rawLevel = amplitudeAnalyzer.analyze();

    if (calibrating) {
      calibrationTotal += rawLevel;
      calibrationSamples++;

      if (millis() - calibrationStartedAt >= CALIBRATION_DURATION_MS) {
        // The multiplier places the threshold slightly above average room noise.
        noiseFloor = max(0.0015, (calibrationTotal / max(1, calibrationSamples)) * 1.35);
        calibrating = false;
      }
      return 0;
    }

    float signalAboveRoomNoise = max(0, rawLevel - noiseFloor);
    float strongBreathLevel = max(0.025, noiseFloor * 7.5);
    float mapped = constrain(map(signalAboveRoomNoise, 0, strongBreathLevel, 0, 1), 0, 1);

    // Attack is quick; release is slow. This avoids nervous flicker after each breath.
    float smoothingRate = mapped > smoothedIntensity ? 0.24 : 0.065;
    smoothedIntensity = lerp(smoothedIntensity, mapped, smoothingRate);

    if (smoothedIntensity < 0.006) {
      smoothedIntensity = 0;
    }

    return smoothedIntensity;
  }

  float secondsRemaining() {
    float remaining = CALIBRATION_DURATION_MS - (millis() - calibrationStartedAt);
    return max(0, remaining / 1000.0);
  }
}

class Building {
  float x;
  float groundY;
  float w;
  float h;
  int columns;
  int rows;
  int buildingIndex;

  Building(float startX, float bottomY, float buildingWidth, float buildingHeight, int index) {
    x = startX;
    groundY = bottomY;
    w = buildingWidth;
    h = buildingHeight;
    buildingIndex = index;
    columns = max(2, int(w / 17));
    rows = max(3, int(h / 24));
  }

  void display(float energy) {
    int calmBuilding = color(8, 19, 40);
    int activeBuilding = color(32, 28, 57);
    noStroke();
    fill(lerpColor(calmBuilding, activeBuilding, energy));
    rect(x, groundY - h, w, h);

    float gapX = w / (columns + 1);
    float gapY = h / (rows + 1);

    for (int row = 1; row <= rows; row++) {
      for (int column = 1; column <= columns; column++) {
        float windowX = x + column * gapX - 3;
        float windowY = groundY - h + row * gapY - 4;
        float windowPattern = noise(column * 0.71, row * 0.61, buildingIndex * 0.44);

        int calmWindow = color(66, 108, 130, 85);
        int activeWindow = color(255, 199, 105, 245);
        float localEnergy = constrain(energy + map(windowPattern, 0, 1, -0.25, 0.25), 0, 1);
        fill(lerpColor(calmWindow, activeWindow, localEnergy));
        rect(windowX, windowY, 6, 8, 1);
      }
    }
  }
}

class Star {
  float x;
  float y;
  float diameter;

  Star(float startX, float startY, float starDiameter) {
    x = startX;
    y = startY;
    diameter = starDiameter;
  }

  void display(float energy) {
    float alpha = map(energy, 0, 1, 115, 35);
    noStroke();
    fill(220, 242, 255, alpha);
    circle(x, y, diameter);
  }
}

class BreathParticle {
  PVector position;
  PVector velocity;
  float life;
  float size;
  float noiseOffset;
  int baseColour;

  BreathParticle(float startX, float startY, float birthEnergy) {
    position = new PVector(startX, startY);
    velocity = new PVector(random(-0.35, 0.35), random(-1.1, -0.35) - birthEnergy * 2.2);
    life = random(150, 230);
    size = random(2.5, 7.5);
    noiseOffset = random(1000);
    baseColour = lerpColor(color(113, 210, 230), color(255, 175, 119), birthEnergy);
  }

  void update(float energy) {
    float sidewaysDrift = map(noise(noiseOffset), 0, 1, -0.035, 0.035);
    velocity.x += sidewaysDrift;
    velocity.y -= 0.002 + energy * 0.009;
    velocity.limit(1.8 + energy * 4.5);
    position.add(velocity);
    noiseOffset += 0.012;
    life -= 1.3 + energy * 0.5;
  }

  void display(float energy) {
    noStroke();
    float alpha = constrain(life, 0, 210);
    int liveColour = lerpColor(baseColour, color(255, 224, 177), energy);
    fill(red(liveColour), green(liveColour), blue(liveColour), alpha);
    circle(position.x, position.y, size + energy * 4);
  }

  boolean isFinished() {
    return life <= 0 || position.y < -20 || position.x < -20 || position.x > width + 20;
  }
}

class BreathWave {
  float x;
  float y;
  float radius;
  float alpha;
  float strength;

  BreathWave(float centreX, float centreY, float breathStrength) {
    x = centreX;
    y = centreY;
    radius = 30;
    alpha = 220;
    strength = breathStrength;
  }

  void update() {
    radius += 4 + strength * 7;
    alpha -= 3.0;
  }

  void display() {
    noFill();
    strokeWeight(1.5 + strength * 2.5);
    stroke(151, 225, 239, alpha);
    ellipse(x, y, radius * 2.3, radius * 0.42);
    strokeWeight(1);
  }

  boolean isFinished() {
    return alpha <= 0;
  }
}

class LevelGraph {
  float[] history;
  int nextIndex = 0;

  LevelGraph(int sampleCount) {
    history = new float[sampleCount];
  }

  void add(float value) {
    history[nextIndex] = value;
    nextIndex = (nextIndex + 1) % history.length;
  }

  void display(float x, float y, float w, float h, float currentValue) {
    noFill();
    stroke(101, 151, 174, 90);
    rect(x, y, w, h, 4);

    float thresholdY = y + h - BREATH_TRIGGER * h;
    stroke(255, 198, 119, 90);
    line(x, thresholdY, x + w, thresholdY);

    stroke(119, 219, 230, 220);
    beginShape();
    for (int i = 0; i < history.length; i++) {
      int historyIndex = (nextIndex + i) % history.length;
      float graphX = map(i, 0, history.length - 1, x, x + w);
      float graphY = y + h - history[historyIndex] * h;
      vertex(graphX, graphY);
    }
    endShape();

    noStroke();
    fill(255, 198, 119, 210);
    circle(x + w, y + h - currentValue * h, 5);
  }
}
