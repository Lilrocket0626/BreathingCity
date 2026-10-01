# Actual build and runtime test report

**Date:** 1 October 2026. **Project:** Breathing City 2.0. **Operator:** assistant-controlled tool runs; a guided human trial was requested after the user explicitly agreed. This report distinguishes code execution, synthetic input, live sound capture and participant-confirmed actions.

## Environment actually used

Processing 4.5.7 (revision 1435), Java mode, official Sound 2.4.0 (revision 18), bundled Temurin Java 17.0.20.1+1, JSyn 17.1.0, macOS 26.6.2 arm64, default JavaSound backend. Window: 1280×720 JAVA2D, pixel density 1. The real input was selected as **Default Audio Device**; its underlying physical microphone was not independently identified.

Official binaries were downloaded into a task-local tools directory. Global Processing settings were not modified. Versions/hashes are in [runtime environment](evidence/runtime-environment.json) and [dependencies](runtime-dependencies.md). Initial native GUI initialization failed in the execution sandbox; the authorized native host execution path compiled and ran successfully. This was a tooling environment restriction, not a sketch syntax error.

## Reproducing one complete run from the beginning

1. **Preserve the original:** the supplied sketch and 20 companion documents/assets were copied before editing to `archive/baseline-2026-10-01`. Every archived file still matches its SHA-256 manifest.
2. **Install the stated versions:** obtain Processing and Sound from the official pinned releases in the dependency document. The normal human setup is described in the root README. For these measurements, isolated Processing preferences pointed to the task-local sketchbook containing Sound.
3. **Open/build the final sketch:** the Processing Java-mode compiler consumed `BreathingCity/BreathingCity.pde` and the other four tabs. Baseline and revised builds completed with exit 0. No fake Processing/Sound stubs were used for compilation.
4. **Run a known input sequence:** launch auto-demo mode, remain in the labelled synthetic path, and observe calibration, calm, gentle, strong and recovery. The actual renderer exported five stage screenshots plus the 721-frame capture used for video preparation.
5. **Open real input:** a separate 24-second microphone run enumerated input devices, selected the default, calibrated and produced varying RMS values without a capture exception. No audio was saved.
6. **Invite a human trial:** the user wrote “可以参与一次约 1 分钟的真人测试”. The next run displayed timed instructions: 0–10 seconds quiet, 10–25 gentle, 25–40 stronger input, 40–55 stop/quiet, 55–60 complete. The program recorded 62 seconds, with numeric phase labels and actual screenshots. Confirmation of compliance and perceived clarity is a separate record below.
7. **Check settling and limits:** inspect the telemetry, screenshots and tests. The guided run returned to intensity zero near the end. The deterministic tests exercised envelope behaviour and simulated extended effect lifetimes.
8. **Verify an independent copy:** copy the project to a separate path and use Processing to build/run its own five source files. This checks missing assets and source-folder assumptions. It does not emulate a clean OS, another computer or a human clicking through the library manager.
9. **Check sustained rendering:** run the native graphical program for approximately ten minutes with no per-frame PNG export. The results and exact source scope are below.

Normal users only need the root README's Processing editor steps. Developer capture uses `BC_MODE`, `BC_RUN_DIR`, `BC_DURATION`, `BC_CAPTURE_FRAMES` and optionally `BC_GUIDED_TEST`, documented in [dependencies](runtime-dependencies.md). CSV sampling is about 4 Hz; reported peaks are sampled peaks, not maxima of every audio sample.

## Recorded synthetic and live runs

| Run | Observed result | Evidence and limit |
|---|---|---|
| Baseline and revised compilation | PASS, real Processing Java compiler, exit 0 | Source structure and Sound API compatibility; no assertion about another OS |
| Captured synthetic sequence | 24.033 animation seconds; 721 rendered frames; particles ≤180, ripples ≤3 | [Demo evidence](evidence/demo/run-report.json); fixed 30 FPS animation clock, actual PNG export |
| Live capture probe | 24.016 seconds; varying RMS; available=true; no reported capture error; average 59.08 FPS after warm-up | [Microphone report](evidence/microphone/run-report.json); not labelled human actions |
| Guided microphone acquisition | 62.005 seconds; 2,995 rendered frames; no reported capture error; average 50.38 FPS, minimum 25.67 | [Guided raw report](evidence/human-trial-01/run-report.json); video encoding ran concurrently, load was not isolated |
| Independent copy | PASS, compile and 24-second native run | [Fresh-copy reproduction](evidence/fresh-copy-final/reproduction-report.json); same host/library, synthetic input |
| Control callback tests | PASS, 10 cases / 1,017 assertions, with a real pre-fix failure retained | [Before/after record](../tests/control-test-record.txt); actual keyPressed callback, hardware adapter stub, no physical key events |
| Envelope tests | PASS, 11 cases and 547 assertions | [Test result](../tests/test-results-2026-10-01.txt), actual SignalEnvelope source |
| Effect-state stress | PASS, 324,012 assertions; 1,800 simulated seconds; maxima 180 particles / 3 ripples | Actual compiled effect classes; pixel sink only; not a real 30-minute GUI run |

The captured demo's average 28.29 FPS includes writing every 1280×720 PNG. It must not be compared directly with the ordinary 60 FPS target. Fresh-copy and endurance runs do not export every frame.

