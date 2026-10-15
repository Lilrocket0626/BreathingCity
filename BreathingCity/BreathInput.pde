/**
 * Owns the real microphone connection provided by the Processing Sound library.
 * This class is responsible only for selecting an input device, reading RMS
 * loudness, reporting input problems, and forwarding valid readings to
 * SignalEnvelope. No audio is played, monitored, recorded, or written to disk.
 */
class BreathInput {
  /** Main Processing sketch required by Sound, AudioIn and Amplitude. */
  final PApplet parent;

  /** Converts raw RMS readings into a calibrated 0..1 control value. */
  final SignalEnvelope envelope = new SignalEnvelope();

  /** Live audio stream from the currently selected input channel. */
  AudioIn microphone;

  /** Processing Sound analyser that returns RMS amplitude for each audio block. */
  Amplitude analyzer;

  /** Processing Sound engine used to list and select hardware devices. */
  Sound sound;

  /** True only after the input stream and analyser connect successfully. */
  boolean available = false;

  /** Prevents repeatedly constructing the Sound engine during reconnection. */
  boolean initialized = false;

  /** Human-readable device name shown in the debug panel. */
  String deviceName = "System default";

  /** Most recent connection or runtime error shown for troubleshooting. */
  String errorMessage = "";

  /** Processing Sound ID for the selected hardware input device. */
  int deviceId = -1;

  /** IDs of devices that report at least one available input channel. */
  int[] inputDevices = new int[0];

  /** Continuous seconds of near-zero input, used to warn about permissions. */
  float zeroSeconds = 0;

  /** Continuous seconds near maximum level, used to warn about clipping. */
  float clippingSeconds = 0;

  /** Stores the sketch reference required by Processing Sound constructors. */
  BreathInput(PApplet parent) { this.parent = parent; }

  /**
   * Opens the selected input device and begins a fresh quiet-room calibration.
   * The method returns false instead of crashing the whole artwork when a
   * device, permission, or native Sound-library error occurs.
   */
  boolean begin() {
    // Always release an earlier stream before opening or changing a device.
    stop();
    try {
      if (!initialized) {
        sound = new Sound(parent);
        initialized = true;
      }
      // Re-read devices on retry: a newly connected input must not be ignored.
      String[] names = Sound.list();
      IntList ids = new IntList();
      for (int id = 0; id < names.length; id++) {
        // Playback-only devices are not useful, so keep input-capable IDs only.
        if (Sound.getAudioDeviceManager().getMaxInputChannels(id) > 0) ids.append(id);
      }
      inputDevices = ids.array();
      if (inputDevices.length == 0) throw new RuntimeException("No input device found");

      // Prefer the previous choice, otherwise the system default, otherwise the
      // first valid input. This also handles disconnected microphones safely.
      if (!ids.hasValue(deviceId)) deviceId = Sound.getAudioDeviceManager().getDefaultInputDeviceID();
      if (!ids.hasValue(deviceId)) deviceId = inputDevices[0];
      sound.inputDevice(deviceId);
      deviceName = names[deviceId];

      // The second argument is CHANNEL zero, not the device ID.
      microphone = new AudioIn(parent, 0);
      if (analyzer == null) analyzer = new Amplitude(parent);
      microphone.start(); // start(), unlike play(), avoids monitoring/feedback.
      analyzer.input(microphone);

      // Only advertise availability after every connection step succeeds.
      available = true;
      errorMessage = "";
      zeroSeconds = clippingSeconds = 0;
      envelope.startCalibration();
      return true;
    } catch (RuntimeException error) {
      fail(error.getClass().getSimpleName() + ": " + error.getMessage());
    } catch (LinkageError error) {
      fail("Sound native library: " + error.getMessage());
    }
    return false;
  }

  /** Moves the input object into a safe unavailable state and records the cause. */
  void fail(String message) {
    stop();
    errorMessage = message;
    println("Microphone unavailable: " + message);
    println("Check input device / permission; I retries; M uses simulation.");
  }

  /**
   * Releases the microphone stream and clears transient signal motion. Calling
   * this method repeatedly is safe, which simplifies switching between modes.
   */
  void stop() {
    if (microphone != null) {
      try { microphone.stop(); } catch (RuntimeException ignored) { }
      microphone = null;
    }
    available = false;
    envelope.calibrating = false;
    envelope.resetMotion();
  }

  /**
   * Reads and processes one microphone measurement.
   *
   * @param dt elapsed frame time in seconds
   * @return calibrated and smoothed visual intensity from 0 to 1
   */
  float update(float dt) {
    if (!available) return 0;
    try {
      float sample = analyzer.analyze(); // RMS amplitude of the current audio block.
      if (Float.isNaN(sample) || Float.isInfinite(sample)) {
        throw new RuntimeException("Invalid audio sample");
      }

      // These timers do not modify the signal. They drive clear diagnostic
      // messages when the input is silent for too long or continuously clips.
      zeroSeconds = sample <= 0.000001 ? zeroSeconds + dt : 0;
      clippingSeconds = sample >= 0.98 ? clippingSeconds + dt : 0;
      return envelope.update(sample, dt);
    } catch (RuntimeException error) {
      fail(error.getMessage());
      return 0;
    }
  }

  /**
   * Cycles to the next input-capable device and reconnects. The modulo operation
   * wraps from the last device back to the first device.
   */
  void nextDevice() {
    if (!initialized) { begin(); return; }
    int index = -1;
    for (int i = 0; i < inputDevices.length; i++) if (inputDevices[i] == deviceId) index = i;
    if (inputDevices.length > 0) deviceId = inputDevices[(index + 1) % inputDevices.length];
    begin();
  }
}
