# Runtime dependencies and asset provenance

The final sketch needs Processing Java mode and the official Sound library. It draws the complete scene from code and does not load any image, audio, video, model, shader or font file. Internet access is needed to obtain the tools, not to run the sketch.

## Versions actually installed and used

| Software | Actual version | Role |
|---|---|---|
| Processing | 4.5.7, revision 1435 | Editor, Java preprocessor/compiler and renderer |
| Sound | 2.4.0, internal version 18 | AudioIn, Amplitude, Sound device configuration |
| Java | Temurin 17.0.20.1+1 bundled with Processing | Executes the compiled sketch; a separate JDK is unnecessary |
| JSyn | 17.1.0 supplied inside Sound | Sound's transitive audio engine; do not install separately |
| Host | macOS 26.6.2, build 25G83, arm64 | Actual tested platform |
| Audio backend | Sound's default JavaSound | Actual tested backend on Apple Silicon |

The exact Processing archive used was the official Apple Silicon portable ZIP. Other OS packages are available on the same release page but were not run in this test. Do not describe another version or OS as tested without a new result.

- [Processing 4.5.7 release](https://github.com/processing/processing4/releases/tag/processing-1435-4.5.7)
- [Exact Processing macOS arm64 ZIP](https://github.com/processing/processing4/releases/download/processing-1435-4.5.7/processing-4.5.7-macos-aarch64-portable.zip)
- [Sound 2.4.0 release](https://github.com/processing/processing-sound/releases/tag/v2.4.0)
- [Exact Sound ZIP](https://github.com/processing/processing-sound/releases/download/v2.4.0/sound.zip)

SHA-256 recorded from downloaded archives:

```text
Processing: 5753aa93611217ef0b6d58b38ce11927cd20c38ce47b03724aee95977b837c59
Sound:      3fd1296e93b4172d1b1a9fa087e56d42fd28e1d0764f478d14668e1673a6bfa2
```

The Processing hash matched its published release checksum. The Sound hash is the locally recorded archive digest; no separate upstream checksum comparison is claimed. Sound's `library.properties` supplied its version, and the Processing build used its bundled Java executable.

## Every runtime asset

| Item | Needed? | Source and contribution |
|---|---|---|
| Five files in `BreathingCity/` | Yes | Submitted source; all tabs must remain together |
| Sound library folder | Yes | Official external library, installed into the sketchbook |
| Microphone and OS permission | For microphone mode | Device supplies live RMS measurements; no recording file is created |
| Mouse | For mouse simulation | Horizontal position supplies a visual control value |
| City images or photographs | No | Skyline, Opera House shells and bridge are code geometry authored for the revision |
| Music, sound effects, recorded breath files | No | The sketch does not play audio or load audio assets |
| Fonts | No bundled font asset | Java logical `SansSerif` resolves through the Java/OS font environment |
| Video and documentation diagrams | No | Submission/study evidence; not loaded by the sketch |
| API keys, AI models, remote services | No | The finished artwork runs locally without an AI service |

Sources and acknowledgements apply to the actual artifact used. API usage follows official references; no stock art or downloaded tutorial scene is incorporated. The baseline and this revision are substantially AI-assisted. See [references](references.md) for APA 7 and contribution details, and [AI declaration](genai-declaration.md) for assistance disclosure.

## Optional development and video tools

These are not sketch dependencies. They are useful only to rebuild evidence.

- JDK 17+ for command-line tests; this session used Processing's bundled Temurin 17.0.20.1+1.
- Python 3 with Pillow for the previously produced video cards; media files are outside the current project package.
- FFmpeg/FFprobe 7.1.1 for H.264/AAC encoding, captions and validation.
- macOS `say`, Samantha voice, for synthetic English narration. The narration text remains under `presentation/subtitles/`; audio assets are not included in this package. This is not the student's voice.
- System Arial and Menlo fonts for presentation graphics; those fonts are not redistributed. Java `SansSerif` is used by the sketch itself.

The previously produced video used original runtime exports and code excerpts, with no external footage or music. It used labelled synthetic input and synthetic narration. The video and its authoring assets are not part of this project package.

## Optional evidence capture

Normal Processing use requires no environment variables. For an automated run launched through a Processing Java-mode command-line environment, the sketch reads:

| Variable | Value | Effect |
|---|---|---|
| BC_MODE | mic, mouse or demo | Initial input mode; omitted means mic |
| BC_RUN_DIR | Writable absolute directory | Saves numeric telemetry, selected screenshots and a JSON report |
| BC_DURATION | Positive seconds | Ends the run after this animation duration |
| BC_CAPTURE_FRAMES | 1 | Saves each rendered frame; demo uses a fixed 30 FPS animation clock |
| BC_GUIDED_TEST | 1 | Starts the live microphone guided trial after setup |

With `BC_RUN_DIR`, telemetry stores RMS and state values, not audio. Without it, no automatic numeric log is created. Pressing S still saves a screenshot. Captured frame export has disk/CPU overhead. `BC_DURATION` measures the sketch's clamped animation time; the report does not claim that this is identical to a stopwatch under long OS stalls. Developer tooling is optional and intentionally kept outside the normal README launch steps.

## Chinese video edition

The Chinese edition uses macOS Tingting synthetic Mandarin narration and Heiti SC presentation/caption text, with Menlo for source code. It reuses the actual Processing-rendered demo clip. Font binaries are not distributed. The script is `tools/build_video_zh.py`; all these tools remain optional authoring dependencies. The Chinese video and its authoring assets are not included in this package.
