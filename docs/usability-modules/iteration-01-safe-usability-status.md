# Iteration 01 — Safe Usability Status Module + Recording Safeguards

## Goal

Introduce the **safest possible usability improvements** without changing core flight behavior or destabilizing the existing UI/codebase.

This iteration intentionally focuses on:
1. A **read-only operator status panel** (no state mutation).
2. **Recording start/stop safety guards** to prevent silent failures and misleading UI behavior.

---

## Scope of Changes

### 1) New read-only FlyView module

A new QML component was added:

- `src/FlyView/FlyViewUsabilityStatusPanel.qml`

This panel is **observational only** and displays:
- Vehicle connection status
- Communications status
- Video source configured status
- Video decode active/idle status
- Recording ON/OFF state
- YOLO availability/enabled state
- Current detection count

It does **not**:
- Start/stop video
- Arm/disarm vehicle
- Change flight mode
- Toggle recording
- Toggle detector state

It only reads existing properties from:
- `QGroundControl.videoManager`
- `QGroundControl.multiVehicleManager.activeVehicle`

---

### 2) Integrate module into FlyView (additive only)

The panel was inserted into the existing right-side `ColumnLayout` in:

- `src/FlyView/FlyView.qml`

Integration is additive:
- Existing controls remain in place and behavior is preserved.
- No existing widgets were removed.
- No guided action logic was altered.

---

### 3) Recording safeguards in VideoManager

`VideoManager::startRecording` and `VideoManager::stopRecording` were hardened in:

- `src/VideoManager/VideoManager.cc`

#### Added safeguards:

- Null receiver checks.
- Skip non-started receivers explicitly.
- Track whether at least one receiver accepted the command.
- Emit user-facing app message when no receiver is available.

#### Behavior after change:

- If recording is requested before an active stream is ready:
  - command does not silently fail
  - user gets clear feedback:
    - `"Cannot start recording: no active video stream is ready yet."`

- If stop is requested while no receiver is active:
  - user gets clear feedback:
    - `"Recording is not active on any available video stream."`

---

### 4) Right-panel recording button guard (UVC-safe)

In `src/FlyView/FlyView.qml`, right-panel recording button was constrained to avoid invalid backend combinations:

- `enabled` now requires:
  - `videoManager` exists
  - `videoManager.decoding` is true
  - `!videoManager.isUvc`

This keeps recording flow predictable in this iteration and avoids invoking recording via unsupported/unstable paths while preserving the dedicated UVC path controls.

---

### 5) FlyView module registration

The new QML file was registered in:

- `src/FlyView/CMakeLists.txt`

Added to `qt_add_qml_module(... QML_FILES ...)`:
- `FlyViewUsabilityStatusPanel.qml`

---

## Design Principles Used

### A) Additive-first architecture
No destructive refactor. Existing code paths remain intact.

### B) Read-only UX module
First iteration module is intentionally non-invasive:
- no command side effects
- no additional backend coupling
- low rollback cost

### C) Explicit user feedback
Where commands can be ignored due to readiness constraints, messages are surfaced instead of failing silently.

### D) Defensive coding
Null checks and readiness checks were added before issuing receiver commands.

---

## Why this is considered “safest”

- No changes to vehicle command APIs.
- No changes to mission upload logic.
- No modifications to flight-critical state transitions.
- No replacement of existing visual components.
- No runtime dependency additions.
- Module can be removed by deleting a single QML inclusion if needed.

---

## Files touched in this iteration

1. **Added**
   - `src/FlyView/FlyViewUsabilityStatusPanel.qml`

2. **Updated**
   - `src/FlyView/CMakeLists.txt`
   - `src/FlyView/FlyView.qml`
   - `src/VideoManager/VideoManager.cc`

3. **Documentation**
   - `docs/usability-modules/iteration-01-safe-usability-status.md` (this file)

---

## Validation strategy used

### Build checks
- Ensure QML module registration compiles.
- Ensure no C++ signature mismatches from `VideoManager` edits.

### Runtime checks
- FlyView opens with existing controls still present.
- Status panel renders and updates live.
- Start recording with no active stream shows clear user message.
- Stop recording with no active stream shows clear user message.
- Existing recording flow still works when stream is active.

---

## Known constraints (intentional for Iteration 01)

- Right-panel recording button is disabled for UVC path in this pass for stability.
- This iteration does not introduce settings toggles for the status panel yet.
- No persistence/profile customization yet.

These are reserved for later iterations once baseline safety is confirmed.

---

## Next Iterations (planned)

### Iteration 02 (still safe)
- Add app setting to show/hide status panel.
- Add compact/full display modes persisted in settings.
- Add optional soft warning badges (decode idle, comms lost).

### Iteration 03
- Add non-blocking telemetry/video health trend indicators.
- Add operator tooltip help text and diagnostics links.

### Iteration 04
- Add customizable “quick actions” panel (opt-in), preserving legacy controls.

---

## Rollback plan

If needed, rollback is straightforward:
1. Remove `FlyViewUsabilityStatusPanel.qml` from `src/FlyView/CMakeLists.txt`.
2. Remove panel inclusion from `src/FlyView/FlyView.qml`.
3. Revert `VideoManager.cc` recording guard changes.

No schema/data migration is required for this iteration.

---

## Summary

Iteration 01 successfully adds a **safe, read-only usability module** and **recording robustness improvements** while preserving existing operational behavior and minimizing integration risk.