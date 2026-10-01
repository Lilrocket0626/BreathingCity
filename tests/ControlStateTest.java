import processing.core.PGraphics;

/**
 * Calls the real Processing-compiled keyPressed() handler directly.
 * A stub replaces only microphone opening; no GUI or audio hardware is started.
 * This is callback/state coverage, NOT a physical keyboard or focus test.
 */
public final class ControlStateTest {
  private static int assertions;
  private static int cases;

  public static void main(String[] args) {
    run("M microphone to mouse clears previous state", ControlStateTest::micToMouse);
    run("M mouse to microphone reconnects and calibrates", ControlStateTest::mouseToMic);
    run("A starts a fresh synthetic demo", ControlStateTest::autoDemo);
    run("R restarts demo calibration", ControlStateTest::recalibrateDemo);
    run("bracket keys tune and bound threshold margin", ControlStateTest::marginKeys);
    run("gain aliases bound sensitivity; zero resets tuning", ControlStateTest::gainKeys);
    run("D and H toggle panels", ControlStateTest::panelKeys);
    run("G refuses unavailable microphone", ControlStateTest::guidedUnavailable);
    run("G starts calibration and correct guided stages", ControlStateTest::guidedAvailable);
    run("N and R cancel the previous guided timeline", ControlStateTest::deviceChange);
    System.out.println("PASS: " + cases + " callback cases, " + assertions + " assertions.");
    System.out.println("Direct callback tests only; microphone adapter stubbed; no physical key presses or GUI.");
  }

  private static void micToMouse() {
    Fixture f = new Fixture(); f.input.available = true;
    dirty(f); key(f, 'm');
    check(f.app.mode == f.app.MOUSE, "M selects mouse from mic");
    check(!f.input.available, "old mic adapter is stopped");
    check(f.input.beginCalls == 0, "mouse transition cannot open a microphone");
    cleared(f);
  }

  private static void mouseToMic() {
    Fixture f = new Fixture(); f.app.mode = f.app.MOUSE;
    dirty(f); key(f, 'M');
    check(f.app.mode == f.app.MICROPHONE, "M selects microphone from mouse");
    check(f.input.beginCalls == 1 && f.input.available, "mic adapter starts once");
    check(f.input.envelope.calibrating, "microphone transition recalibrates");
    cleared(f);
  }

  private static void autoDemo() {
    Fixture f = new Fixture(); f.input.available = true;
    dirty(f); key(f, 'A');
    check(f.app.mode == f.app.DEMO, "A selects synthetic demo");
    check(!f.input.available && f.input.beginCalls == 0, "demo never opens microphone");
    check(f.input.envelope.calibrating, "demo starts with calibration");
    cleared(f);
  }

  private static void recalibrateDemo() {
    Fixture f = new Fixture(); f.app.mode = f.app.DEMO;
    f.app.demoTime = 13;
    f.input.envelope.update(0.9f, 0.1f);
    key(f, 'r');
    check(f.app.demoTime == 0, "R restarts synthetic timeline");
    check(f.input.envelope.calibrating, "R starts calibration");
    check(f.input.envelope.intensity == 0 && f.input.envelope.target == 0,
      "R clears old envelope response");
    check(f.input.beginCalls == 0, "demo R never opens microphone");
  }

  private static void marginKeys() {
    Fixture f = new Fixture();
    key(f, '['); near(0.0015f, f.input.envelope.margin, "[ lowers margin");
    key(f, ']'); near(0.002f, f.input.envelope.margin, "] raises margin");
    for (int i = 0; i < 200; i++) key(f, '[');
    near(0.0005f, f.input.envelope.margin, "margin lower bound");
    for (int i = 0; i < 200; i++) key(f, ']');
    near(0.05f, f.input.envelope.margin, "margin upper bound");
  }

  private static void gainKeys() {
    Fixture f = new Fixture();
    key(f, '-'); near(0.8f, f.input.envelope.sensitivity, "- reduces gain");
    key(f, '='); near(1, f.input.envelope.sensitivity, "= increases gain");
    key(f, '+'); near(1.25f, f.input.envelope.sensitivity, "+ alias increases gain");
    key(f, '_'); near(1, f.input.envelope.sensitivity, "_ alias reduces gain");
    for (int i = 0; i < 40; i++) key(f, '-');
    near(0.25f, f.input.envelope.sensitivity, "gain lower bound");
    for (int i = 0; i < 40; i++) key(f, '+');
    near(8, f.input.envelope.sensitivity, "gain upper bound");
    f.input.envelope.margin = 0.04f;
    key(f, '0');
    near(1, f.input.envelope.sensitivity, "zero resets gain");
    near(0.002f, f.input.envelope.margin, "zero resets margin");
  }

