/**
 * Breathing City 2.0
 *
 * Main Processing sketch and program coordinator. It selects one of three input
 * modes, converts that input into a 0..1 intensity value, passes the value to
 * the city and effects renderers, draws the interface, and optionally records
 * numerical test evidence.
 *
 * Open THIS file in Processing Java mode with the official Sound 2.4.0 library.
 * Important limitation: microphone mode measures loudness, not breath identity,
 * so speech, music and other sufficiently loud sounds can also activate it.
 * Revision and documentation are AI-assisted; see docs/genai-declaration.md.
 */
import processing.sound.*;
import java.io.File;
import java.io.PrintWriter;

/** Version displayed in the window title and written into evidence reports. */
final String PROJECT_VERSION = "2.0";

/** Integer constants identify the three mutually exclusive input modes. */
final int MICROPHONE = 0, MOUSE = 1, DEMO = 2;

// Main components. Each class has one clear responsibility.
/** Opens the microphone and converts RMS amplitude into stable intensity. */
BreathInput input;

/** Draws the permanent Sydney Harbour background and audio-reactive scene. */
CityScene city;

/** Draws short-lived particles and water ripples. */
VisualEffects effects;

/** Stores recent intensity values for the diagnostic history graph. */
LevelGraph graph;

/** Currently selected source; the sketch starts by requesting microphone mode. */
int mode = MICROPHONE;

/** User-interface visibility flags toggled by D and H. */
boolean debugVisible = true, helpVisible = true;

/** True while the prompted 60-second live microphone trial is active. */
boolean guidedTest = false;

/** Global elapsed time at which the current guided trial began. */
float guidedStarted = 0;

/**
 * intensity: current 0..1 value shared by every visual system.
 * elapsed: total runtime in seconds.
 * demoTime: position within the repeating 24-second synthetic demonstration.
 */
float intensity = 0, elapsed = 0, demoTime = 0;

/** High-resolution timestamp of the previous frame, used to calculate dt. */
long lastNanos;

/** Short user feedback message and the time at which it should disappear. */
String notice = "";
float noticeUntil = 0;

// Optional, documented developer capture controls. Normal users need no env vars.
/** Directory selected by BC_RUN_DIR; null disables all evidence-file writing. */
String runDirectory;

/** True when BC_CAPTURE_FRAMES=1 requests one image per rendered demo frame. */
boolean captureFrames;

/** Optional automatic stop time read from BC_DURATION, measured in seconds. */
float durationLimit;

/** CSV writer for 4-Hz numerical telemetry; never contains microphone audio. */
PrintWriter telemetry;

/** Counters used to name frames, schedule telemetry and record peak object counts. */
int captureIndex = 0, nextTelemetry = 0, maxParticlesSeen = 0, maxRipplesSeen = 0;

/** Accumulators used to report mean and minimum FPS after startup warm-up. */
float fpsSum = 0, minFps = Float.MAX_VALUE;
int fpsSamples = 0;

/** Guard ensuring the final report is written and closed only once. */
boolean finishedRun = false;

/** Configures window properties before Processing creates the drawing surface. */
void settings() {
  size(1280, 720);
  pixelDensity(1); // Consistent screenshot size on Retina and ordinary displays.
  smooth(4);
}

/** Creates program components, optional evidence writers and the initial mode. */
void setup() {
  surface.setTitle("Breathing City | Sydney Harbour | v" + PROJECT_VERSION);
  frameRate(60);
  textFont(createFont("SansSerif", 16)); // Java logical font; no font asset needed.

  // Fixed seeds make the artwork reproducible between runs while it still looks organic.
  randomSeed(52685); noiseSeed(52685);

  // Construct long-lived objects once rather than allocating them every frame.
  input = new BreathInput(this);
  city = new CityScene(); effects = new VisualEffects(); graph = new LevelGraph(240);

  // Environment variables are optional and mainly support repeatable testing.
  runDirectory = System.getenv("BC_RUN_DIR");
  captureFrames = "1".equals(System.getenv("BC_CAPTURE_FRAMES"));
  durationLimit = positiveEnvironmentNumber("BC_DURATION", 0);
  if (runDirectory != null && runDirectory.length() > 0) {
    new File(runDirectory).mkdirs();
    telemetry = createWriter(runDirectory + "/telemetry.csv");
    telemetry.println("seconds,mode,raw_rms,noise_floor,opening_threshold,sensitivity,target,intensity,particles,ripples,fps,heap_used_mb,guided_phase");

    // A fixed 30 FPS clock makes captured demo frames exactly reproducible.
    if (captureFrames) { new File(runDirectory + "/frames").mkdirs(); frameRate(30); }
  }

  // Default to a real microphone unless BC_MODE explicitly requests a simulation.
  String requestedMode = System.getenv("BC_MODE");
  switchMode("demo".equals(requestedMode) ? DEMO : "mouse".equals(requestedMode) ? MOUSE : MICROPHONE);
  if ("1".equals(System.getenv("BC_GUIDED_TEST"))) startGuidedTest();

  // The first draw() call needs a baseline timestamp for its delta-time calculation.
  lastNanos = System.nanoTime();
}

