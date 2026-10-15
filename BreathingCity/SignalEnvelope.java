import java.util.Arrays;

/**
 * Converts RMS amplitude into a bounded visual control signal.
 *
 * <p>Signal path:</p>
 * <ol>
 *   <li>Collect three seconds of quiet-room samples.</li>
 *   <li>Estimate the background-noise floor from those samples.</li>
 *   <li>Use a two-threshold gate to reject low-level noise.</li>
 *   <li>Map sound above the gate to a target value from 0 to 1.</li>
 *   <li>Smooth that target with separate attack and release times.</li>
 * </ol>
 *
 * Pure Java, independent of audio hardware and drawing, so the same production
 * code can be exercised with deterministic test samples. It does not identify breath.
 */
public final class SignalEnvelope {
  /** Length of the quiet-room calibration at startup. */
  public static final float CALIBRATION_SECONDS = 3.0f;

  /** Time constant used when the visual intensity is rising. */
  public static final float ATTACK_SECONDS = 0.10f;

  /** Longer time constant used when the visual intensity is falling. */
  public static final float RELEASE_SECONDS = 0.55f;

  /** RMS distance above the opening threshold that maps to full intensity. */
  public static final float FULL_SCALE_ABOVE_GATE = 0.06f;

  // The buffer is deliberately larger than the expected number of samples.
  // At 60 FPS, three seconds normally produces about 180 readings.
  private final float[] calibration = new float[720];

  /** Number of valid values currently stored in calibration[]. */
  private int samples;

  /** Accumulated calibration time in seconds, independent of frame rate. */
  private float calibrationElapsed;

  /** Estimated background RMS level measured during quiet calibration. */
  public float noiseFloor = 0.002f;

  /** Extra level above the noise floor required to open the gate. */
  public float margin = 0.002f;

  /** User-adjustable multiplier controlling how strongly the artwork reacts. */
  public float sensitivity = 1.0f;

  /** Most recent valid RMS sample, constrained to the range 0..1. */
  public float raw;

  /** Immediate gated and mapped control value before temporal smoothing. */
  public float target;

  /** Final attack/release-smoothed value used by all visual systems. */
  public float intensity;

  /** True while the RMS input is above the gate's current closing condition. */
  public boolean gateOpen;

  /** True while the class is collecting quiet-room calibration samples. */
  public boolean calibrating;

  /**
   * Starts a fresh calibration whenever the program starts, the input device
   * changes, or the user presses R. Visual motion is reset so room noise cannot
   * animate the scene while the new baseline is being measured.
   */
  public void startCalibration() {
    samples = 0;
    calibrationElapsed = 0;
    calibrating = true;
    resetMotion();
  }

  /** Clears transient signal state without changing the learned noise floor. */
  public void resetMotion() {
    raw = target = intensity = 0;
    gateOpen = false;
  }

  /** Higher threshold used to begin a sound event. */
  public float openingThreshold() { return noiseFloor + margin; }

  /**
   * Lower threshold used to end a sound event. The 0.55 multiplier creates
   * hysteresis, so tiny variations near one boundary do not flicker the gate.
   */
  public float closingThreshold() { return noiseFloor + margin * 0.55f; }

  /** Number of seconds remaining in the current calibration. */
  public float calibrationRemaining() {
    return Math.max(0, CALIBRATION_SECONDS - calibrationElapsed);
  }

  /** Changes noise rejection while keeping the value inside a safe range. */
  public void adjustMargin(float delta) { margin = clamp(margin + delta, 0.0005f, 0.05f); }

  /** Changes response gain multiplicatively while preventing extreme values. */
  public void adjustSensitivity(float multiplier) {
    sensitivity = clamp(sensitivity * multiplier, 0.25f, 8.0f);
  }

  /**
   * Processes one RMS reading per rendered frame.
   *
   * @param sample RMS amplitude supplied by Processing Sound (normally 0..1)
   * @param dt elapsed real time in seconds, not a frame counter
   * @return a stable visual control value in the range 0..1
   */
  public float update(float sample, float dt) {
    // Reject invalid timing and audio values before they can reach the visuals.
    dt = clamp(Float.isFinite(dt) ? dt : 0, 0, 0.1f);
    raw = Float.isFinite(sample) ? clamp(sample, 0, 1) : 0;
    if (calibrating) {
      // Store samples only while buffer capacity remains, but continue timing.
      if (samples < calibration.length) calibration[samples++] = raw;
      calibrationElapsed += dt;

      // At least 45 readings prevents a misleading result after a very slow or
      // interrupted startup. Normally many more readings are available.
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

    // Subtract the opening threshold so the mapped value begins at zero.
    // FULL_SCALE_ABOVE_GATE defines how much additional loudness reaches 1.0.
    target = gateOpen ? clamp((raw - openingThreshold()) * sensitivity /
                             FULL_SCALE_ABOVE_GATE, 0, 1) : 0;

    // The target may change instantly; intensity follows it smoothly over time.
    intensity = smooth(intensity, target, dt);

    // Snap extremely small release tails to exactly zero to avoid endless motion.
    if (target == 0 && intensity < 0.001f) intensity = 0;
    return intensity;
  }

  /**
   * Exponential smoothing preserves approximately the same response time at
   * 30, 60 or 120 FPS. A short attack feels responsive; a longer release makes
   * the city settle rather than switching off abruptly.
   */
  public static float smooth(float current, float target, float dt) {
    // Select the time constant according to the direction of travel.
    float tau = target > current ? ATTACK_SECONDS : RELEASE_SECONDS;
    // Convert a time constant into the interpolation amount for this exact frame.
    float amount = (float)(1.0 - Math.exp(-Math.max(0, dt) / tau));
    return current + (target - current) * amount;
  }

  /** Utility used to guarantee that control values remain inside valid bounds. */
  private static float clamp(float value, float low, float high) {
    return Math.max(low, Math.min(high, value));
  }
}
