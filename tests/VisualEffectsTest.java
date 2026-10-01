import processing.core.PGraphics;

/**
 * Runs the ACTUAL classes emitted by the Processing compiler with a no-op
 * drawing sink. This verifies object/event logic without opening a GUI or mic.
 * It is not a rendered performance, audio, or real-time soak test.
 */
public final class VisualEffectsTest {
  private static int assertions;

  public static void main(String[] args) {
    BreathingCity sketch = new BreathingCity();
    sketch.width = 1280; sketch.height = 720;
    sketch.g = new SilentGraphics();
    sketch.randomSeed(52685); sketch.noiseSeed(52685);
    BreathingCity.VisualEffects effects = sketch.new VisualEffects();

    effects.updateAndDraw(0.13f, 1f / 60);
    check(effects.ripples.size() == 1, "crossing event threshold creates one ripple");
    BreathingCity.BreathWave first = effects.currentWave;
    effects.updateAndDraw(0.9f, 1f / 60);
    check(first == effects.currentWave && first.strength == 0.9f,
      "current ripple captures later strong peak, rather than frozen crossing level");
    effects.updateAndDraw(0.3f, 1f / 60);
    check(first.strength == 0.9f, "falling signal cannot erase event peak");
    effects.reset();

    int peakParticles = 0, peakRipples = 0;
    // 30 MINUTES OF SIMULATED TIME executed faster than real time.
    // Only bounds/lifetimes are being tested: no FPS or real hardware claims.
    for (int frame = 0; frame < 30 * 60 * 60; frame++) {
      effects.updateAndDraw(1, 1f / 60);
      check(effects.particles.size() <= effects.MAX_PARTICLES, "particle count is bounded");
      check(effects.ripples.size() <= effects.MAX_RIPPLES, "ripple count is bounded");
      check(effects.emissionRemainder >= 0 && effects.emissionRemainder < 1,
        "full particle pool does not accumulate deferred emission");
      peakParticles = Math.max(peakParticles, effects.particles.size());
      peakRipples = Math.max(peakRipples, effects.ripples.size());
    }
    check(peakParticles == effects.MAX_PARTICLES, "stress case actually reaches capacity");
    check(peakRipples >= 2, "sustained strong input creates repeated ripples");
    for (int frame = 0; frame < 300; frame++) effects.updateAndDraw(0, 1f / 60);
    check(effects.particles.isEmpty() && effects.ripples.isEmpty(),
      "silence expires all transient objects");
    check(!effects.eventActive && effects.currentWave == null, "silence rearms event detection");

    // Explicitly exercise defensive cap even though normal lifetime/rate imply fewer.
    for (int i = 0; i < 50; i++) effects.addRipple(0.8f);
    check(effects.ripples.size() == effects.MAX_RIPPLES, "explicit ripple cap evicts oldest");
    effects.reset();
    check(effects.particles.isEmpty() && effects.ripples.isEmpty() &&
      effects.emissionRemainder == 0 && effects.currentWave == null, "reset clears transient state");

    int expectedCount = -1;
    for (int fps : new int[] {30, 60, 120}) {
      effects.reset();
      for (int frame = 0; frame < fps; frame++) effects.updateAndDraw(0.2f, 1f / fps);
      if (expectedCount < 0) expectedCount = effects.particles.size();
      check(Math.abs(effects.particles.size() - expectedCount) <= 1,
        "emission per second stable across frame rates, allowing integer rounding");
    }
    System.out.println("PASS: actual compiled VisualEffects; " + assertions + " assertions.");
    System.out.println("Simulated duration: 1800 seconds; peak particles: " + peakParticles +
      "; peak ripples: " + peakRipples + ". No rendered FPS or microphone validation.");
  }

  private static void check(boolean condition, String message) {
    assertions++;
    if (!condition) throw new AssertionError(message);
  }

  // PGraphics still provides Processing's real color conversions. Only the
  // final pixel drawing calls are discarded; production effect logic is unchanged.
  static final class SilentGraphics extends PGraphics {
    @Override public void ellipse(float x, float y, float w, float h) { }
  }
}
