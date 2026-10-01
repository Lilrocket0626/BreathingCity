# Breathing City — code walkthrough

This guide explains the revised source, not the preserved baseline. Read alongside the final `BreathingCity/` sketch. For measured results and exact installed versions, use the runtime report; this document explains intended/code-defined behaviour.

## 1. Trace the complete signal

```text
Input device → AudioIn(channel 0) → Amplitude.analyze() → RMS float
 → quiet calibration → noise estimate + margin → hysteresis gate
 → sensitivity and normalisation → attack/release envelope → energy [0,1]
 → sky / windows / landmarks / water / particles / ripples
```

`AudioIn` supplies the audio stream. `Amplitude` calculates root mean square over an audio block: conceptually `sqrt(mean(sample * sample))`. Squaring prevents positive and negative waveform samples from cancelling. The returned value is a level, not a waveform, frequency, calibrated decibel reading or breath classification. The official API pattern is verified in [references.md](references.md).

`BreathInput.begin()` selects a device through `Sound.inputDevice(deviceId)`, creates `new AudioIn(parent, 0)`, calls `start()`, and attaches the analyzer. **Zero is the input channel number, not a device ID.** Using `start()` avoids routing microphone input to the speakers. `update(dt)` reads RMS and hands it to `SignalEnvelope.update(sample, dt)`. Exceptions produce a visible unavailable state instead of fabricated input.

Mouse simulation and automated demonstration are explicitly labelled. The automated sequence supplies synthetic RMS numbers to the production envelope; it tests its software behaviour without proving hardware input. Mouse position bypasses calibration, gating and gain: it maps directly to a smoothed intensity, so changing margin or sensitivity does not change mouse response. These modes must not be described as a live breath test.

## 2. Calibration, threshold and sensitivity

`SignalEnvelope` is a plain Java class so its actual production calculations can be tested independently of an audio device and drawing window.

- `startCalibration()` clears the state and begins quiet sampling.
- Calibration gathers up to 720 readings for at least 3 seconds of accepted `dt`, with at least 45 readings. `dt` is capped at 0.1 seconds to avoid a large animation jump after a pause, so a heavily stalled run can take longer than 3 wall-clock seconds.
- The readings are sorted. Their 90th percentile becomes `noiseFloor`, with a minimum of `0.0003`. A few isolated peaks are less influential than on the old average estimate, but sustained speech/blowing can still spoil calibration. Stay quiet and press `R` to repeat it.
- `openingThreshold = noiseFloor + margin`; `closingThreshold = noiseFloor + 0.55 * margin`.
- A closed gate opens when `raw > openingThreshold`. An open gate closes when `raw < closingThreshold`. Two thresholds reduce state chatter around a single boundary.
- While open, `target = clamp((raw - openingThreshold) * sensitivity / 0.06, 0, 1)`. While closed, `target = 0`.

The open/close state and the target are distinct: between the closing and opening thresholds, the gate can remain open while the clamped target is already zero. This is deliberate; it retains gate state without adding a step in brightness.

Worked example, **illustrative values rather than measured microphone results**: if `noiseFloor = 0.003`, `margin = 0.002` and `sensitivity = 1`, the gate opens above `0.005` and closes below `0.0041`. Raw `0.017` gives target `0.20`; raw `0.059` gives `0.90`. A different microphone may produce different raw levels for the same breath.

## 3. Time-based attack and release

`SignalEnvelope.smooth()` uses:

```java
float tau = target > current ? ATTACK_SECONDS : RELEASE_SECONDS;
float amount = (float)(1.0 - Math.exp(-Math.max(0, dt) / tau));
return current + (target - current) * amount;
```

In normal interactive mode, `dt` is elapsed seconds computed in `draw()` from consecutive `System.nanoTime()` readings. For automated frame capture in demo mode only, the sketch deliberately uses a fixed 1/30-second animation step. `ATTACK_SECONDS = 0.10` responds quickly; `RELEASE_SECONDS = 0.55` settles more slowly. A time constant is not the full settling time: for a step input, one time constant moves about 63% of the remaining distance. Roughly three time constants move about 95%. When target is zero and intensity drops below `0.001`, the code snaps that imperceptibly small residue to zero.

This replaces frame-dependent interpolation. Under ordinary frame rates, 30, 60 and 120 FPS should have almost the same response duration. A very long pause is intentionally clipped to avoid sudden animation jumps; this is not a promise of exact real-time integration through a stalled application.

## 4. How energy changes the scene

The following table describes code-defined values at **illustrative steady energies** `0.2` and `0.9`, not recorded breath readings.

| Output | Mapping | Energy 0.2 | Energy 0.9 |
|---|---|---:|---:|
| Sky | `lerpColor(calm, active, energy)` | Mostly dark/cool | Mostly warm/purple |
| Building windows | Fixed per-window activation thresholds; alpha rises with energy | Fewer/dimmer windows | More/brighter windows |
| Bridge and opera house | Light alpha and shell/pylon colours rise with energy | Subdued lights | Bright warm landmarks |
| Wave phase speed | `0.35 + 1.30 * energy` rad/s | 0.61 | 1.52 |
| Base wave amplitude before perspective | `0.65 + 4.5 * energy` pixels | 1.55 | 4.70 |
| Particle emission above energy 0.025 | `12 + 95 * energy` particles/s, subject to cap | 31 | 97.5 |
| Particle upward speed | `12 + 95 * energy` pixels/s | 31 | 97.5 |
| Ripple radial speed at that peak strength | `55 + 150 * strength` pixels/s | 85 | 190 |

