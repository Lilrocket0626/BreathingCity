# Issue and change log

Date: 1 October 2026. **Source observations are distinct from runtime results.** The full original files are in `archive/baseline-2026-10-01/`; the final sketch is in `BreathingCity/`. Do not infer historical commits from these snapshots.

| ID | Baseline observation / requirement gap | Revision and rationale | Evidence / verification boundary |
|---|---|---|---|
| I01 | Noise calibration used mean × 1.35, with fixed response range | Separate `SignalEnvelope`: percentile estimate, explicit margin and sensitivity controls | Compare old `BreathInput.update()` with `SignalEnvelope.update()`. Actual room accuracy needs microphone testing |
| I02 | One visual level, fixed-frame smoothing; no runtime gain/margin controls | Hysteresis and exponential attack/release using elapsed seconds; margin/gain/reset keys | Formula and deterministic test evidence in runtime report; not a breath classifier |
| I03 | Rectangular skyline had no clear Sydney landmark | Add code-drawn Harbour Bridge and opera-house shells | `CityScene.pde`, actual screenshots; human recognition should be assessed with peer feedback |
| I04 | Wave amplitude changed but speed used a fixed `frameCount * 0.025` | Integrate phase with energy-dependent speed and `dt`; amplitude also changes | `CityScene.display()` and `drawHarbour()` |
| I05 | Ripple strength fixed at first `0.18` crossing | Track active event peak; use rearm/cooldown and controlled repeat during strong input | `VisualEffects.updateAndDraw()`. Baseline could store ≈0.183 versus ≈0.24 at two different onset targets; those are source-derived illustrative values |
| I06 | Particle count bounded, but emission/motion and wave cooldown tied to frames; no explicit ripple count cap | Time-based rates/lifetimes, particle cap 180, ripple cap 8, backward expiry removal | Code enforces bounds. A hardware endurance run is separate evidence |
| I07 | Default microphone startup only; little support for device diagnosis | Select input-capable devices; next-device and reconnect controls; report raw/zero/clipping/error state | `BreathInput.pde`; OS permissions and a real device remain external dependencies |
| I08 | One large source file made explanation and signal testing harder | Separate lifecycle, real audio, pure Java signal envelope, scene and effects | Processing loads all tabs from the same sketch folder |
| I09 | Old documentation asserted unverified student experiences, dates, course sources and tutor permission | Preserve in archive; replace active text with verified session facts and marked evidence gaps | Journal, reflection, references, AI declaration |
| I10 | No established fresh-download handover evidence | Provide explicit setup, versions, evidence logs and a fresh-copy test procedure | Read actual runtime report for what was performed, not just this plan |

## Append actual runtime problems here or in the runtime report

Record timestamp, version, command/action, exact error, reproduction, fix, retest result and evidence filename. Do not delete failed attempts. A useful entry distinguishes a corrected software defect from a blocked OS permission or a test still awaiting the user's physical input.

## Guided test invalidated by device or calibration change

**Observed:** the before-fix callback regression failed because N retained `guidedTest` and graph history after changing input. **Changed:** N cancels the trial/clears history; R cancels the trial before a fresh calibration. **Verified:** final 10 callback cases / 1,017 assertions passed; before and after outputs are preserved in `tests/control-test-record.txt`. Actual OS keyboard delivery is outside this callback test.
