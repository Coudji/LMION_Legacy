# LMION development workspace

## Read this first

The current project direction and resumable development state are maintained in [`CURRENT_STATE.md`](CURRENT_STATE.md).

**Do not use `REFACTOR_HANDOFF.md` as the current plan.** It documents the previous V2 refactor and remains useful as historical context only.

Repository roles:

- `Legacy/Contents` — behavioral reference for already validated LMION behavior.
- `Legacy/Research` — engine/research knowledge. Expensive findings must be preserved and consulted before changing related PZ integration code.
- `Workshop` — current V2 candidate/refactor tree. It is now an audit/migration source, not automatically the V3 architecture.
- `CURRENT_STATE.md` — canonical handoff for the current conversation/project state.
- `V3_REPOSITORY_AUDIT.md` — migration inventory and keep/migrate/archive decisions for V3.

When resuming after a conversation limit, start with `CURRENT_STATE.md`, then read only the research notes relevant to the subsystem being touched.
