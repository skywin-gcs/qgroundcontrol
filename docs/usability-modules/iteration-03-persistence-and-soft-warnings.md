# Iteration 03 — Persistence and Soft Warning Badges

## Goal

Extend the safe usability module with:

1. **Persisted panel preferences** (show/hide and compact/full mode)
2. **Read-only soft warning badges** for operator awareness

This iteration remains strictly additive and non-invasive: no flight-critical logic changes, no vehicle command path modifications, and no replacement of existing controls.

---

## Scope

### Included

- Persisting status panel view preferences across sessions
- Adding non-blocking warning badges derived from existing runtime state
- Keeping all existing controls and workflow intact

### Excluded

- Any autopilot command logic changes
- Any mission upload/edit path changes
- Any backend state mutation caused by the new panel
- Any mandatory modal alerts or disruptive UX behavior

---

## Files Updated

1. `src/FlyView/FlyView.qml`
2. `src/FlyView/FlyViewUsabilityStatusPanel.qml`

---

## 1) Preference Persistence in `FlyView.qml`

### What was added

- Imported QML settings support:
  - `import Qt.labs.settings 1.1`
- Added local panel state properties:
  - `_showUsabilityStatusPanel`
  - `_compactUsabilityStatusPanel`
- Added persisted storage:
  - `Settings { category: "FlyViewUsabilityPanel" }`
  - `showPanel` (bool)
  - `compactPanel` (bool)
- On startup (`Component.onCompleted`), UI state is restored from persisted values.
- On button click, both in-memory state and persisted values are updated.

### Why this is safe

- Persistence is strictly UI preference state.
- No coupling to vehicle state, mission state, or command dispatch.
- Defaults remain sensible if no stored values exist.

---

## 2) Soft Warning Badges in `FlyViewUsabilityStatusPanel.qml`

### What was added

A read-only warning badge section was introduced below the status grid using a `Flow` layout.

Helper functions added:

- `_warningVisible(id)`
- `_warningLevel(id)`
- `_warningText(id)`
- `_warningColor(level)`

Badge cases implemented:

- `vehicle`: no active vehicle connected (**critical**)
- `comms`: comms lost while vehicle exists (**critical**)
- `video`: video configured but decode idle (**warning**)
- `recording`: decode active but recording off (**info**)
- `yolo`: detector available but disabled (**info**)

### UX behavior

- Badges appear only when corresponding condition is true.
- Styling is intentionally soft (subtle background, colored border/text).
- No modal dialogs, no command lockouts, no forced actions.

---

## Design Principles Preserved

1. **Additive-first integration**
   - Existing right-panel controls remain unchanged.
2. **Read-only awareness**
   - New panel content does not trigger side effects.
3. **Low-risk persistence**
   - Preference-only data, isolated category.
4. **Operator clarity**
   - Actionable but non-blocking visual cues.

---

## Runtime Expectations

- On first launch:
  - Panel defaults to visible/full mode.
- After user changes panel visibility or compact mode:
  - Preference is restored on next launch.
- Warning badges appear/disappear dynamically with telemetry/video/detector state.
- Existing recording safety checks from prior iteration remain active.

---

## Validation Checklist

### Build/Static

- FlyView QML compiles with no diagnostics
- Usability status panel QML compiles with no diagnostics

### Runtime

- Status panel preference state persists across restart
- Show/Hide and Compact/Full controls continue to function
- Soft warning badges render correctly per state transitions
- Existing controls (arm/mode/guided/video) remain unaffected

---

## Rollback Plan

If rollback is required:

1. Remove `Qt.labs.settings` import and `Settings` block from `FlyView.qml`
2. Remove warning helper functions and badge `Flow` section from `FlyViewUsabilityStatusPanel.qml`
3. Keep base status panel from Iteration 01/02 intact

No data migration needed.

---

## Known Constraints

- `Qt.labs.settings` is used for pragmatic lightweight persistence in this iteration.
- Badge logic is intentionally conservative and informational.
- No telemetry trend history storage in this iteration (planned for a future pass).

---

## Next Iteration (Proposed)

1. Optional lightweight health trend indicators (read-only)
2. Optional panel-level setting to mute specific badge types
3. Optional profile presets for operator role (pilot/observer/inspection)

All future work should continue to follow the same safety-first, additive architecture.