/**
 * Dependency-free tests against the exact production SignalEnvelope.java.
 * Run with assertions implemented below; JVM -ea is not required.
 * These synthetic samples verify math and state transitions, not a microphone.
 */
public final class SignalEnvelopeTest {
  private static int assertions;
  private static int cases;

  public static void main(String[] args) {
    run("steady room calibration", SignalEnvelopeTest::steadyCalibration);
    run("isolated click rejected by percentile", SignalEnvelopeTest::isolatedSpike);
    run("persistent louder noise represented", SignalEnvelopeTest::persistentNoise);
    run("silence calibration lower bound", SignalEnvelopeTest::silentCalibration);
    run("opening and closing hysteresis", SignalEnvelopeTest::hysteresis);
    run("sensitivity is monotonic", SignalEnvelopeTest::sensitivity);
    run("attack/release are bounded and settle", SignalEnvelopeTest::attackRelease);
    run("response independent of 30/60/120 FPS", SignalEnvelopeTest::frameRates);
    run("invalid samples and time deltas", SignalEnvelopeTest::invalidValues);
    run("tuning limits and motion reset", SignalEnvelopeTest::tuningAndReset);
    run("recalibration replaces previous floor", SignalEnvelopeTest::recalibration);
    System.out.println("PASS: " + cases + " cases, " + assertions + " assertions.");
  }

  private static void steadyCalibration() {
    SignalEnvelope s = new SignalEnvelope();
    s.startCalibration();
    for (int frame = 0; frame < 120; frame++) {
      near(0, s.update(0.012f, 1f / 60), 0, "calibration suppresses output");
    }
    check(s.calibrating, "two seconds cannot complete three-second calibration");
    for (int frame = 0; frame < 65; frame++) s.update(0.012f, 1f / 60);
    check(!s.calibrating, "calibration completes after sufficient time/samples");
    near(0.012f, s.noiseFloor, 0.000001f, "steady room floor");
    near(0.014f, s.openingThreshold(), 0.000001f, "floor plus opening margin");
    near(0, s.intensity, 0, "room noise remains calm after calibration");
  }

  private static void isolatedSpike() {
    SignalEnvelope s = new SignalEnvelope();
    s.startCalibration();
    for (int frame = 0; frame < 185; frame++) {
      s.update(frame == 73 ? 0.91f : 0.007f, 1f / 60);
    }
    near(0.007f, s.noiseFloor, 0.000001f, "single spike does not set floor");
    check(!s.gateOpen, "background still gated after isolated calibration click");
  }

  private static void persistentNoise() {
    SignalEnvelope s = new SignalEnvelope();
    s.startCalibration();
    for (int frame = 0; frame < 185; frame++) {
      s.update(frame % 5 == 0 ? 0.02f : 0.006f, 1f / 60);
    }
    near(0.02f, s.noiseFloor, 0.000001f, "repeated higher noise enters 90th percentile");
  }

  private static void silentCalibration() {
    SignalEnvelope s = new SignalEnvelope();
    s.startCalibration();
    for (int frame = 0; frame < 185; frame++) s.update(0, 1f / 60);
    near(0.0003f, s.noiseFloor, 0, "silent input retains a finite minimum floor");
  }

  private static void hysteresis() {
    SignalEnvelope s = new SignalEnvelope();
    s.noiseFloor = 0.01f; s.margin = 0.01f;
    s.update(0.018f, 0.02f);
    check(!s.gateOpen, "below open threshold remains closed");
    s.update(0.021f, 0.02f);
    check(s.gateOpen && s.target > 0, "above open threshold opens");
    s.update(0.018f, 0.02f);
    check(s.gateOpen, "between thresholds does not chatter closed");
    near(0, s.target, 0, "no negative energy between gate thresholds");
    s.update(0.015f, 0.02f);
    check(!s.gateOpen, "below close threshold closes");
    s.update(0.018f, 0.02f);
    check(!s.gateOpen, "return to middle band cannot reopen");
    s.update(s.openingThreshold(), 0.02f);
    check(!s.gateOpen, "exact opening boundary cannot chatter open");
  }

  private static void sensitivity() {
    float last = -1;
    for (float gain : new float[] {0.25f, 0.5f, 1, 2, 4, 8}) {
      SignalEnvelope s = new SignalEnvelope(); s.sensitivity = gain;
      for (int frame = 0; frame < 60; frame++) s.update(0.016f, 1f / 60);
      check(s.intensity >= last, "higher gain never reduces identical input response");
      check(s.intensity <= 1, "sensitivity saturation remains bounded");
      last = s.intensity;
    }
    check(last > 0.99f, "maximum gain can reach strong response");
  }

