# Breathing City - Project Journal

Student: Jiangpeng Huang  
Subject: 52685 Creative Coding  
Assessment: A2 Code Prototype Project

This journal records factual development evidence. Before using an entry in the final reflection, add your own genuine reactions, decisions, difficulties, and learning in the marked sections.

## Entry 1 - Project scope and visual foundation

Date: 10 September 2026

### Goal

Define a realistic core prototype and separate it into testable parts.

### Work completed

- Confirmed the project title: *Breathing City*.
- Defined the interaction: microphone amplitude will influence a generative Sydney-inspired night city.
- Limited the core feature set to calibrated sound input, smooth intensity, city lighting, breath waves, and particles.
- Created a first Processing sketch containing a procedurally generated skyline, gradient sky, windows, moon, and harbour.
- Chose to draw all visual elements with code instead of using downloaded images. This increases the original code contribution and removes asset licensing problems.

### Technical concepts used

- Arrays and `for` loops create multiple building objects.
- A `Building` class groups building data and display behaviour.
- `map()` and `lerpColor()` produce the sky gradient.
- `noise()` makes window lighting varied but visually coherent.
- `randomSeed()` keeps the generated layout reproducible.

### Evidence

- `BreathingCity/BreathingCity.pde`
- `docs/concept-map-start.svg`
- Git commit for Stage 1

### Your genuine reflection - complete after running Stage 1

- What surprised you?
- Which part did you understand immediately?
- Which part was confusing?
- What would you change after seeing the sketch run?

### Next step

Install the Processing Sound library, capture microphone amplitude, and display raw and smoothed input values in a debug panel.

---

## Entry 2 - Sound data and responsive systems

Date: 10 September 2026

### Goal

Connect the microphone to multiple visual systems without allowing background noise to make the artwork flicker.

### Work completed

- Added `AudioIn` and `Amplitude` from the Processing Sound library.
- Added a three-second calibration stage that estimates the room's noise floor.
- Subtracted the noise floor from the raw amplitude and mapped the remaining signal to a constrained `0.0-1.0` intensity value.
- Used different smoothing rates for attack and release so the city responds quickly but returns to calm gradually.
- Connected the shared intensity value to the sky, moon, building windows, harbour, particles, and waves.
- Added a threshold-crossing test and cooldown for wave creation.
- Added mouse simulation mode so the full interaction can still be demonstrated if microphone permissions fail.
- Added a live data graph to make the hidden input-processing stages visible.

### Important design decision

One processed intensity value controls several outputs. This creates a coherent visual system while keeping the data flow traceable in the explainer video:

`microphone → raw amplitude → calibration → mapping → smoothing → intensity → visual systems`

### Evidence

- Updated `BreathingCity/BreathingCity.pde`
- Live data panel in the running sketch
- Git commit for Stage 2

### Your genuine reflection - complete after running Stage 2

- Did the calibration finish successfully?
- What raw level appeared in a quiet room?
- How did the animation respond to soft and strong breaths?
- Did the response feel too sensitive, too weak, or appropriate?
- Which code concept became clearer after watching the live graph?

### Next step

Run the sketch on the student's computer, record measured values in the test log, tune thresholds, gather peer feedback, and then make an evidence-based final revision.

---

## Entry template - duplicate for every development session

Date:

### Goal


### What I changed


### What happened during testing


### Important code or error message


### Feedback received


### What I learned


### Evidence files


### Next step