/** Runs once per rendered frame and coordinates input, animation, UI and logging. */
void draw() {
  // Calculate real elapsed seconds instead of assuming that every frame is 1/60 s.
  long now = System.nanoTime();
  float realDt = (now - lastNanos) / 1000000000.0f;
  lastNanos = now;

  // Clamp pauses (window dragging, debugger) so one frame cannot launch a burst.
  float dt = constrain(realDt, 0.001, 0.1);

  // Captured frames use an explicit 30 FPS animation clock, not live mic timing.
  if (captureFrames && mode == DEMO) dt = 1.0 / 30.0;
  elapsed += dt;

  // Only this block differs by mode. Every branch produces the same 0..1 signal.
  if (mode == MICROPHONE) {
    intensity = input.update(dt);
  } else if (mode == MOUSE) {
    // Horizontal pointer position becomes a target intensity for testing visuals.
    intensity = SignalEnvelope.smooth(intensity, constrain(mouseX / float(width), 0, 1), dt);
  } else {
    // The automatic demo passes synthetic RMS through the real SignalEnvelope.
    demoTime += dt;
    if (demoTime >= 24) { demoTime -= 24; input.envelope.startCalibration(); }
    intensity = input.envelope.update(demoSample(demoTime), dt);
  }

  // Render back to front: scene first, temporary effects second, interface last.
  graph.add(intensity);
  city.display(intensity, dt);
  effects.updateAndDraw(intensity, dt);
  drawInterface();
  recordEvidence();

  // Automated test runs can stop cleanly at a requested duration.
  if (durationLimit > 0 && elapsed >= durationLimit) {
    finishEvidence(); input.stop(); exit();
  }
}

// Synthetic input is ONLY a reproducible visual / signal-processing demonstration.
// It exercises calibration, gentle input, strong input and release without audio.
/**
 * Generates a repeatable RMS-like signal for debugging without a microphone.
 * 0-6 s is room noise/calibration, 6-10 s is gentle input, 10-16 s is strong
 * input, and 16-24 s is recovery. Small sine terms prevent perfectly flat data.
 */
float demoSample(float t) {
  float room = 0.002 + 0.00015 * sin(t * 8);
  if (t < 6 || t >= 16) return room;
  if (t < 10) return room + 0.015 + 0.002 * sin(t * 4);
  return room + 0.074 + 0.009 * sin(t * 3);
}

/** Converts the integer mode constant into a clear interface/report label. */
String modeName() { return mode == MICROPHONE ? "MICROPHONE" : mode == MOUSE ? "MOUSE SIMULATION" : "AUTO DEMO / SYNTHETIC RMS"; }

/**
 * Chooses the highest-priority status message for the current program state.
 * Hardware problems and calibration are reported before calm/gentle/strong.
 */
String stageName() {
  if (mode == MICROPHONE && !input.available) return "INPUT UNAVAILABLE - I retry / M simulate";
  if (mode != MOUSE && input.envelope.calibrating) return "CALIBRATING - stay quiet  " + nf(input.envelope.calibrationRemaining(), 1, 1) + " s";
  if (mode == MICROPHONE && input.zeroSeconds > 5) return "NO SIGNAL - check permission / input device";
  if (mode == MICROPHONE && input.clippingSeconds > 0.2) return "INPUT CLIPPING - move back or reduce OS gain";
  if (intensity < 0.035) return "CALM / LISTENING";
  return intensity < 0.5 ? "GENTLE RESPONSE" : "STRONG RESPONSE";
}

