# Breathing City - Code Walkthrough

Use this guide to understand the code before recording the explainer video. The final video should explain selected core logic in your own natural delivery instead of reading every line.

## 1. The central idea: one traceable data pipeline

The project does not connect the microphone directly to random visual effects. It converts sound through a series of stages:

```text
microphone → raw amplitude → calibrated signal → mapped value → smoothed intensity → visuals
```

The global `intensity` variable is constrained between `0.0` and `1.0`. Because every visual system receives the same range, it is easy to reason about and test.

## 2. Capturing amplitude

`BreathInput.begin()` creates an `AudioIn` object, starts it, creates an `Amplitude` analyzer, and connects the microphone to the analyzer. `Amplitude.analyze()` returns the current root-mean-square sound level.

The raw level cannot be used safely by itself because every room has background sound.

## 3. Calibration and normalization

For the first three seconds, `BreathInput.update()` adds every raw sample to `calibrationTotal` and counts the samples. It then calculates an average and multiplies it by `1.35` to place the noise floor slightly above ordinary room sound.

The program subtracts this floor:

```text
signalAboveRoomNoise = max(0, rawLevel - noiseFloor)
```

Anything below the noise floor becomes zero. `map()` converts the useful signal range into `0.0-1.0`, and `constrain()` prevents unusually loud sounds from producing invalid values above one.

## 4. Attack and release smoothing

The program uses two interpolation rates:

- `0.24` when the new signal is stronger than the current intensity;
- `0.065` when the signal is becoming weaker.

This is an attack-and-release design. The faster attack makes the artwork react promptly. The slower release lets it settle gradually instead of flickering.

## 5. Detecting a breath event

A wave should be created once at the start of a breath, not on every frame while the sound remains loud. `triggerBreathWave()` therefore checks for a rising edge:

```text
current intensity >= threshold AND previous intensity < threshold
```

It also checks that 42 frames have passed since the previous wave. The two Boolean conditions separate event detection from continuous visual control.

## 6. Managing particles safely

`emitParticles()` adds more particles when intensity is high but never exceeds `MAX_PARTICLES`. This prevents unlimited growth and protects performance.

`updateAndDrawParticles()` loops backwards through the `ArrayList`. When an expired particle is removed, the unprocessed indexes remain valid. A forward loop could skip an item after removal.

Every `BreathParticle` contains its own:

- position;
- velocity;
- remaining life;
- size;
- noise offset; and
- colour.

This is object-oriented organisation: the main sketch manages the collection, while each object manages its own state and behaviour.

## 7. Creating organic motion

Each particle uses Perlin noise to generate a small sideways force. Unlike frame-by-frame random values, nearby noise samples change smoothly. This produces drifting movement that better resembles air.

`PVector` stores position and velocity as paired x/y values. The particle adds velocity to position on every frame and limits maximum speed.

## 8. The circular live-data graph

`LevelGraph` stores 220 intensity samples in a fixed-size array. `nextIndex` moves forward and wraps to zero using the modulo operator:

```text
nextIndex = (nextIndex + 1) % history.length
```

This keeps recent information without continually increasing memory usage. The graph also draws the breath threshold, making the relationship between data and a triggered wave visible.

## 9. Stable procedural visuals

The buildings and stars are generated once in `setup()`. A fixed `randomSeed()` makes the city repeatable between runs. Particles remain varied because the seed is not reset inside `draw()`.

All buildings are stored in an array. Each `Building` uses nested loops to draw its rows and columns of windows. `noise()` gives each window a stable local variation, while the shared intensity determines how strongly it glows.

## 10. Fallback and responsible testing

If microphone access fails, the exception is handled and the user is directed to simulation mode. Pressing `M` maps horizontal mouse position to intensity. This does not replace microphone testing, but it prevents a permission problem from making the full visual system impossible to demonstrate.

## Best three sections for the explainer video

For a three-minute video, focus on:

1. calibration, mapping, and smoothing in `BreathInput.update()`;
2. rising-edge detection and cooldown in `triggerBreathWave()`; and
3. object-based particle management in `emitParticles()` and `updateAndDrawParticles()`.

These sections demonstrate data literacy, conditions, state, functions, arrays, object-oriented code, debugging awareness, and performance management.
