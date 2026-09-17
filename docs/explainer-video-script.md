# Breathing City Explainer Video Script and Shot List

Target duration: 2 minutes 50 seconds to 3 minutes 10 seconds. Record at 1080p and keep the finished MP4 below 300 MB.

## 0:00-0:25 Project overview

**Screen:** Start with the running artwork in a calm state, then breathe softly and strongly.

**Narration:**

Hi, I am Jiangpeng Huang, and this is *Breathing City*. It is an interactive Processing artwork that makes invisible breath visible through a Sydney-inspired night city. The laptop microphone measures sound intensity. A soft breath creates gentle light and motion, while a stronger breath warms the sky, brightens windows, raises harbour waves, increases particles and releases an expanding breath ring.

## 0:25-0:55 Core features

**Screen:** Show calibration, the live data panel, a soft breath, a strong breath, and mouse simulation.

**Narration:**

The main feature is not a single animation but a connected response system. When the sketch starts, it spends three seconds measuring room noise. The live panel then shows the raw amplitude, noise floor, mapped intensity and recent history. Most visuals respond continuously to intensity. A breath ring responds only when a new breath crosses a threshold. If microphone access fails, pressing M activates mouse simulation, which lets me test the complete visual system independently from the audio device.

## 0:55-1:45 Code focus one: signal pipeline

**Screen:** Zoom into `BreathInput.begin()` and `BreathInput.update()`. Highlight the relevant lines as they are explained.

**Narration:**

The first important code section is the `BreathInput` class. `AudioIn` opens microphone channel zero, and `Amplitude` analyses its level each frame. Raw sound is unreliable because every room has background noise. During calibration, I add the samples, count them, calculate their average, and multiply it by 1.35 to create a noise floor. After calibration, I subtract that floor from the live value. `map()` converts the useful range into zero to one, while `constrain()` prevents extreme values from exceeding that range. Finally, I use a faster interpolation rate when intensity rises and a slower rate when it falls. This attack-and-release smoothing keeps the response immediate without visible flicker.

## 1:45-2:20 Code focus two: event detection

**Screen:** Show `triggerBreathWave()` and then replay a ring appearing.

**Narration:**

The second section shows the difference between continuous data and an event. If I created a ring whenever intensity was above the threshold, the program would add one every frame. Instead, `previousIntensity` stores the earlier value. A Boolean condition checks whether the signal has just crossed upward over the threshold, and a second condition checks a 42-frame cooldown. Only when both are true is one `BreathWave` object added. This uses state to detect change over time.

## 2:20-2:50 Code focus three: particles and objects

**Screen:** Show `emitParticles()`, `updateAndDrawParticles()`, and the `BreathParticle` class.

**Narration:**

Particles are stored in an `ArrayList`. Each object manages its own position, velocity, lifetime, colour and Perlin-noise drift. The amount created depends on intensity, but `MAX_PARTICLES` prevents unlimited growth. I iterate backwards when deleting expired particles so that removing one item does not cause the next item to be skipped. This structure lets the main sketch manage the collection while each particle manages its own behaviour.

## 2:50-3:05 Conclusion

**Screen:** Return to a clean full-screen interaction and fade out on the title.

**Narration:**

Through this prototype, I learned to treat microphone input as data that must be calibrated, interpreted and tested, rather than as a direct trigger. The code connects data processing, state, conditions and object-oriented animation in one traceable system. Thank you.

## Recording checklist

- Replace every planned shot with genuine footage from the running Processing sketch.
- Keep code large enough to read; zoom in rather than showing the whole file.
- Record in a quiet room and use headphones.
- Speak naturally and do not rush the code explanation.
- Remove long pauses and failed takes.
- Export MP4 at 1080p; use HandBrake Fast 1080p30 if the file exceeds 300 MB.
- Name the video `Huang_Jiangpeng_14559823_TXX_BreathingCity.mp4`, replacing `TXX` with the real tutorial number.
