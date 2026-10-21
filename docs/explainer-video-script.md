# Three-minute explainer video script

This narration follows the 12-slide English code-explanation deck. Jiangpeng Huang records the final narration. The timing is a guide, so brief pauses can be used when changing slides or showing the running prototype.

## Slide 1 — Breathing City (00:00–00:12)

Hello, I'm Jiangpeng Huang. Breathing City is an interactive Processing artwork that turns sound intensity into a changing Sydney Harbour night scene.

## Slide 2 — Visible response (00:12–00:32)

This is a guided live-microphone run. The program requests quiet, gentle and strong input, and the recorded microphone levels change across those phases. As the level rises, the city brightens, the water moves faster, and particles and ripples increase. The prompts show requested actions; they do not identify the exact sound source.

## Slide 3 — Microphone input (00:32–00:46)

`BreathInput` reads the microphone. `AudioIn` opens the selected channel, and `Amplitude` returns one RMS value for each audio block. That value represents current loudness. It does not recognise breathing, so speech, music or wind can also activate the artwork.

## Slide 4 — Noise calibration (00:46–01:02)

The program first records three seconds of quiet room noise. It sorts those readings and uses the 90th percentile as the noise floor. This reduces false triggers from ordinary background sound. I can press R to repeat calibration after changing the room or device.

## Slide 5 — Threshold and sensitivity (01:02–01:17)

The gate opens above the noise floor plus a margin and closes at a lower level. These two thresholds create hysteresis, which prevents rapid on-and-off switching near one boundary. Sensitivity changes how strongly above-threshold sound affects the scene.

## Slide 6 — Attack and release (01:17–01:32)

The code maps sound above the opening threshold to a target from zero to one. A 0.10-second attack time constant responds quickly, while a 0.55-second release lets the city settle gradually.

## Slide 7 — Light and colour (01:32–01:46)

`CityScene` receives the processed energy value. `lerpColor` blends calm and active colours. The same value brightens windows, bridge lights and the Opera House, creating a coordinated response.

## Slide 8 — Wave motion (01:46–02:01)

Energy also changes wave speed and amplitude. The code adds speed multiplied by elapsed time to `wavePhase`. Updating phase gradually keeps the water continuous when the input changes.

## Slide 9 — Particle emission (02:01–02:15)

`VisualEffects` turns energy into a particle emission rate. Stronger input creates particles faster, but the code limits the total to 180 so the collection cannot grow without a bound.

## Slide 10 — Object lifetime (02:15–02:28)

Each particle loses life every frame. The loop removes expired particles backwards, so changing the `ArrayList` does not make the code skip the next item.

## Slide 11 — Ripple strength (02:28–02:42)

Each ripple tracks the strongest energy reached during one input event. This preserves the difference between gentle and strong input. Ripples expire after 2.3 seconds and the collection is capped at eight.

## Slide 12 — Running the project (02:42–03:00)

The project runs in Processing Java mode with the Sound library. Its main limitation is that it detects loudness rather than breath itself, so other sounds can also activate it. Building it helped me understand how measured input becomes visual behaviour. My AI use is declared in the written reflection. Thank you.

## Evidence and source locations

| Slides | Repository source |
|---|---|
| 1–2 | `README.md`, `docs/evidence/human-trial-01/` and `docs/evidence/demo/` |
| 3 | `BreathingCity/BreathInput.pde` |
| 4–6 | `BreathingCity/SignalEnvelope.java` |
| 7–8 | `BreathingCity/CityScene.pde` |
| 9–11 | `BreathingCity/VisualEffects.pde` |
| 12 | `docs/runtime-dependencies.md`, `docs/genai-declaration.md` |

When recording, keep code readable, show the input-mode label whenever the prototype is visible, and do not describe simulated input as microphone evidence.
