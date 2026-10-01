# Run from scratch — verification procedure

This is a **test procedure**, not a claim that every test passed. The actual runtime report and `evidence/` contain completed results. Keep microphone, mouse, automated input and offline numerical tests separately labelled.

## A. Reproduce a downloaded copy

1. Extract the complete project into a new folder that has not been used for development. Do not open the archived baseline.
2. Follow the root README to install the exact reported Processing and Sound versions. Record OS, CPU architecture, Processing version, Sound version, input device and date. Software obtained from a later package-manager release is not automatically the tested version.
3. Open `BreathingCity/BreathingCity.pde` in Processing **Java mode**. Keep the sibling `.pde` tabs and `SignalEnvelope.java` in the same sketch folder. The folder must remain named `BreathingCity`.
4. Press Run. Record the console output and any permission prompt. Confirm that the expected window opens and Sydney landmarks render.
5. Start with labelled mouse/automatic simulation if hardware is unavailable; record it as a simulation result. Confirm calm, gentle, strong and recovery states and save screenshots with `S`.
6. Close Processing, reopen the fresh copy, and repeat the launch to detect assumptions about current working directory or temporary development files.

Expected dependencies are the Processing runtime and official Sound library; the scene needs no external images, recordings or font files. A successful fresh-copy run on the developer's machine does not prove compatibility with every other operating system.

## B. Physical microphone test

1. Set the operating system's intended input device and allow microphone access for the application actually running the sketch. Confirm microphone mode in the screen label. Use `N` for the next input device and `I` to reconnect when needed.
2. Press `R` and remain quiet through calibration. Save the calibration screen and record noise floor, margin, opening threshold and sensitivity.
3. Stay quiet for 20 seconds. Record whether energy remains near zero. If small room noise activates the scene, raise margin one step with `]` and repeat; record both settings.
4. At a repeatable distance, try three gentle breaths/blows and three stronger ones. Note the raw and processed values, whether each response appears, and recovery time. Keep the distance and system gain fixed during comparison.
5. Adjust sensitivity (`-` or `=`) only if the signal crosses the gate but the visual range is unsuitable. If needed, lower margin with `[`. Record one change at a time. `0` restores default gain/margin.
6. Stop input for at least 5 seconds and inspect smooth recovery. Speak or clap once as an explicit limitation test: activation is expected because the program uses amplitude, not AI breath recognition.
7. If the raw level remains zero, distinguish a wrong device/permission failure from an exceptionally quiet room using the OS input meter. Do not mark a physical breath test as passed using mouse input.

## Guided one-minute trial

Press `G` to begin the guided microphone trial. Follow the on-screen phases: 0–10 seconds quiet (including calibration), 10–25 gentle, 25–40 strong, 40–55 stop/recovery, and 55–60 finish. Keep microphone distance and OS gain consistent. The phase label records the prompt, not proof that the user performed the action: after the run, confirm what was actually done and note interruptions. Compare the phase data only after that confirmation.

## C. Controls, failure and sustained operation

- Exercise `M`, `A`, `G`, `R`, `N`, `I`, `D`, `H`, `S`, `[`, `]`, `-`, `=`, `0`; confirm screen mode and parameters match the action. Keep the mode visible in evidence.
- If practical, select an unavailable input or remove a USB device and record the error/recovery behaviour. Do not claim this test if it was not performed.
- Optional extended check recommended during review (not a user-specified requirement): run the artwork for 30 wall-clock minutes at a demanding input pattern. Record FPS, particle count, ripple count and elapsed time at 0, 5, 10, 20 and 30 minutes. Check particle count ≤180 and ripple count ≤8; record visible pauses and CPU/memory if measured.
- A fast offline numerical simulation of 30 minutes validates its tested calculations, not 30 minutes of actual GUI/audio performance.

## D. Evidence and acceptance

| Evidence | Required label | Acceptance / limit |
|---|---|---|
| Calibration / quiet screenshot | MICROPHONE, real device | Sample collected and floor visible; does not alone prove breath response |
| Gentle / strong / recovery captures | Mode + parameter settings | Visible separation and smooth decay; include numerical ranges |
| Simulation captures / video | MOUSE or AUTO DEMO | Graphics demonstration only |
| Long-run log | Wall-clock duration + machine | Bounded objects and measured frame rate; no missing time represented as tested |
| Fresh-copy launch | Extracted path + dependency versions | Follow README without access to source-development paths |
| Peer form | Actual person/date/mode | Interaction feedback, distinct from assistant observations |

Append results with an honest status: PASS, FAIL, BLOCKED or NOT RUN. Keep logs from failures and retests. Test records should say who or what ran the test (student, assistant automation, peer) and whether input was real, synthetic or absent.