/** Draws project title, current state, optional diagnostics, help and notices. */
void drawInterface() {
  // pushStyle/popStyle isolate UI colours, text alignment and stroke settings.
  pushStyle();
  noStroke(); fill(231, 236, 226); textAlign(LEFT, TOP);
  textSize(12); text("S Y D N E Y   H A R B O U R", 34, 24);
  textSize(31); text("Breathing City", 32, 43);
  textSize(11); fill(mode == MICROPHONE ? color(149, 215, 203) : color(245, 201, 128));
  text(modeName(), 35, 87);
  fill(207, 218, 222); text(stageName(), 35, 106);
  if (debugVisible) drawDebugPanel();
  if (guidedTest) drawGuidedTest();
  if (helpVisible) {
    // The translucent footer lists every available keyboard control.
    fill(3, 13, 25, 220); rect(22, height - 66, width - 44, 50, 8);
    fill(190, 210, 214); textSize(11);
    text("M mic / mouse    A auto demo    G guided test    R calibrate    I retry    N next input    D data    H help    S screenshot", 35, height - 56);
    text("[ / ] threshold margin    - / = sensitivity    0 reset tuning    |    Sound level control; speech and other sounds also respond.", 35, height - 36);
  }
  if (elapsed < noticeUntil) { fill(255, 208, 136); textSize(12); text(notice, 35, height - 88); }
  popStyle();
}

/** Draws live signal values, object counts, FPS, history and device name. */
void drawDebugPanel() {
  SignalEnvelope signal = input.envelope;
  noStroke(); fill(3, 13, 25, 208); rect(24, 133, 318, 178, 10);
  fill(175, 197, 205); textSize(11);
  String rawText = mode == MOUSE ? "not sampled" : nf(signal.raw, 1, 4);
  text("RMS  " + rawText + "     FLOOR  " + nf(signal.noiseFloor, 1, 4), 37, 147);
  text("OPEN  " + nf(signal.openingThreshold(), 1, 4) + "     GAIN  " + nf(signal.sensitivity, 1, 2), 37, 166);
  text("INTENSITY  " + nf(intensity, 1, 3) + "     FPS  " + nf(frameRate, 1, 0), 37, 185);
  text("PARTICLES  " + effects.particles.size() + "/180     RIPPLES  " + effects.ripples.size() + "/8", 37, 204);
  graph.display(37, 228, 290, 43);

  // Simulation labels prevent screenshots from being mistaken for microphone evidence.
  String device = mode == MICROPHONE ? input.deviceName : "Simulation - not microphone evidence";
  if (device.length() > 46) device = device.substring(0, 43) + "...";
  fill(151, 175, 184); text(device, 37, 284);
}

/**
 * Safely changes input source. Old audio/effect state is cleared so the next
 * mode cannot inherit an open stream, particles, graph history or intensity.
 */
void switchMode(int next) {
  input.stop(); mode = next; intensity = demoTime = 0; guidedTest = false;
  effects.reset(); graph.clear();
  if (mode == MICROPHONE) input.begin();
  if (mode == DEMO) input.envelope.startCalibration();
}

/** Maps keyboard controls to input selection, calibration, tuning and UI actions. */
void keyPressed() {
  // M toggles between the real microphone and direct mouse simulation.
  if (key == 'm' || key == 'M') switchMode(mode == MICROPHONE ? MOUSE : MICROPHONE);

  // A starts the repeatable automatic signal demonstration.
  else if (key == 'a' || key == 'A') switchMode(DEMO);

  // G starts a prompted, timed live-microphone test.
  else if (key == 'g' || key == 'G') startGuidedTest();

  // R learns a new room-noise baseline for whichever measured input is active.
  else if (key == 'r' || key == 'R') {
    if (mode == MICROPHONE && input.available) {
      guidedTest = false; // A new calibration invalidates an in-progress trial.
      input.envelope.startCalibration();
    }
    else if (mode == DEMO) { demoTime = 0; input.envelope.startCalibration(); }
    else showNotice("R calibrates an active mic. Press M to switch, or I to reconnect.");
  }

  // I retries the microphone after a permission or connection problem.
  else if (key == 'i' || key == 'I') switchMode(MICROPHONE);

  // N selects the next hardware input device, useful with USB microphones.
  else if (key == 'n' || key == 'N') {
    guidedTest = false; mode = MICROPHONE; intensity = 0;
    effects.reset(); graph.clear(); input.nextDevice();
  }

  // Brackets change the noise margin; minus/plus change response sensitivity.
  else if (key == '[') input.envelope.adjustMargin(-0.0005);
  else if (key == ']') input.envelope.adjustMargin(0.0005);
  else if (key == '-' || key == '_') input.envelope.adjustSensitivity(1.0 / 1.25);
  else if (key == '=' || key == '+') input.envelope.adjustSensitivity(1.25);

  // 0 restores the documented tuning defaults.
  else if (key == '0') { input.envelope.margin = 0.002; input.envelope.sensitivity = 1; }

  // D and H independently toggle the data panel and help footer.
  else if (key == 'd' || key == 'D') debugVisible = !debugVisible;
  else if (key == 'h' || key == 'H') helpVisible = !helpVisible;

  // S stores a timestamped still image inside the sketch's screenshots folder.
  else if (key == 's' || key == 'S') {
    String filename = "screenshots/BreathingCity-" + System.currentTimeMillis() + ".png";
    save(filename); showNotice("Saved " + filename);
  }
}

