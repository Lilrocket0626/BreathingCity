# Three-minute explainer: narration and shot list

This script describes the actual implementation. It does not claim the student personally authored or tested each part. The produced demonstration must label synthetic input and synthetic narration. For a final student submission, replace narration with the student's own verified explanation if required by the course.

## Narration (377 words; produced video timing)

Output: [BreathingCity_3min_Explainer.mp4](../video/BreathingCity_3min_Explainer.mp4), 180 seconds, 1920×1080, approximately 7.7 MiB. The narration is synthetic English speech; visual interaction footage is from the actual running sketch with labelled synthetic RMS input. [Narration text](../video/narration.txt) and [captions](../video/captions.srt) are retained.

### 0:00–0:20 — Project

Breathing City is a Processing artwork that connects sound intensity to a Sydney Harbour night scene. The bridge, opera-house shells, buildings, water and particles are drawn with code. The intended interaction uses a microphone: gentle input produces a quieter city, while stronger input produces brighter light and more motion.

### 0:20–0:45 — Core functions and evidence boundary

This demonstration uses labelled synthetic input in the running sketch. It shows calm, gentle, strong and recovery states, but it is not evidence of a person breathing into a microphone. Mouse simulation is also available. The real microphone path uses the Processing Sound library. It responds to loudness, so speech and other sounds can also activate it.

### 0:45–1:10 — Code focus 1a: input and calibration

The first code section is SignalEnvelope. AudioIn captures the selected input channel. Amplitude calculates the root mean square of each audio block and returns a level. During three seconds of calibration, the envelope collects room-noise readings and uses their ninetieth percentile. Staying quiet is important: sustained noise will raise this estimate.

### 1:10–1:28 — Code focus 1b: gate and gain

The opening threshold adds an adjustable margin to the noise floor. A lower closing threshold creates hysteresis, reducing rapid on-off switching. The signal above the opening threshold is multiplied by sensitivity and limited to zero through one.

### 1:28–1:46 — Code focus 1c: smoothing

Finally, exponential smoothing uses elapsed time. Its coefficient is one minus e to the power of negative delta-time divided by tau. Attack takes a shorter time constant than release, so the city responds quickly and settles gradually.

### 1:46–2:18 — Code focus 2: mapping energy into the city

The second section is CityScene. One smoothed energy value controls several visible ranges. Colour interpolation brightens windows, bridge lights and opera-house shells. Wave phase accumulates speed multiplied by elapsed time. Stronger input increases both wave speed and amplitude. Integrating phase avoids a sudden position jump when speed changes. This shared input makes the response coherent while each visual keeps its own scale.

### 2:18–2:48 — Code focus 3: bounded effects

The third section manages particles and ripples. Emission rate increases with energy, but particle count never exceeds one hundred and eighty. Ripples have a separate limit of eight. Each object expires, and backward removal avoids skipped entries. Ripple strength can rise after creation, preserving the difference between gentle and strong input instead of freezing strength near the trigger threshold.

### 2:48–3:00 — Close

The source, parameter guide, before-and-after files and test records accompany the project. Hardware-specific microphone checks and real peer feedback remain separate from this simulated demonstration.

## Shot list and exact code sections

| Time | Picture | Code to show | Purpose |
|---|---|---|---|
| 0:00–0:20 | Side-by-side actual runtime stills, labelled calm/strong | Title only | Establish the project and Sydney landmarks |
| 0:20–0:45 | Live panel; labelled synthetic sequence | Input-mode label must remain visible | Explain modes and avoid presenting synthetic input as microphone evidence |
| 0:45–1:10 | Presentation cards with exact input/calibration code excerpts | `BreathInput.begin()` and `SignalEnvelope.update()` calibration | RMS → room-noise estimate |
| 1:10–1:28 | Gate-code presentation card | `openingThreshold()`, `closingThreshold()`, `update()` | Gate state → bounded target |
| 1:28–1:46 | Smoothing-code presentation card | `SignalEnvelope.smooth()` | Elapsed-time attack/release → energy |
| 1:46–2:18 | Water and lighting code cards | `CityScene.pde`: `display()`, `drawHarbour()`, `drawShell()` | Connect a numerical change to lighting, wave amplitude and speed |
| 2:18–2:48 | Emission, expiry and ripple code cards | `VisualEffects.pde`: emission/update/removal and `BreathWave.updateAndDraw()` | Explain bounds, lifetime, event strength and stability |
| 2:48–3:00 | Evidence and disclosure card | No new code | Point to reviewable evidence and remaining tests |

## Recording/review checklist

- Use captures of the running Processing application, not an invented rendering presented as a screenshot.
- Keep the mode label visible whenever input behaviour is shown.
- Display code at a readable size and use only the three sections above; do not scroll through the entire program.
- When the video uses a still image, label it as a still rather than implying live movement.
- Identify synthetic narration in the video description/credits; do not imply it is the student's recorded voice.
- The exact runtime/library versions and test results come from the README and runtime report.
- Retain the narration text, captions and source capture provenance with the MP4.
