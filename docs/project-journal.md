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


