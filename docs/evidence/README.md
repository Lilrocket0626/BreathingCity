# Actual runtime evidence

These files were produced by running the submitted Processing code. Input mode and provenance matter: a screenshot of a rendered simulation proves rendering, not microphone or human-breath performance.

- `runtime-environment.json`: official software versions and downloaded archive hashes.
- `demo/`: actual Processing PNG exports, 4 Hz numeric telemetry and run report for a labelled synthetic-RMS sequence. Full frames were used for the video.
- `microphone/`: a 24-second live capture-path probe. Input was not annotated as any human action.
- `human-trial-01/`: a live microphone run after the user agreed to a guided one-minute test. `guided_phase` indicates the requested action. Participant confirmation is recorded separately in the runtime report; phase labels do not automatically prove compliance.
- `fresh-copy/`: initial independent-copy run; `fresh-copy-final/`: exact final source after the guided-state regression fix, rebuilt and rerun on the same host.
- `soak/`: sustained rendered-run measurements, distinct from the accelerated state tests.
- `source-changes.patch`: complete source changes from the preserved baseline.
- `final-source-sha256.json`: source checksums for matching submitted code to evidence.

No microphone waveform or audio recording is saved. CSV files contain only sound-level/state samples. The 4 Hz telemetry can miss brief instantaneous RMS peaks; its maximum is a sampled maximum.

The automatically written JSON field `evidence_limit` is conservative and does not certify the participant's actions. For the guided run, combine CSV phase labels, actual screenshots, the user's confirmation and the interpretation in [runtime-test-report.md](../runtime-test-report.md).

The frame-export run uses a fixed animation clock and saves every frame, so its FPS is not an ordinary-interaction benchmark. Fresh-copy/soak runs use elapsed time. Full baseline files and unverified inherited claims remain isolated in `archive/`, outside this current evidence folder.
