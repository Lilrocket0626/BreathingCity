# References and contribution register

Verified against the linked primary sources on 1 October 2026. These are **public technical references**. None has been verified as a prescribed course reading. The separate five-course-source requirement is still recorded in [course-sources-needed.md](course-sources-needed.md).

## APA 7 reference list

Oracle. (n.d.). *System: nanoTime*. Java Platform, Standard Edition 17 API specification. https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/lang/System.html#nanoTime()

Processing Foundation. (n.d.-a). *Amplitude*. https://processing.org/reference/libraries/sound/Amplitude

Processing Foundation. (n.d.-b). *AudioIn*. https://processing.org/reference/libraries/sound/AudioIn

Processing Foundation. (n.d.-c). *frameRate()*. https://processing.org/reference/frameRate_

Processing Foundation. (n.d.-d). *lerpColor()*. https://processing.org/reference/lerpColor_

Processing Foundation. (n.d.-e). *map()*. https://processing.org/reference/map_

Processing Foundation. (n.d.-f). *millis()*. https://processing.org/reference/millis_

Processing Foundation. (n.d.-g). *noise()*. https://processing.org/reference/noise_

Processing Foundation. (n.d.-h). *Sound*. https://processing.org/reference/libraries/sound/Sound

Processing Sound contributors. (n.d.). *Processing Sound library* [Computer software]. GitHub. Retrieved October 1, 2026, from https://github.com/processing/processing-sound

Use the same `n.d.-a` to `n.d.-h` suffixes in text; they distinguish undated works by the same author. The exact installed software versions belong in the README and runtime report; the generic documentation pages do not establish which version was actually tested.

## What each source contributed

| Source | Specific use in this revision | Extent of reuse |
|---|---|---|
| Amplitude | Verified that `analyze()` measures block RMS amplitude; verified `AudioIn → Amplitude.input()` wiring | Standard API setup follows the official example's pattern. No substantial tutorial program was imported |
| AudioIn | Verified input channel argument and the difference between `start()` and `play()` | `start()` captures without microphone playback, avoiding an unnecessary audio feedback path |
| frameRate() | Confirmed that the requested frame rate is a target, not a guarantee | Motivated elapsed-time animation and separate performance measurements |
| lerpColor() | Confirmed interpolation between calm and active colours | Used for sky, landmark and particle colours; revised windows respond through opacity and fixed activation thresholds |
| map() | Confirmed range mapping does not itself clamp values | Consulted when reviewing baseline mappings; final normalisation uses explicit division and clamping rather than calling `map()` |
| millis() | Confirmed elapsed milliseconds in the inherited code | Consulted to understand the baseline; the revision uses monotonic `System.nanoTime()` deltas instead |
| System.nanoTime() | Verified elapsed-time measurement in Java | The main sketch converts nanosecond differences to seconds for `dt`; the consulted API page is not a claim that Java 17 is the actual tested runtime |
| noise() | Confirmed smooth spatial variation | Used for particle drift; the revised window pattern uses seeded, fixed random thresholds |
| Sound | Verified device enumeration and input-device selection | Used for selecting an input device and reporting available devices |
| Processing Sound repository | Installation route, library implementation and project provenance | Runtime dependency; install its official distribution. The sketch does not vendor the library source |

The Processing reference pages report a CC BY-NC-SA 4.0 licence; the Sound repository reports LGPL 2.1. This project links to the originals and uses short API patterns. No full reference pages or tutorial artworks are redistributed.

## Artwork, inherited code and AI contributions

- The starting sketch and documents were supplied in the workspace and described by the user as ChatGPT-generated. Their earlier creation dates, claimed course experiences and tutor permissions were not independently verified. Their exact pre-edit contents remain under `archive/baseline-2026-10-01/`.
- The current revision retains the starting idea and procedural skyline/audio/particle structure, with AI-assisted changes to input handling, controls, Sydney landmarks, animation timing, resource bounds and documentation. See [project-journal.md](project-journal.md) and [issue-log.md](issue-log.md).
- The artwork uses procedural geometry: no downloaded photographs, textures, sprites, music, prerecorded breath sample or external font file is required to run the sketch. Bridge and shell-like opera-house forms are stylised code drawings, not scans or traced images.
- The concept maps were generated for this revision from the code and requirements. They are not historic records of the student's private thought process.
- Generated demonstration narration, if included in the video, must be described as synthetic speech. Recorded simulation footage demonstrates the running graphics, not successful human breathing recognition.
- No source of inherited code can be identified more precisely than the supplied archive and the user's description. Do not claim a tutorial was used simply because it appears in an old draft bibliography.
