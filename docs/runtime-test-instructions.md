# Required Runtime Test

The source has passed a local structural syntax check against the Processing APIs used by the project. The Sound library and live microphone still need to be tested in the real Processing application on Jiangpeng's computer.

## Test procedure

1. Install Processing 4 and the official Sound library.
2. Open `BreathingCity/BreathingCity.pde` and press Run.
3. Take one screenshot while the screen says `CALIBRATING`.
4. Stay quiet until the screen changes to `CALM`.
5. Record the displayed `noise floor` value.
6. Breathe softly three times and note the approximate mapped intensity.
7. Breathe strongly three times and note the approximate mapped intensity.
8. Press `M`, move the mouse from left to right, and confirm that every visual system changes.
9. Press `D` and `H` to test the interface toggles.
10. Press `S` and confirm that a PNG is saved.

## Evidence to retain

- Screenshot: calibration
- Screenshot: calm state
- Screenshot: soft breath
- Screenshot: strong breath
- Screenshot: simulation mode
- Short screen recording showing one complete interaction
- Any Processing error messages

Place evidence in `docs/evidence/` and complete the corresponding rows in `docs/test-log.csv`.

## Results to send back

- Does the sketch open successfully?
- What noise-floor value appears?
- Approximate intensity for a soft breath:
- Approximate intensity for a strong breath:
- Does the animation feel too sensitive, too weak, or appropriate?
- Attach screenshots and any error message.