/** Displays a temporary four-second message without blocking the animation loop. */
void showNotice(String text) { notice = text; noticeUntil = elapsed + 4; }

// A reproducible, prompted HUMAN trial. Prompts identify requested actions;
// the participant must still confirm that they actually followed each prompt.
/** Starts the guided trial and forces a real, available microphone connection. */
void startGuidedTest() {
  if (mode != MICROPHONE || !input.available) switchMode(MICROPHONE);
  if (!input.available) { showNotice("A working microphone is required for G."); return; }

  // A fresh calibration and empty visuals give each trial the same starting state.
  guidedTest = true; guidedStarted = elapsed;
  input.envelope.startCalibration(); effects.reset(); graph.clear();
}

/** Returns the guided phase selected from seconds since the trial began. */
String guidedPhase() {
  if (!guidedTest) return "none";
  float t = elapsed - guidedStarted;

  // Durations: quiet 10 s, gentle 15 s, strong 15 s, recovery 15 s.
  return t < 10 ? "quiet" : t < 25 ? "gentle" : t < 40 ? "strong" : t < 55 ? "recovery" : "complete";
}

/** Draws the current participant instruction and a countdown for that phase. */
void drawGuidedTest() {
  float t = elapsed - guidedStarted;
  String phase = guidedPhase();

  // Prompt wording changes at the same boundaries used by guidedPhase().
  String prompt = phase.equals("quiet") ? "STAY QUIET / CALIBRATING" :
    phase.equals("gentle") ? "BREATHE GENTLY toward microphone" :
    phase.equals("strong") ? "BLOW MORE STRONGLY toward microphone" :
    phase.equals("recovery") ? "STOP / STAY QUIET" : "TEST COMPLETE - confirm observations";
  float phaseEnd = t < 10 ? 10 : t < 25 ? 25 : t < 40 ? 40 : t < 55 ? 55 : 60;

  // A dark panel keeps instructions readable over every sky colour.
  fill(3, 13, 25, 230); rect(365, 24, 625, 83, 10);
  fill(249, 217, 160); textAlign(LEFT, TOP); textSize(18);
  text(prompt, 383, 39);
  fill(194, 214, 217); textSize(13);
  text("LIVE MICROPHONE TEST  |  " + max(0, ceil(phaseEnd - t)) + " seconds in this stage", 384, 73);
  if (t >= 60) guidedTest = false;
}

/** Reads a non-negative float environment variable or returns a safe fallback. */
float positiveEnvironmentNumber(String name, float fallback) {
  try { return max(0, Float.parseFloat(System.getenv(name))); }
  catch (Exception ignored) { return fallback; }
}

// Evidence records numbers only, never microphone audio. Files are opt-in.
/**
 * Records optional reproducibility evidence when BC_RUN_DIR is configured.
 * This includes signal/visual metrics, selected screenshots and performance
 * information. Normal interactive use exits immediately because telemetry is null.
 */
