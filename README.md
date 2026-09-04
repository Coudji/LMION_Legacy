# LMION legacy development archive

## Read this first

The current project direction and resumable development state are maintained in [`CURRENT_STATE.md`](CURRENT_STATE.md).

**Do not use `REFACTOR_HANDOFF.md` as the current plan.** It documents the previous V2 refactor and remains useful as historical context only.

## Repository role

`LMION_Legacy` is now the archaeology/reference repository for LMION V3.

The intended V3 strategy is to create a new clean canonical repository (recommended name: `Coudji/LMION`) rather than moving all old material into an `archive/` directory here. Keeping this repository intact preserves history, paths, research references and easy V1/V2 comparison without polluting the V3 root.

Repository contents:

- `Legacy/Contents` — behavioral reference for already validated LMION behavior.
- `Legacy/Research` — engine/research knowledge. Expensive findings must be preserved and consulted before changing related PZ integration code.
- `Workshop` — V2 candidate/refactor tree. It is now an audit/migration source, not the V3 architecture.
- `CURRENT_STATE.md` — canonical handoff while V3 migration preparation is still happening here.
- `V3_REPOSITORY_AUDIT.md` — migration inventory and keep/migrate/archive decisions for V3.

Once the clean V3 repository exists, the active handoff and selected active research will move there. This repository will remain available as the historical source rather than being physically reorganized.

When resuming after a conversation limit, start with `CURRENT_STATE.md`, then read only the research notes relevant to the subsystem being touched.
