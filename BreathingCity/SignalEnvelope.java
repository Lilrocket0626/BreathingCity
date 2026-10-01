import java.util.Arrays;

/**
 * Converts RMS amplitude into a bounded visual control signal.
 * Pure Java, independent of audio hardware and drawing, so the same production
 * code can be exercised with deterministic test samples. It does not identify breath.
 */
public final class SignalEnvelope {
  public static final float CALIBRATION_SECONDS = 3.0f;
  public static final float ATTACK_SECONDS = 0.10f;
  public static final float RELEASE_SECONDS = 0.55f;
  public static final float FULL_SCALE_ABOVE_GATE = 0.06f;
  private final float[] calibration = new float[720];
  private int samples;
  private float calibrationElapsed;
  public float noiseFloor = 0.002f;
  public float margin = 0.002f;
  public float sensitivity = 1.0f;
  public float raw;
  public float target;
  public float intensity;
  public boolean gateOpen;
  public boolean calibrating;

  public void startCalibration() {
    samples = 0;
    calibrationElapsed = 0;
    calibrating = true;
    resetMotion();
  }

  public void resetMotion() {
    raw = target = intensity = 0;
    gateOpen = false;
  }

  public float openingThreshold() { return noiseFloor + margin; }
  public float closingThreshold() { return noiseFloor + margin * 0.55f; }
  public float calibrationRemaining() {
    return Math.max(0, CALIBRATION_SECONDS - calibrationElapsed);
  }

  public void adjustMargin(float delta) { margin = clamp(margin + delta, 0.0005f, 0.05f); }
  public void adjustSensitivity(float multiplier) {
    sensitivity = clamp(sensitivity * multiplier, 0.25f, 8.0f);
  }

  /** One RMS reading per rendered frame; dt is seconds, not a frame counter. */
  public float update(float sample, float dt) {
    dt = clamp(Float.isFinite(dt) ? dt : 0, 0, 0.1f);
    raw = Float.isFinite(sample) ? clamp(sample, 0, 1) : 0;
    if (calibrating) {
      if (samples < calibration.length) calibration[samples++] = raw;
      calibrationElapsed += dt;
      if (calibrationElapsed >= CALIBRATION_SECONDS && samples >= 45) {
        Arrays.sort(calibration, 0, samples);
        // The 90th percentile rejects isolated clicks but represents typical louder
        // room noise. Stay quiet: sustained speech during calibration biases it.
        noiseFloor = Math.max(0.0003f, calibration[(int)((samples - 1) * 0.90f)]);
        calibrating = false;
      }
      target = intensity = 0;
      gateOpen = false;
      return intensity;
    }

    // Hysteresis has separate open/close levels, preventing rapid gate chatter.
    if (gateOpen && raw < closingThreshold()) gateOpen = false;
    else if (!gateOpen && raw > openingThreshold()) gateOpen = true;
    target = gateOpen ? clamp((raw - openingThreshold()) * sensitivity /
                             FULL_SCALE_ABOVE_GATE, 0, 1) : 0;
    intensity = smooth(intensity, target, dt);
    if (target == 0 && intensity < 0.001f) intensity = 0;
    return intensity;
  }

  /** Exponential smoothing preserves response time at 30, 60 or 120 FPS. */
  public static float smooth(float current, float target, float dt) {
    float tau = target > current ? ATTACK_SECONDS : RELEASE_SECONDS;
    float amount = (float)(1.0 - Math.exp(-Math.max(0, dt) / tau));
    return current + (target - current) * amount;
  }

  private static float clamp(float value, float low, float high) {
    return Math.max(low, Math.min(high, value));
  }
}
