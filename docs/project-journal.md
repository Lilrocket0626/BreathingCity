# Project journal / 真实开发过程记录

**Recorded session: 1 October 2026.** Entries below document the assistant's work during this revision. They are not claims that the student performed those steps personally or that earlier dated development occurred. Runtime measurements are kept in the [runtime report](runtime-test-report.md) and evidence logs.

## J1 — Inspect and preserve the supplied version

**Observation:** The supplied sketch already contained procedural buildings, `AudioIn`, `Amplitude`, a three-second average calibration, attack/release interpolation, a particle cap and mouse simulation. Existing test rows were pending. The inherited documents described earlier dated work and tutor/course facts that were not available for verification.

**Action:** Preserve pre-edit code and documents in `archive/baseline-2026-10-01/`, including a checksum manifest. Use the active project directory for the final version.

**Reason:** A comparison needs actual before/after files. A polished inherited document is not a substitute for runtime evidence or a genuine student reflection.

**Evidence:** Baseline `.pde`, archived documentation, `SHA256.json`, [issue log](issue-log.md).

## J2 — Turn requirements into traceable changes

**Source-review findings:** Runtime sensitivity was fixed, generic rectangular buildings were insufficiently recognisable as Sydney, sea-wave speed was fixed, and ripple strength was captured close to the trigger crossing, making strong/weak rings too similar. Frame-based timing could vary with rendering performance.

**Decision:** Keep the existing Processing Java/Sound foundation. Add adjustable input conditioning, explicit microphone/simulation status, Sydney landmark geometry, elapsed-time visual motion and bounded effects. Split responsibilities across Processing tabs rather than introduce a second application framework.

**Evidence:** Final `.pde` tabs; the before/after concept maps reconstruct these two code structures from the files. They do not represent the student's historical mental state.

## J3 — Make input behaviour explainable

**Decision:** Separate raw RMS amplitude, estimated room level, gate threshold, normalised target and smoothed energy. Display the pipeline state so calibration and sensitivity can be diagnosed. Preserve a labelled synthetic mode to inspect graphics when a microphone is unavailable.

**Tradeoff:** This remains an amplitude-driven interaction. Noise conditioning can reduce small background activations but cannot tell breath from speech, music or a loud fan. A gain value that feels good on one device may not transfer unchanged to another.

**Evidence:** Input tab; [code walkthrough](code-walkthrough.md); actual runtime logs where available. Device-specific human breath testing must be recorded independently.

## J4 — Documentation and attribution correction

**Action:** Consult official Processing references, list exactly what each reference contributed, remove unverified earlier student/tutor/course claims from active documents, and mark course-source and peer-feedback gaps explicitly.

**Evidence:** [References](references.md), [AI log](ai-prompt-log.md), [declaration](genai-declaration.md), [course-source register](course-sources-needed.md), [peer form](peer-feedback-form.md).

## J5 — Completed software checks and demonstration

**Recorded results:** The real Processing 4.5.7 build with Sound 2.4.0 passed. The deterministic signal tests passed 11 cases with 547 assertions. The production-effects harness completed 324,012 assertions across 30 simulated minutes; observed counts stayed at or below 180 particles and 3 ripples (the configured ripple cap remains 8). Simulated duration is not 30 minutes of GUI/audio wall-clock performance.

**Runtime evidence:** The application rendered a labelled synthetic sequence used for demonstration. A separate live microphone capture produced changing RMS values without capture errors. A [180-second 1080p explainer](../video/BreathingCity_3min_Explainer.mp4) was produced with actual rendered demonstration footage, readable code sections and English synthetic narration; its file size is approximately 7.7 MiB. This is a project/implementation demonstration, not a student-voiced presentation or evidence of real breath actions.

**Evidence:** [Runtime report](runtime-test-report.md), `docs/evidence/`, [narration and shot list](explainer-video-script.md). Fresh-copy verification and the separate sustained GUI test were still in progress when this entry was written; the runtime report contains their final status.

## J6 — User-agreed guided microphone trial

**Participation status:** The user explicitly agreed to a one-minute guided trial. The app displayed quiet, gentle, strong and recovery prompts and completed its capture. At the time of this entry, the user had not yet confirmed whether every prompt was followed or whether the visual difference felt clear. Prompt labels therefore describe the requested action, not independently verified behaviour.

**Recorded environment and run:** Processing 4.5.7, Sound 2.4.0, default input device, no reported audio error; 62.005 seconds and 2,995 rendered frames. Mean recorded FPS was 50.376 and minimum 25.675 while video encoding ran concurrently. This loaded run is not an isolated performance benchmark. The calibrated floor was 0.001740.

| Prompted phase | Median RMS | Maximum RMS | Median energy | Maximum energy |
|---|---:|---:|---:|---:|
| Quiet | 0.00134 | 0.00250 | 0 | 0 |
| Gentle | 0.00206 | 0.00965 | 0.0182 | 0.1024 |
| Strong | 0.01716 | 0.18651 | 0.5715 | 1 |
| Recovery | 0.00164 | 0.11147 | 0.0106 | 0.999 |
| Complete | 0.00117 | 0.00178 | 0 | 0 |

**Interpretation with limits:** The recorded prompted periods show clear numerical separation between gentle and strong, and the final phase returned to zero. Gentle energy remained low for much of its interval; whether that feels sufficiently visible requires the user's observation. Recovery contains an early high energy value and a high raw input maximum, so the whole phase must not be described as uninterrupted silence. The logs alone cannot determine whether this was continuing input, timing of the user's actions or another sound.

**Next step:** Obtain the user's confirmation and qualitative observation, then decide whether a sensitivity change and controlled retest are useful. Preserve this first result even if settings are changed. It is not peer feedback, and it does not replace the five missing course sources.

For complete commands, raw logs and the final status of each test, read the [runtime report](runtime-test-report.md). The [runtime test instructions](runtime-test-instructions.md) are procedures, not results.

## Next real student entry — fill only after doing the work

Date / time / code version:  
What I tried before receiving help:  
What I personally changed and why:  
Exact failure / unexpected behaviour:  
Measured before result and evidence file:  
Measured after result and evidence file:  
What I can now explain without reading the guide:  
Peer feedback and what I did with it:  
Course source, page/time and how it changes my interpretation:  
Next question or remaining limitation:  

## Final regression and handover verification

A direct callback test exposed a guided-test state defect: N changed device while retaining the old trial phase. The first regression run failed. The final N handler cancels the trial and clears the graph; R also cancels a trial before recalibration. The same final production callbacks passed 10 cases / 1,017 assertions, with the before/after logs retained in `tests/`. An independent copy of the exact final five source files then compiled and ran for 24 seconds with actual screenshots and no missing assets.

The native rendered endurance run completed 600.014 animation seconds and 34,825 frames, with mean FPS 58.21, peak 180 particles and 3 ripples. The early/late telemetry FPS means were 57.46 / 57.79. Rendering, envelope and effects were unchanged during that run; the later R/N handler correction was separately tested. This is approximately ten minutes of GUI operation, distinct from the accelerated 1,800-second state test. Full values and limitations appear in `runtime-test-report.md`.

The final package preserves the 21 baseline files, source hashes, a complete source patch, original failed regression output, measured CSVs, runtime PNGs, code guides, concept diagrams and the 180-second synthetic-narrated video. Human action/visual confirmation, peer feedback and five genuine course sources remain separate evidence requirements.