`CityScene.display()` integrates `wavePhase += dt * speed`. Changing speed changes future movement without replacing the current phase. `drawHarbour()` uses that phase inside sine waves, combines two wave frequencies, and increases amplitude with depth. Geometry is authored in a 1280×720 design space and scaled to the sketch window. The bridge arch, pylons, hangers and shell-like opera-house roofs make the Sydney reference explicit.

## 5. Continuous values, events and bounded objects

`VisualEffects.updateAndDraw()` receives continuous energy, but a new ripple is an event. An event starts above `0.12`, rearms below `0.06`, and uses a `0.6` second minimum interval. Sustained energy above `0.55` can add another ripple every `0.95` seconds.

The newest ripple's `strength` increases with the peak of the active event. The baseline captured strength only when energy first crossed `0.18`, which compressed the difference between a gentle and a strong onset. Peak tracking lets a ring strengthen as input rises.

Particle emission uses a fractional accumulator: `(12 + 95 * energy) * dt` is added, whole particles are emitted, and only the fraction remains. When full, extra requested emissions are discarded rather than stored for a later burst.

`MAX_PARTICLES = 180` and `MAX_RIPPLES = 8` provide explicit limits. Particles live 1.8–3.2 seconds; ripples live 2.3 seconds. Expired objects are removed using a backward loop so that shifting list indexes do not skip unprocessed items. Fixed scene arrays store buildings and stars. These properties prevent unbounded accumulation; runtime performance still requires measurement.

## 6. File, class and function responsibilities

| Source | Main responsibility | Useful symbols |
|---|---|---|
| `BreathingCity.pde` | Processing lifecycle, input-mode routing, keyboard controls, panel/capture/log orchestration | `settings()`, `setup()`, `draw()`, `switchMode()`, `keyPressed()`, `LevelGraph` |
| `BreathInput.pde` | Device lifecycle and real microphone reading | `BreathInput.begin()`, `update(dt)`, `nextDevice()`, `stop()` |
| `SignalEnvelope.java` | Hardware-independent calibration, gate, normalisation and smoothing | `startCalibration()`, `update()`, `smooth()`, `adjustMargin()`, `adjustSensitivity()` |
| `CityScene.pde` | Procedural city/landmark/water rendering | `CityScene.display()`, `drawHarbour()`, `drawBridge()`, `drawOperaHouse()`, `CityBuilding`, `CityStar` |
| `VisualEffects.pde` | Rate-based spawning, event detection and collection lifetime | `VisualEffects.updateAndDraw()`, `addRipple()`, `BreathParticle`, `BreathWave` |

Important state: `raw` is the measured level; `noiseFloor` estimates the room; `margin` separates room sound from activity; `target` is the unsmoothed desired response; `intensity` is the smoothed envelope; `gateOpen` remembers gate state; `wavePhase` remembers water position; `LevelGraph.samples` is a fixed 240-value circular buffer; `emissionRemainder` preserves fractional particle emission; `sinceRipple` measures cooldown; `currentWave` allows peak strength updates.

## 7. Parameters worth adjusting

| Parameter / control | Default or bounds | Effect of increasing it |
|---|---|---|
| Sensitivity: `-` / `=` | 1.0; 0.25–8.0 | Smaller above-threshold sounds produce stronger visuals; saturation arrives sooner |
| Margin: `[` / `]` | 0.002; 0.0005–0.05; step 0.0005 | Requires louder input; reduces low-level activations but can hide gentle breathing |
| `0` | Reset gain and margin | Returns those two tuning values to defaults |
| `R` | Quiet recalibration | Re-estimates room noise; this is not a gain adjustment |
| `G` | Guided 60-second microphone test | Displays quiet, gentle, strong and recovery prompts; confirm actual participation before interpreting phase-labelled data |
| `ATTACK_SECONDS` | 0.10, source constant | Slower rise, less immediate response |
| `RELEASE_SECONDS` | 0.55, source constant | Longer fade back to calm |
| `FULL_SCALE_ABOVE_GATE` | 0.06, source constant | Requires more above-gate amplitude to reach full energy |
| Wave speed/amplitude ranges | See mapping table | Greater movement; excessive ranges can look restless |
| Particle/ripple caps | 180 / 8, source constants | More possible visual objects and higher rendering cost |

Tune in order: choose the right microphone, calibrate while quiet, raise margin only if the quiet room still activates, then adjust sensitivity until gentle/strong input separates. Record the settings and before/after readings instead of changing several parameters at once.

## 8. The three best video sections

Use [explainer-video-script.md](explainer-video-script.md): (1) `SignalEnvelope` with the short microphone setup, (2) `CityScene` energy mappings and integrated wave phase, and (3) `VisualEffects` bounds, expiry and ripple peak. Together these explain input interpretation, visual transformation and stable long-running state without touring every line.
