# Breathing City project journal

This journal records the main design decisions, problems, tests and revisions visible in the preserved source files and evidence. The starting and final concept maps were reconstructed from code during the final revision, so they compare architecture rather than claiming to be drawings made on the original dates. Generative AI support is described separately in the [declaration](genai-declaration.md) and [activity log](ai-prompt-log.md).

## J1 — Clarifying the project goal

The starting idea was to use a laptop microphone to turn breathing into a visual Sydney Harbour scene. Early wording suggested that the program could detect human breathing. Reviewing the Processing Sound interface showed that this was too strong. `AudioIn` supplies an audio stream and `Amplitude.analyze()` returns an RMS sound level. The library does not identify the source or meaning of that sound.

The project goal was therefore revised to a testable claim: **Breathing City visualises microphone loudness, calibrated so that a nearby breath or blow can produce a noticeable response in an ordinary room.** Speech, music, wind and keyboard noise remain possible triggers. This limitation appears in the interface, README, video plan and written reflection.

The supplied version was preserved under `archive/baseline-2026-10-01/` before the active sketch was revised. This made it possible to compare the original single-file structure with the final five-file version.

## J2 — Stabilising the microphone signal

The baseline used a simple average-based calibration and a fixed response range. That approach could react continuously when the ambient room level changed. The revised signal pipeline separates five values:

1. `raw`, the RMS level reported by `Amplitude`.
2. `noiseFloor`, estimated from quiet calibration readings.
3. `gateOpen`, controlled by separate opening and closing thresholds.
4. `target`, the normalised and sensitivity-adjusted value from 0 to 1.
5. `intensity`, the attack/release-smoothed value used by the scene.

Calibration now collects at least three seconds of quiet readings and uses the 90th percentile, with a small minimum floor. The opening threshold is the noise floor plus an adjustable margin. The closing threshold uses only 55% of that margin. These two thresholds create hysteresis and reduce rapid switching near one boundary.

Sound above the opening threshold is scaled by sensitivity and divided by a defined full-scale range. The result is clamped from 0 to 1. A 0.10-second attack time constant lets the scene respond quickly, while a 0.55-second release lets it settle more gradually. Runtime controls allow recalibration, margin adjustment, sensitivity adjustment and input-device changes without editing the source.

## J3 — Mapping data into visual behaviour

The visual response is a creative mapping rather than a property contained in the audio. The final `energy` value controls several systems with different ranges:

- `lerpColor()` blends calm and active colours in the sky and landmarks.
- Building, bridge and Opera House lights become brighter.
- Wave phase advances faster and wave amplitude increases.
- Particle emission and upward speed increase, subject to a 180-particle cap.
- Ripple events record the strongest energy reached during an input event and expire after 2.3 seconds.

The final code separates responsibilities across `BreathInput`, `SignalEnvelope`, `CityScene`, `VisualEffects` and the main Processing tab. This separation made the signal logic testable without drawing a window and made the video explanation easier to organise around input, transformation and output.

## J4 — Testing and regression fix

The validation process combined real Processing builds, deterministic Java checks, rendered demonstrations and live microphone measurements. The signal-envelope checks passed 11 cases with 547 assertions. The effect-state harness completed 324,012 assertions across 1,800 simulated seconds while respecting the configured bounds. A rendered run completed 600.014 animation seconds with an average of 58.21 FPS and no progressive decline in the recorded early and late samples.

Testing also found a real state-management problem. Pressing `N` during a guided microphone trial changed the input device but retained the old trial phase and graph history. This could display a misleading state after reconnection. The handler was changed so `N` cancels the active trial and clears the graph. `R` now also cancels a trial before recalibration. The original failing record was retained, and the corrected callbacks passed 10 cases with 1,017 assertions.

The live guided run recorded different numeric levels across the prompted quiet, gentle and strong phases. These measurements show that the microphone path responded, but the phase labels only record requested actions. They do not independently prove that every sound was a human breath. This evidence boundary is kept in the [runtime report](runtime-test-report.md).

## J5 — Responding to feedback

The tutor asked for individual pieces of code to be explained instead of showing only the final animation. Detailed comments were therefore added across the five production files. The comments explain variable roles, function responsibilities, state changes, thresholds and the reason for bounds. The final video plan follows the data flow from `AudioIn` and RMS measurement, through `SignalEnvelope`, into `CityScene` and `VisualEffects`.

Class feedback raised the possibility that room noise could repeatedly trigger the city. The response was to make calibration, threshold margin, sensitivity, hysteresis and attack/release behaviour visible and adjustable. The remaining limitation was not hidden: amplitude conditioning improves stability but cannot classify breath.

## J6 — Final interpretation and next step

The main learning outcome was a change from treating code as a visual effect to treating it as a chain of measurements, states and decisions. A bright city does not prove that the program interpreted the sound correctly. Each claim needs evidence that matches its scope. Automated tests can verify formulas, transitions and collection bounds. They cannot evaluate whether a participant experiences the work as breathing-sensitive.

A useful next test would compare at least two microphones in quiet and moderately noisy rooms. For each setup, the noise floor, threshold, sensitivity, gentle input range and strong input range should be recorded before making one tuning change at a time. Participant comments should then be compared with the numerical evidence. If the project later aims to distinguish breathing from speech or music, RMS amplitude alone will be insufficient and the project will need additional audio features or classification methods.

## Evidence summary

| Evidence | Recorded result | Interpretation boundary |
|---|---|---|
| Processing build | Pass with Processing 4.5.7 and Sound 2.4.0 | Tested environment only |
| Signal envelope | 11 cases, 547 assertions | Formula and state behaviour, not sound-source identity |
| Control callbacks | 10 cases, 1,017 assertions after fix | Callback logic, not physical keyboard delivery |
| Effect-state stress | 324,012 assertions | Simulated state time, not 30 minutes of rendered use |
| Rendered endurance | 600.014 seconds, mean 58.21 FPS | One tested Mac and workload |
| Guided microphone run | 62.005 seconds recorded | Prompt labels do not independently verify the sound source |

Detailed commands, measurements and raw evidence are listed in the [runtime test report](runtime-test-report.md), [issue log](issue-log.md) and `docs/evidence/` folders.
