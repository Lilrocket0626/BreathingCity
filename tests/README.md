# Reproducible code checks

These tests exercise the production code. They do not require JUnit and do not
open a microphone. Running the sketch in Processing does **not** require running
these developer checks or installing a separate JDK.

## Signal processing

With JDK 17 or newer available, run from the `BreathingCity_A2` project directory:

```sh
mkdir -p tests/build
javac -d tests/build BreathingCity/SignalEnvelope.java tests/SignalEnvelopeTest.java
java -cp tests/build SignalEnvelopeTest
```

The suite covers quiet calibration, an isolated click, sustained louder noise,
silence, gate hysteresis, sensitivity, attack/release, equal response at
30/60/120 FPS, invalid samples/time deltas, tuning limits and recalibration.
The tests compile the exact `SignalEnvelope.java` that Processing loads.

## Bounded effect state

First build the final sketch using Processing's Java-mode compiler. Use that
compiler's output folder, not an independently rewritten Java version. Set the
classpath to include the build folder, Processing `core` jars and Sound jars.

Example for a POSIX shell, with paths adapted to the local installation:

```sh
# Set these three paths to real local folders before running the commands.
BC_BUILD=/path/to/processing-build
BC_CORE=/path/to/Processing/core/library
BC_SOUND=/path/to/sketchbook/libraries/sound/library
javac -cp "$BC_BUILD:$BC_CORE/*:$BC_SOUND/*" -d tests/build tests/VisualEffectsTest.java
java -Djava.awt.headless=true -cp "tests/build:$BC_BUILD:$BC_CORE/*:$BC_SOUND/*" VisualEffectsTest
```

On Windows, use `;` between classpath entries and the corresponding PowerShell
environment syntax, or invoke the commands from a shell that supports the
examples. `tests/build` is generated output and may be deleted.

`VisualEffectsTest` instantiates the actual compiled `BreathingCity.VisualEffects`
and replaces only pixel drawing with a silent sink. It verifies event peak
capture, repeated ripples, particle/ripple caps, dropped excess emission,
expiry, reset and time-based emission. It advances 1,800 seconds of simulated
time in a fast loop. **That is a state/lifetime stress test, not a real 30-minute
rendered performance test, a microphone test or evidence of stable FPS.**

The measured run and source hashes are retained in
[test-results-2026-10-01.txt](test-results-2026-10-01.txt).

## Keyboard callback state

Using the same compiled sketch and classpath folders as above:

```sh
javac -cp "$BC_BUILD:$BC_CORE/*:$BC_SOUND/*" -d tests/build tests/ControlStateTest.java
java -Djava.awt.headless=true -cp "tests/build:$BC_BUILD:$BC_CORE/*:$BC_SOUND/*" ControlStateTest
```

This calls the actual compiled `keyPressed()` method. It replaces only the
hardware-opening input adapter with a stub, so no microphone or window opens.
The ten cases cover input-mode changes, calibration, threshold/sensitivity
keys and limits, panel visibility, guided-test availability, prompt timing and
cancelling an obsolete guided timeline when changing devices or recalibrating.
It does **not** test physical keys, keyboard focus, OS events or audio hardware.

This check found a real defect: `N` reconnected the input but retained the old
guided-test timeline and graph. The final handler cancels the old trial and
clears the graph; `R` also cancels a microphone trial before recalibrating.
The failing and passing outputs are preserved separately:

- [Before the fix](control-test-before-fix.txt)
- [After the fix](control-test-after-fix.txt)
- [Environment, source hashes and exact commands](control-test-record.txt)
