# Iteration 04 — Opt-in Quick Actions Panel and Persistence Controls

## Goal

Introduce a **safe, opt-in Quick Actions panel** in FlyView to improve operator efficiency while preserving existing behavior and avoiding risky backend coupling.

This iteration focuses on:

1. A new **Quick Actions UI module** that calls only existing command paths.
2. **Visibility + compact/full controls** for the panel.
3. **Persisted preferences** for panel visibility and compact mode.
4. Maintaining strict non-breaking constraints from previous iterations.

---

## Scope

### Included

- New FlyView quick actions panel component.
- FlyView-side controls to show/hide and compact/full switch for quick actions.
- Persistence of quick actions panel preferences across sessions.
- Integration with existing video/detector/utility actions in a guarded way.

### Excluded

- Any changes to mission/autopilot command internals.
- Any replacement/removal of existing controls.
- Any new backend command APIs.
- Any flight-critical behavior changes.

---

## Files Added/Updated

### Added

- `src/FlyView/FlyViewQuickActionsPanel.qml`

### Updated

- `src/FlyView/CMakeLists.txt`
- `src/FlyView/FlyView.qml`

---

## 1) New module: `FlyViewQuickActionsPanel.qml`

A new panel component was added to provide fast access to common actions.

### Module design principles

- **Additive only**: no replacement of existing controls.
- **Safe command routing**: uses existing exposed methods (`videoManager.startRecording`, `stopRecording`, `grabImage`, `startVideo`, detector toggles).
- **No direct risky vehicle action dispatch** from this panel.
- **Guarded enable states** on every action.

### Action groups

- Flight (Arm/Disarm shown, RTL intentionally disabled in this panel to avoid direct unsupported call paths)
- Video (Start/Stop recording, screenshot)
- Detector (YOLO on/off, confidence up/down)
- Utilities (Start video, placeholder recenter-map signal hook)

### Why RTL is intentionally disabled here

For safety consistency, RTL from this panel is intentionally disabled and left to established guided-action flows/controllers. This avoids introducing a parallel or potentially unsupported command path from a new module.

---

## 2) FlyView integration and controls

`FlyView.qml` now includes a dedicated control card for the Quick Actions panel:

- **Show Quick Actions / Hide Quick Actions**
- **Switch to Compact / Switch to Full**

The panel is then conditionally rendered via:

- `visible: _showQuickActionsPanel`
- `compact: _compactQuickActionsPanel`

This keeps behavior user-configurable while preserving existing UI sections.

---

## 3) Preference persistence (Quick Actions)

Persistence was extended in the existing FlyView preference settings block.

### Persisted keys

- `showQuickActionsPanel` (bool)
- `compactQuickActionsPanel` (bool)

### Initialization

On `Component.onCompleted`, runtime UI state is restored from persisted values.

### Updates

Each toggle button updates both:
- local in-memory state
- persisted settings key

This ensures user preferences survive restart.

---

## 4) Safety model and non-breaking guarantees

This iteration remains low-risk and non-invasive:

- No mission/autopilot backend changes.
- No removal of legacy UI controls.
- No replacement of guided action flows.
- No hidden side effects in the quick panel.
- Existing behavior remains available and unchanged.

The quick panel is opt-in by visibility control and can be hidden entirely.

---

## Runtime behavior

### Defaults

- Quick Actions panel visible by default.
- Full mode (non-compact) by default.

### User actions

- Hide/show quick panel at runtime.
- Switch quick panel compact/full.
- Settings persist across restarts.

### Command behavior

- Video and detector shortcuts call existing APIs only.
- Guard conditions prevent invalid action invocation.
- RTL is disabled in quick panel by design for safety.

---

## Validation checklist

### Build/static

- QML module registration includes `FlyViewQuickActionsPanel.qml`.
- FlyView module builds successfully.
- Main target builds successfully.

### Diagnostics

- `FlyView.qml` has no diagnostics errors/warnings.
- `FlyViewQuickActionsPanel.qml` has no diagnostics errors/warnings.

### Runtime

- Quick Actions control card renders correctly.
- Panel show/hide and compact/full toggle works.
- Preferences persist after restart.
- Existing controls remain available and functional.

---

## Known constraints

- Quick panel intentionally does not add new backend actions.
- RTL remains disabled in this module pending a future safe integration path through guided controllers.
- Utility “Recenter Map” is exposed as a signal extension point and remains decoupled from map internals by design.

---

## Rollback plan

If rollback is needed:

1. Remove `FlyViewQuickActionsPanel.qml` from `src/FlyView/CMakeLists.txt`.
2. Remove quick actions control card and panel inclusion from `FlyView.qml`.
3. Remove quick-panel preference keys from the FlyView settings block.

No data migration is required.

---

## Next iteration candidates

1. Wire quick panel actions to guided controllers via explicit safe interfaces (no direct vehicle calls).
2. Add per-action visibility toggles (persisted) for personalized layouts.
3. Add optional keyboard shortcuts for quick panel actions.
4. Add read-only action telemetry (last action timestamp/result) for operator feedback.

---

## Summary

Iteration 04 introduces a practical, opt-in Quick Actions panel with persisted UI preferences while preserving system stability, existing workflows, and safety constraints. It improves usability without altering flight-critical logic or replacing established command paths.