void recordEvidence() {
  // Peak counts are tracked even without a CSV so the final report can summarise them.
  maxParticlesSeen = max(maxParticlesSeen, effects.particles.size());
  maxRipplesSeen = max(maxRipplesSeen, effects.ripples.size());

  // Ignore the first two seconds when measuring FPS because startup is atypical.
  if (elapsed > 2) { fpsSum += frameRate; fpsSamples++; minFps = min(minFps, frameRate); }
  if (telemetry == null) return;

  // Write one numerical row every 0.25 seconds (4 Hz), not on every frame.
  if (elapsed >= nextTelemetry * 0.25) {
    SignalEnvelope s = input.envelope;
    telemetry.println(String.format(java.util.Locale.US,
      "%.3f,%s,%.6f,%.6f,%.6f,%.3f,%.5f,%.5f,%d,%d,%.2f,%.2f,%s",
      elapsed, modeName(), s.raw, s.noiseFloor, s.openingThreshold(), s.sensitivity,
      s.target, intensity, effects.particles.size(), effects.ripples.size(), frameRate,
      (Runtime.getRuntime().totalMemory() - Runtime.getRuntime().freeMemory()) / 1048576.0,
      guidedPhase()));
    telemetry.flush(); nextTelemetry++;
  }

  // Full frame capture is opt-in because it uses significant storage.
  if (captureFrames) save(runDirectory + "/frames/" + nf(captureIndex++, 6) + ".png");

  // Save five representative moments once each for repeatable visual comparison.
  float[] moments = {1.5, 5, 8, 13, 21};
  String[] names = {"01-calibration", "02-calm", "03-gentle", "04-strong", "05-recovery"};
  for (int i = 0; i < moments.length; i++) {
    String label = mode == DEMO ? names[i] : "input-at-" + int(moments[i] * 10) + "-tenths";
    File screenshot = new File(runDirectory + "/" + label + ".png");
    if (elapsed >= moments[i] && !screenshot.exists()) save(screenshot.getAbsolutePath());
  }

  // During a guided human trial, capture each prompted phase after two seconds.
  if (guidedTest) {
    String phase = guidedPhase();
    File stageShot = new File(runDirectory + "/guided-" + phase + ".png");
    float t = elapsed - guidedStarted;
    float stageStart = t < 10 ? 0 : t < 25 ? 10 : t < 40 ? 25 : t < 55 ? 40 : 55;
    if (t - stageStart >= 2 && !stageShot.exists()) save(stageShot.getAbsolutePath());
  }
}

/** Closes evidence output and writes one machine-readable summary JSON file. */
void finishEvidence() {
  // The guard prevents duplicate writes from both timed exit and dispose().
  if (finishedRun || runDirectory == null) return;
  finishedRun = true;
  if (telemetry != null) { telemetry.flush(); telemetry.close(); }
  JSONObject report = new JSONObject();
  report.setString("project_version", PROJECT_VERSION);
  report.setString("mode", modeName());
  report.setString("os", System.getProperty("os.name") + " " + System.getProperty("os.version"));
  report.setString("java", System.getProperty("java.version"));
  report.setFloat("animation_seconds", elapsed);
  report.setInt("rendered_frames", frameCount);
  report.setInt("max_particles", maxParticlesSeen);
  report.setInt("max_ripples", maxRipplesSeen);
  report.setFloat("mean_fps_after_warmup", fpsSamples > 0 ? fpsSum / fpsSamples : 0);
  report.setFloat("min_fps_after_warmup", fpsSamples > 0 ? minFps : 0);
  report.setBoolean("fixed_animation_clock", captureFrames && mode == DEMO);
  report.setBoolean("microphone_opened", input.available);
  report.setString("microphone_error", input.errorMessage);
  report.setString("device", input.deviceName);
  report.setString("evidence_limit", mode == MICROPHONE ? "Live amplitude, no labelled human breath trial" : "Simulation; not evidence of human breath input");
  saveJSONObject(report, runDirectory + "/run-report.json");
}

// Preserve the final log when the user closes the sketch window or presses Esc.
/** Processing lifecycle hook used for safe stream and file cleanup. */
public void dispose() {
  finishEvidence();
  if (input != null) input.stop();
  super.dispose();
}

/**
 * Fixed-size circular buffer used to draw recent intensity history efficiently.
 * New samples overwrite the oldest sample, so memory use never increases.
 */
class LevelGraph {
  /** Circular sample storage; 240 values represent about four seconds at 60 FPS. */
  final float[] samples;

  /** Index at which the next sample will be written. */
  int next = 0;

  /** Allocates a fixed number of graph samples once. */
  LevelGraph(int count) { samples = new float[count]; }

  /** Zeros the graph and returns the write index to the first element. */
  void clear() { java.util.Arrays.fill(samples, 0); next = 0; }

  /** Adds one value, wrapping around when the end of the array is reached. */
  void add(float value) { samples[next] = value; next = (next + 1) % samples.length; }

  /** Draws samples oldest-to-newest inside the requested rectangle. */
  void display(float x, float y, float w, float h) {
    noFill(); stroke(57, 86, 104); rect(x, y, w, h, 3);
    stroke(144, 218, 207); beginShape();

    // (next + i) modulo length reorders circular storage chronologically.
    for (int i = 0; i < samples.length; i++) vertex(x + i * w / (samples.length - 1), y + h * (1 - samples[(next + i) % samples.length]));
    endShape();
  }
}