  private static void attackRelease() {
    SignalEnvelope s = new SignalEnvelope();
    float previous = 0;
    for (int frame = 0; frame < 60; frame++) {
      float now = s.update(0.3f, 1f / 60);
      check(now >= previous && now <= 1, "attack bounded and monotonic");
      previous = now;
    }
    check(s.intensity > 0.99f, "sustained strong signal approaches maximum");
    for (int frame = 0; frame < 300; frame++) {
      float now = s.update(0, 1f / 60);
      check(now <= previous && now >= 0, "release bounded and monotonic");
      previous = now;
    }
    near(0, s.intensity, 0, "release settles exactly to calm");
    check(!s.gateOpen, "silence closes the gate");
  }

  private static void frameRates() {
    float[] reference = responseAt(60);
    for (int fps : new int[] {30, 120}) {
      float[] actual = responseAt(fps);
      for (int stage = 0; stage < actual.length; stage++) {
        near(reference[stage], actual[stage], 0.00002f,
          "equal wall-time response at " + fps + " FPS stage " + stage);
      }
    }
  }

  private static float[] responseAt(int fps) {
    SignalEnvelope s = new SignalEnvelope();
    float[] sample = {0.016f, 0.055f, 0, 0};
    float[] result = new float[sample.length];
    for (int stage = 0; stage < sample.length; stage++) {
      for (int frame = 0; frame < fps; frame++) s.update(sample[stage], 1f / fps);
      result[stage] = s.intensity;
    }
    return result;
  }

  private static void invalidValues() {
    for (float sample : new float[] {Float.NaN, Float.POSITIVE_INFINITY,
                                    Float.NEGATIVE_INFINITY, -1}) {
      SignalEnvelope s = new SignalEnvelope();
      near(0, s.update(sample, 0.02f), 0, "invalid/negative input is silence");
      near(0, s.raw, 0, "raw sample sanitized");
      check(!s.gateOpen, "invalid sample cannot open gate");
    }
    SignalEnvelope clipped = new SignalEnvelope();
    clipped.update(2, 0.02f);
    near(1, clipped.raw, 0, "out-of-range finite input clamps to one");
    for (float dt : new float[] {Float.NaN, Float.POSITIVE_INFINITY, -1, 0}) {
      SignalEnvelope s = new SignalEnvelope();
      near(0, s.update(0.3f, dt), 0, "invalid/nonpositive dt cannot jump intensity");
    }
    SignalEnvelope paused = new SignalEnvelope();
    float jump = paused.update(0.3f, 50);
    check(jump > 0.6f && jump < 0.64f, "long pause uses at most 0.1 seconds");
  }

  private static void tuningAndReset() {
    SignalEnvelope s = new SignalEnvelope();
    s.adjustMargin(-100); near(0.0005f, s.margin, 0, "margin lower bound");
    s.adjustMargin(100); near(0.05f, s.margin, 0, "margin upper bound");
    s.adjustSensitivity(0.001f); near(0.25f, s.sensitivity, 0, "gain lower bound");
    s.adjustSensitivity(1000); near(8, s.sensitivity, 0, "gain upper bound");
    s.update(0.9f, 0.1f); s.resetMotion();
    near(0, s.raw + s.target + s.intensity, 0, "reset clears motion values");
    check(!s.gateOpen, "reset clears gate");
    near(0.05f, s.margin, 0, "reset preserves user's tuning");
  }

  private static void recalibration() {
    SignalEnvelope s = new SignalEnvelope();
    s.noiseFloor = 0.04f; s.update(0.2f, 0.1f);
    s.startCalibration();
    near(0, s.intensity, 0, "recalibration clears old motion");
    for (int frame = 0; frame < 185; frame++) s.update(0.003f, 1f / 60);
    near(0.003f, s.noiseFloor, 0.000001f, "new calibration replaces previous room floor");
  }

  private static void run(String name, Runnable test) {
    test.run(); cases++;
    System.out.println("PASS " + name);
  }

  private static void near(float expected, float actual, float tolerance, String message) {
    check(Float.isFinite(actual) && Math.abs(expected - actual) <= tolerance,
      message + " (expected " + expected + ", got " + actual + ")");
  }

  private static void check(boolean condition, String message) {
    assertions++;
    if (!condition) throw new AssertionError(message);
  }
}