## Guided human trial measurements

**Participant-confirmation status: awaiting the user's confirmation that all requested actions were followed and that the visual differences were clear.** Agreement to participate and phase labels alone do not prove which physical action generated a sample.

Calibration estimate: `noiseFloor = 0.001740`; default margin `0.002`, opening threshold `0.003740`, sensitivity `1.0`.

| Requested phase | RMS median | RMS sampled max | Intensity median | Intensity sampled max |
|---|---:|---:|---:|---:|
| Quiet | 0.00134 | 0.00250 | 0.0000 | 0.0000 |
| Gentle input | 0.00206 | 0.00965 | 0.0182 | 0.1024 |
| Stronger input | 0.01716 | 0.18651 | 0.5715 | 1.0000 |
| Stop/recovery | 0.00164 | 0.11147 | 0.0106 | 0.9990 |
| Complete | 0.00117 | 0.00178 | 0.0000 | 0.0000 |

These are measured values, not example values or invented calibration data. The phases show a substantial numerical contrast. Gentle input is relatively subtle; the participant should assess whether it is sufficiently visible before deciding to increase sensitivity. No tuning change was made merely to produce a more impressive screenshot.

The recovery period contains further loud input near seconds 41–42 and smaller above-gate samples later. Therefore it cannot be interpreted as fifteen seconds of uninterrupted silence. Intensity reaches zero by the sampled row near 50 seconds and remains zero in the final complete phase. A release-time claim should use the controlled envelope tests or an independently confirmed silent interval.

Actual live screenshot: [strong-stage prompt and measured response](evidence/human-trial-01/guided-strong.png). Other stage images and the original [CSV](evidence/human-trial-01/telemetry.csv) remain in the same folder. The JSON's conservative `evidence_limit` field does not automatically certify human actions; this report and participant confirmation supply the interpretation.

## Sustained graphical run

**PASS for the observed run.** The actual native graphical program completed 600.014 animation seconds and 34,825 rendered frames, then exited normally. Mean FPS after warm-up was **58.21**, with a minimum sampled by the sketch of **22.74**. Particles never exceeded **180**; ripples peaked at **3**. No per-frame image export was enabled.

Mean telemetry FPS over seconds 30–90 was **57.46**, versus **57.79** over seconds 510–570. This run does not show progressive FPS decline. Sampled JVM heap use ranged from **24.50 to 258.56 MiB**, varying as allocation and garbage collection occurred. These samples are not a retained-heap/leak analysis. Some independent compilation/copy runs occurred concurrently, so this is a practical loaded-session check rather than an isolated benchmark.

[Raw run report](evidence/soak/run-report.json) · [4 Hz telemetry](evidence/soak/telemetry.csv) · [Summary calculations](evidence/soak/analysis.json).

This was approximately ten minutes of actual rendered operation, plus a separate thirty-minute **simulated** state test. It is not a thirty-minute physical GUI endurance claim. The tested rendering/envelope/effect sources remained unchanged; the later R/N handler fix was separately tested against the exact final build.

## Controls and revision checks

A callback review identified a real state bug after guided tests were added: changing microphone with N during a guided trial retained the old trial phase. The final handler cancels the trial and clears the graph when changing device. Recalibrating with R also cancels a guided trial; G starts a fresh one. The test records distinguish direct callback verification from physical keyboard/OS event delivery.

Physical desktop keyboard automation could not attach to the temporary Java application through the available UI interface, so it is not represented as a passed keyboard test. Normal key routing uses Processing's `keyPressed()` callback; participant testing on the final demonstration computer should still exercise M, R, N, D, H and S.

The captured video and sustained run exercise unchanged rendering, audio-envelope and effect code. A later keyboard-state fix affects only R/N cancellation of an active guided trial. Final source checksums and the fresh-copy/callback checks identify the delivered revision; earlier raw evidence is retained rather than silently rewritten.

## Screenshots and three-minute video

- [Calm](evidence/demo/02-calm.png), [gentle](evidence/demo/03-gentle.png), [strong](evidence/demo/04-strong.png), [recovery](evidence/demo/05-recovery.png): actual Processing-rendered synthetic-input states.
- [Guided live microphone screenshot](evidence/human-trial-01/guided-strong.png): actual microphone input and on-screen requested action.
- [Three-minute video](../video/BreathingCity_3min_Explainer.mp4): 180 seconds, 1920×1080, H.264/AAC, about 7.7 MiB. Full decode succeeded. It contains actual rendered demo footage, exact source excerpts, captions and clearly disclosed synthetic English narration.
- [Video validation](../video/video-validation.json): encoding, duration, excerpt and visual checks. No human listening test is claimed.

## Acceptance boundary and remaining evidence

The code builds and runs on the tested Mac with the actual stated library versions, captures live RMS and presents labelled simulation. Numeric tests, code bounds, rendered sequences and independent-copy verification support software correctness within their recorded scopes.

Still required from the student/course: confirm the guided actions and qualitative result, record any personal tuning revision, collect real peer feedback and provide at least five genuine course sources. The reflection remains an evidence-based working document with explicit gaps. Public technical references do not satisfy the course-source requirement by themselves. No peer response, tutor permission, student learning experience, clean-OS installation or untested-platform compatibility has been invented.
