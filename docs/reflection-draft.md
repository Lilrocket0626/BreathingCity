# Breathing City Critical Reflection

**Student:** Jiangpeng Huang

**Student number:** 14559823

**Subject:** 52685 Creative Coding

**Assessment:** A2 Code Prototype Project

## Reflective narrative

*Breathing City* began as a simple artistic proposition: make an invisible human action visible by allowing breath to animate a Sydney-inspired city. My initial concept map separated the project into broad categories such as input, data, visuals, interaction and testing. At that point, I understood the microphone mainly as a trigger. Developing the prototype changed that view. I came to understand interactive code as a chain of interpretations in which data is measured, filtered, mapped, stored and translated into visual behaviour. This reflection focuses on three critical moments in that change: controlling the project scope, turning unstable sound into usable data, and separating continuous animation from event-based behaviour.

The first important decision was to reduce the idea to a testable core. My A1 pitch included a skyline, colour, particles and breath interaction, but it did not yet define how these systems should be built together. The Week 7 seminar advised students to start small, add one feature at a time, test continuously and document each stage (University of Technology Sydney [UTS], 2026d). I therefore divided the prototype into a static city, microphone input, signal processing, visual responses and evidence. The first version used arrays, loops and a `Building` class to generate a repeatable skyline. A fixed random seed made the composition stable between runs, while `noise()` produced local variation in the windows. This mattered because randomness alone would make comparisons difficult. The A2 brief emphasises learning through substantial original code rather than surface complexity (UTS, 2026b). Building the city from shapes rather than imported images made the visual result simpler, but made the relationship between code and output much clearer.

The second critical moment was recognising that microphone amplitude is not the same thing as breath. `AudioIn` captures a stream and `Amplitude.analyze()` returns a changing sound level (Processing Foundation, n.d.-a, n.d.-b). If I mapped that number directly to colour and particle speed, room noise could keep the city active and small fluctuations could create visible flicker. I addressed this through a data pipeline. During a three-second calibration period, the program calculates an average background level and places a noise floor slightly above it. It then subtracts that floor, maps the remaining signal into a `0.0-1.0` range, constrains extreme values, and smooths changes with different attack and release rates. A faster attack allows an immediate response, while a slower release lets the city settle gradually.

This pipeline changed my understanding of data literacy. The amplitude reading is not neutral material that automatically contains meaning. Each operation encodes a design judgement about what should count as silence, a strong breath, or a visually satisfying response. The debug panel makes those judgements visible by displaying raw amplitude, the calibrated floor, mapped intensity and a recent-history graph. `map()` is therefore more than a mathematical convenience: it connects two different scales and makes one system legible to another (Processing Foundation, n.d.-c). The final concept map reflects this change by replacing the vague connection between “data” and “visuals” with explicit stages: input, calibration, mapping, smoothing, interpretation and output.

The third moment concerned the difference between a value and an event. The smoothed intensity should continuously control sky colour, moon glow, harbour height and particle motion. An expanding breath ring, however, should appear once when a breath begins. Creating a ring whenever intensity was above a threshold would add one on every frame. The solution uses state: `previousIntensity` stores the last value, and the code creates a ring only when the current value rises across the threshold. A cooldown adds a second Boolean condition to prevent repeated events from a noisy signal. This gave me a practical understanding of conditional logic. An `if` statement does not only classify a value; when combined with remembered state, it can recognise a transition over time.

The particle system extended this learning into object-oriented organisation. Each `BreathParticle` stores its position, velocity, lifetime, size, colour and noise offset, while the main sketch manages an `ArrayList` of particle objects. The loop runs backwards when removing expired particles so that deletion does not shift an unprocessed index. A maximum particle count protects performance. Shiffman's explanation of autonomous particle objects helped me understand why an object should combine state with behaviour instead of leaving every variable in the main sketch (Shiffman, 2024). Smooth Perlin-noise drift also supports the work's concept better than unrelated random jumps because it suggests moving air.

My evidence process has also revealed a limitation. The code has passed a structural syntax check, but live microphone behaviour still requires validation in Processing on my own computer. I prepared a test log, mouse-simulation fallback and peer-feedback form, but I have not yet completed the peer test. This is not a substitute for evidence, and the A2 checklist makes peer collaboration and accessible project documentation explicit submission responsibilities (UTS, 2026c). The gap shows why documenting only a polished final state is weak: it hides uncertainty and removes opportunities to learn from failure. Hatton and Smith (1995) distinguish description from deeper reflection that considers reasons, alternatives and wider consequences. In this case, critical reflection requires me to state what remains unverified rather than present planned behaviour as a measured result.

Generative AI substantially assisted the project under my tutor's written permission. ChatGPT helped generate and organise the code, comments, documentation, diagrams and drafts (OpenAI, 2026). Its advantage was speed: it could propose a complete architecture and expose concepts I needed to investigate. Its main disadvantage was false fluency. A polished class or explanation can look understandable before I can independently trace it. For that reason, my next step is not simply to submit the generated material. I need to run each version, explain the signal pipeline line by line, record actual values, gather peer feedback and revise the thresholds from evidence. The reflection guidance asks the writer to connect what happened, why it matters and what should happen next (UTS, 2026e). My “now what” is therefore concrete: verify the microphone, tune sensitivity, document one failed and one successful test, and publish a public repository whose history shows the prototype's stages. The most important change in my thinking is that creative code is not a shortcut from idea to image. It is an accountable process of modelling, testing and revising relationships between data, state and experience.

## References

Hatton, N., & Smith, D. (1995). Reflection in teacher education: Towards definition and implementation. *Teaching and Teacher Education, 11*(1), 33-49. https://doi.org/10.1016/0742-051X(94)00012-U

OpenAI. (2026). *ChatGPT* (September 17 version) [Large language model]. https://chatgpt.com/

Processing Foundation. (n.d.-a). *Amplitude*. https://processing.org/reference/libraries/sound/Amplitude

Processing Foundation. (n.d.-b). *AudioIn*. https://processing.org/reference/libraries/sound/AudioIn

Processing Foundation. (n.d.-c). *map()*. https://processing.org/reference/map_

Processing Foundation. (n.d.-d). *noise()*. https://processing.org/reference/noise_

Shiffman, D. (2024). *The nature of code*. No Starch Press. https://natureofcode.com/

University of Technology Sydney. (2026a). *52685 Creative Coding assessment item 1 code prototype pitch task* [Assessment brief].

University of Technology Sydney. (2026b). *52685 Creative Coding assessment item 2 code prototype project* [Assessment brief].

University of Technology Sydney. (2026c). *52685 Creative Coding A2 checklist* [Course checklist].

University of Technology Sydney. (2026d). *52685 Creative Coding week 07 seminar* [Seminar slides].

University of Technology Sydney. (2026e). *Creative Coding written critical reflection additional guidance* [Course guidance].

## Appendix plan

### Appendix A Project journal

Include `project-journal.md` or readable screenshots of the journal.

### Appendix B Initial and final concept maps

Include `concept-map-start.png` and `concept-map-final.png`.

### Appendix C Technical evidence

Include `data-flow.png`, selected code excerpts, the completed test log, and genuine runtime screenshots.

### Appendix D Peer and tutor feedback

Include the completed peer feedback form and any genuine tutor comments.

### Appendix E Declaration of GenAI use

Include `genai-declaration.md`, real screenshots showing prompts and outputs, and the tutor's written permission.
