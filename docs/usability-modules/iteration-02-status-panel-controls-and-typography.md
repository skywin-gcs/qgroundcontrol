# Iteration 02 — Status Panel Controls and Typography (Safe UI Integration)

## Goal

Build on Iteration 01 by improving usability of the new read-only status panel without changing flight behavior or destabilizing existing UI/logic.

This iteration focuses on:

1. **Readable, balanced typography** (middle ground versus prior too-small text)
2. **Operator-facing panel controls** (show/hide + compact/full mode)
3. **Strictly additive integration** (no replacement of existing controls)

---

## Summary of What Was Implemented

### 1) Typography and spacing adjustments (readability fix)

Updated in:

- `src/FlyView/FlyViewUsabilityStatusPanel.qml`

#### Changes

- Increased title and value font scaling to a middle-ground size:
  - `title`: now scales with compact/full modes
  - `value`: now scales with compact/full modes
- Increased line and grid spacing to avoid cramped look.
- Kept overall panel compact enough to fit right-side control area.

#### Rationale

The original status panel text was too small compared to surrounding FlyView controls.  
This iteration establishes a practical visual hierarchy:

- Bigger than before (readable at a glance)
- Smaller than major control headings/buttons
- Consistent with the rest of right-panel density

---

### 2) Added safe panel controls in main FlyView UI

Updated in:

- `src/FlyView/FlyView.qml`

#### New local UI state (FlyView-scoped only)

- `_showUsabilityStatusPanel` (default `true`)
- `_compactUsabilityStatusPanel` (default `false`)

These are local visual preferences in the view layer only (no mission/vehicle side effects).

#### Added control card

A small "Status Panel Controls" card was added above the status panel with:

- **Show/Hide Status**
- **Switch to Compact / Switch to Full**

These controls only affect panel visibility and layout mode.

#### Wiring

`FlyViewUsabilityStatusPanel` now binds to:

- `visible: _showUsabilityStatusPanel`
- `compact: _compactUsabilityStatusPanel`

---

### 3) Recording robustness and UI safety retained

From Iteration 01, retained and validated in this iteration:

- Defensive `startRecording` / `stopRecording` checks in `VideoManager.cc`
- User-facing messages when recording actions are invalid
- Right-panel recording button still guarded to avoid invalid path combinations

This iteration does not weaken those safeguards.

---

## Safety and Non-Breaking Guarantees

This iteration is intentionally low risk:

- No autopilot command path modifications
- No mission model changes
- No vehicle state mutation introduced
- No guided-action logic changes
- No removal of existing controls
- No backend architecture rewrites

All additions are **UI additive** and **read-only status driven**.

---

## Files Affected (Iteration 02)

### Updated

1. `src/FlyView/FlyViewUsabilityStatusPanel.qml`
   - Typography scaling
   - spacing/layout tuning for compact/full

2. `src/FlyView/FlyView.qml`
   - Added show/hide + compact/full controls
   - Added local panel state properties
   - Bound panel visibility/mode to those controls

### Carry-over from Iteration 01 (still active)

- `src/VideoManager/VideoManager.cc` (recording guard rails)
- `src/FlyView/CMakeLists.txt` (module registration for status panel)

---

## UI Behavior After Iteration 02

### Default behavior

- Status panel is visible by default.
- Full (non-compact) mode is active by default.
- Existing telemetry and control widgets remain unchanged.

### Operator controls

- Press **Hide Status** to remove panel from view.
- Press **Show Status** to restore it.
- Press **Switch to Compact** for denser layout.
- Press **Switch to Full** for larger text and spacing.

---

## Validation Checklist

### Build-level

- FlyView module compiles with updated QML
- Main app target compiles cleanly

### Runtime-level

- FlyView opens normally
- Existing control panel functions remain intact
- Status panel renders with readable text
- Show/Hide toggles work
- Compact/Full toggle works
- No regressions in recording control behavior from Iteration 01

---

## Design Notes

### Why local view properties instead of persistent settings now?

For safety and incremental delivery:

- Local state avoids schema/settings migration risk
- Keeps rollback trivial
- Lets us validate UX before introducing persistence

Persistent settings support is planned for next iteration.

---

## Next Planned Iteration (Iteration 03)

1. Persist panel preferences (show/hide, compact/full) in settings
2. Add optional soft warning badges (read-only)
3. Add small health trend indicators (non-blocking, non-commanding)

All still additive and safety-first.

---

## Rollback Plan

If rollback is needed:

1. Remove the status control card and panel bindings from `FlyView.qml`
2. Revert typography tweaks in `FlyViewUsabilityStatusPanel.qml`

No backend migration or data conversion required.

---

## Final Outcome

Iteration 02 successfully improves readability and usability of the status module while preserving system stability, existing workflows, and flight-critical behavior.