  private static void panelKeys() {
    Fixture f = new Fixture();
    key(f, 'd'); check(!f.app.debugVisible, "D hides data");
    key(f, 'D'); check(f.app.debugVisible, "D shows data");
    key(f, 'h'); check(!f.app.helpVisible, "H hides help");
    key(f, 'H'); check(f.app.helpVisible, "H shows help");
    check(f.app.mode == f.app.MICROPHONE && f.input.beginCalls == 0,
      "panel controls cannot change input source");
  }

  private static void guidedUnavailable() {
    Fixture f = new Fixture(); f.app.mode = f.app.MOUSE;
    f.input.allowConnection = false;
    key(f, 'g');
    check(!f.app.guidedTest, "G cannot claim a live trial without input");
    check(f.input.beginCalls == 1, "G tries the input adapter once");
    check(f.app.notice.contains("working microphone"), "G explains missing input");
  }

  private static void guidedAvailable() {
    Fixture f = new Fixture(); f.input.available = true;
    dirty(f); f.app.elapsed = 7;
    key(f, 'G');
    check(f.app.guidedTest && f.app.guidedStarted == 7, "G starts a new timed trial");
    check(f.input.envelope.calibrating, "G calibrates before breath prompts");
    check(f.app.effects.particles.isEmpty() && f.app.effects.ripples.isEmpty(),
      "G clears previous visual effects");
    check(f.input.beginCalls == 0, "G keeps an already working adapter");
    String[] phases = {"quiet", "gentle", "strong", "recovery", "complete"};
    float[] offsets = {0, 10, 25, 40, 55};
    for (int i = 0; i < offsets.length; i++) {
      f.app.elapsed = 7 + offsets[i];
      check(phases[i].equals(f.app.guidedPhase()), "guided stage boundary " + offsets[i]);
    }
  }

  private static void deviceChange() {
    Fixture f = new Fixture(); f.input.available = true;
    key(f, 'G'); f.app.elapsed = 26;
    f.app.graph.add(0.8f);
    key(f, 'N');
    check(f.input.nextCalls == 1, "N requests a device change");
    check(!f.app.guidedTest, "device change must cancel previous guided trial");
    check("none".equals(f.app.guidedPhase()), "new device cannot retain old trial phase");
    for (float value : f.app.graph.samples) check(value == 0, "new device clears old graph");
    key(f, 'G');
    check(f.app.guidedTest, "a fresh guided trial can begin after device selection");
    key(f, 'R');
    check(!f.app.guidedTest && "none".equals(f.app.guidedPhase()),
      "manual recalibration also cancels previous guided timeline");
    check(f.input.envelope.calibrating, "R still starts microphone calibration");
  }

  private static void dirty(Fixture f) {
    f.app.intensity = 0.8f; f.app.demoTime = 13; f.app.guidedTest = true;
    f.app.graph.add(0.8f);
    f.app.effects.particles.add(f.app.new BreathParticle(0.8f));
    f.app.effects.addRipple(0.8f);
  }

  private static void cleared(Fixture f) {
    check(f.app.intensity == 0 && f.app.demoTime == 0, "old signal/timeline cleared");
    check(!f.app.guidedTest, "mode switch cancels guided trial");
    check(f.app.effects.particles.isEmpty() && f.app.effects.ripples.isEmpty(), "effects cleared");
    for (float value : f.app.graph.samples) check(value == 0, "signal history cleared");
  }

  private static void key(Fixture f, char value) { f.app.key = value; f.app.keyPressed(); }
  private static void near(float expected, float actual, String message) {
    check(Math.abs(expected - actual) < 0.000001f, message);
  }
  private static void check(boolean condition, String message) {
    assertions++;
    if (!condition) throw new AssertionError(message);
  }
  private static void run(String name, Runnable body) {
    body.run(); cases++; System.out.println("PASS " + name);
  }

  static final class Fixture {
    final BreathingCity app = new BreathingCity();
    final InputStub input;
    Fixture() {
      app.width = 1280; app.height = 720; app.g = new PGraphics();
      app.randomSeed(52685);
      input = new InputStub(app); app.input = input;
      app.effects = app.new VisualEffects(); app.graph = app.new LevelGraph(240);
    }
  }

  /** Only hardware-bound adapter methods are replaced; callback logic is real. */
  static final class InputStub extends BreathingCity.BreathInput {
    int beginCalls, nextCalls;
    boolean allowConnection = true;
    InputStub(BreathingCity owner) { owner.super(owner); }
    @Override public boolean begin() {
      beginCalls++; available = allowConnection;
      if (available) envelope.startCalibration();
      return available;
    }
    @Override public void nextDevice() { nextCalls++; begin(); }
  }
}
