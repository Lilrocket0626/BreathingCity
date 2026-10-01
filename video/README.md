# Three-minute project and code explainer

中文版：[中文旁白、字幕与讲解画面](zh/BreathingCity_3min_Explainer_zh-CN.mp4) · [中文说明](zh/README.md)。

Open **`BreathingCity_3min_Explainer.mp4`** for the complete 180-second, 1920 × 1080 explanation. The video includes English synthetic narration and visible English captions. `captions.srt` is also provided for players or editing software.

The video introduces the project, demonstrates its visual response, then explains three code areas: the audio envelope, the city mappings, and bounded particles/ripples. It is a review aid prepared with AI assistance. The voice is macOS **Samantha**, not a recording of the student. The student should verify and understand the explanation, disclose the assistance, and record their own narration if the course requires personal presentation.

## What the footage proves

`assets/runtime-demo.mp4` is a continuous 24-second sequence created from **720 actual frames saved by the final Processing sketch**. Processing 4.5.7 and Sound 2.4.0 were used. The input mode is visibly labelled **AUTO DEMO / SYNTHETIC RMS**. Frames use a fixed 30 fps animation clock for reproducible capture; frame-export speed is not an interactive-performance measurement.

The sequence exercises calibration, calm, gentle, strong and recovery states. It demonstrates the rendering and signal-processing path with known synthetic values. It does **not** establish that a person breathed into a microphone, that microphone permissions were granted, or that a particular physical microphone is suitable. Follow the separate runtime report for hardware-test status. Intro images are labelled actual runtime **stills**; code cards are presentation graphics, not recordings of an editor.

No desktop or unrelated personal content was captured. No stock images, third-party footage, music, or recorded person’s voice were used. The scene is drawn by the submitted code. Presentation cards use system Arial and Menlo to render text; font files are not distributed and are not dependencies of the Processing sketch.

## Chapters

| Time | Content | Files explained |
|---|---|---|
| 00:00–00:20 | Project and calm/strong comparison | Actual runtime stills |
| 00:20–00:45 | Continuous labelled synthetic-input demonstration | Actual Processing frames, plus a final one-second hold |
| 00:45–01:10 | Microphone amplitude and calibration | `BreathInput.pde`, `SignalEnvelope.java` |
| 01:10–01:28 | Noise gate, hysteresis and sensitivity | `SignalEnvelope.java` |
| 01:28–01:46 | Attack/release exponential smoothing | `SignalEnvelope.java` |
| 01:46–02:18 | Water speed/amplitude and lighting | `CityScene.pde` |
| 02:18–02:48 | Emission limits, expiry and ripple peak | `VisualEffects.pde` |
| 02:48–03:00 | Evidence, remaining checks and disclosure | Project documentation |

The three strongest code topics for a personal three-minute recording are **(1) RMS → gate → smoothed energy, (2) energy → water/light, and (3) bounded effects with lifetime removal**. Exact displayed source text and line ranges are retained in `assets/source-excerpts.json`; source hashes are in `video-manifest.json`.

## Files

- `BreathingCity_3min_Explainer.mp4`: complete explainer, H.264/yuv420p + AAC, 30 fps.
- `captions.srt`: standalone captions; `captions.ass`: styled captions used in the MP4.
- `narration.txt`: exact spoken script; `narration.wav`: complete synthetic narration.
- `assets/runtime-demo.mp4`: short continuous actual-rendering demonstration.
- `assets/runtime-*.png`: stills extracted from that demonstration.
- `assets/01-*.png` … `12-*.png`: presentation cards with exact code excerpts.
- `assets/narration-*.txt` and `*.wav`: eight reproducible narration segments.
- `assets/capture-provenance.json`: capture method, frame count, sample frame hashes.
- `assets/source-excerpts.json`: displayed code text and line references.
- `video-manifest.json`: final format metadata, checksums and disclosure.
- `../tools/build_video.py`: reproducible video build script.

## Rebuild

Video creation is optional; none of these authoring tools are required to run the sketch. Use Python 3 with Pillow and FFmpeg/FFprobe. A first narration build uses macOS `say` with the installed Samantha voice; subsequent builds can reuse the included narration WAVs. The script looks for macOS Arial/Menlo fonts, with a DejaVu fallback on Linux. Appearance can differ with the fallback.

From the project folder, reuse the included runtime clip and narration:

```sh
python3 tools/build_video.py
```

To replace the demonstration with a new actual Processing capture:

```sh
python3 tools/build_video.py --frames /absolute/path/to/capture/frames
```

The frame directory must contain at least `000000.png` through `000719.png`, representing 24 seconds at 30 fps. Capture from the final sketch's documented developer evidence mode; do not substitute an invented image sequence and call it actual running evidence. Work files are created beside the project in `.tools/video-work`. Output is written to `video/`.

The original build used Python from the Codex artifact runtime, Pillow, FFmpeg 7.1.1 and the macOS 26.6.2 speech service. The FFmpeg command performs no audio recording and requires no microphone. In the Codex sandbox, macOS `say` produced an empty AIFF; generating narration through the approved host execution path resolved this authoring-only issue.

## Revision after video assembly

The main sketch's R/N handlers were subsequently corrected to cancel an in-progress guided trial when recalibrating or changing device. None of the displayed code excerpts or the visual/audio mappings changed. `video-manifest.json` preserves hashes at video-build time; `docs/evidence/final-source-sha256.json` identifies the final submitted source.
