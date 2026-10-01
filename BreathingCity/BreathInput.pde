/** Owns the real Sound library input. No audio is played or written to disk. */
class BreathInput {
  final PApplet parent;
  final SignalEnvelope envelope = new SignalEnvelope();
  AudioIn microphone;
  Amplitude analyzer;
  Sound sound;
  boolean available = false;
  boolean initialized = false;
  String deviceName = "System default";
  String errorMessage = "";
  int deviceId = -1;
  int[] inputDevices = new int[0];
  float zeroSeconds = 0;
  float clippingSeconds = 0;

  BreathInput(PApplet parent) { this.parent = parent; }

  boolean begin() {
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
        if (Sound.getAudioDeviceManager().getMaxInputChannels(id) > 0) ids.append(id);
      }
      inputDevices = ids.array();
      if (inputDevices.length == 0) throw new RuntimeException("No input device found");
      if (!ids.hasValue(deviceId)) deviceId = Sound.getAudioDeviceManager().getDefaultInputDeviceID();
      if (!ids.hasValue(deviceId)) deviceId = inputDevices[0];
      sound.inputDevice(deviceId);
      deviceName = names[deviceId];
      // The second argument is CHANNEL zero, not the device ID.
      microphone = new AudioIn(parent, 0);
      if (analyzer == null) analyzer = new Amplitude(parent);
      microphone.start(); // start(), unlike play(), avoids monitoring/feedback.
      analyzer.input(microphone);
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

  void fail(String message) {
    stop();
    errorMessage = message;
    println("Microphone unavailable: " + message);
    println("Check input device / permission; I retries; M uses simulation.");
  }

  void stop() {
    if (microphone != null) {
      try { microphone.stop(); } catch (RuntimeException ignored) { }
      microphone = null;
    }
    available = false;
    envelope.calibrating = false;
    envelope.resetMotion();
  }

  float update(float dt) {
    if (!available) return 0;
    try {
      float sample = analyzer.analyze(); // RMS amplitude of the current audio block.
      if (Float.isNaN(sample) || Float.isInfinite(sample)) {
        throw new RuntimeException("Invalid audio sample");
      }
      zeroSeconds = sample <= 0.000001 ? zeroSeconds + dt : 0;
      clippingSeconds = sample >= 0.98 ? clippingSeconds + dt : 0;
      return envelope.update(sample, dt);
    } catch (RuntimeException error) {
      fail(error.getMessage());
      return 0;
    }
  }

  void nextDevice() {
    if (!initialized) { begin(); return; }
    int index = -1;
    for (int i = 0; i < inputDevices.length; i++) if (inputDevices[i] == deviceId) index = i;
    if (inputDevices.length > 0) deviceId = inputDevices[(index + 1) % inputDevices.length];
    begin();
  }
}
