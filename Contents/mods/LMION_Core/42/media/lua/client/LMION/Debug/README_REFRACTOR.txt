LMION Debug modular refactor
===========================

This folder replaces the previous client/LMION/Debug folder.

Current workflow:
- Right click -> one single "LMION Inspector" entry.
- Opening it adds the clicked square to the Inspector selection.
- Re-open the same entry on another square to add that square too.
- +N/+S/+E/+W add an adjacent square relative to the active square.
- Object rows cover all currently selected squares.
- Clicking an object toggles its selection AND previews its report.
- "Inspect selected" produces one copyable report for several objects at once.
- "Select all" is convenient for a complete garage / gate test row.
- Copy / Clear stay in the report panel.

Deliberately NOT implemented yet:
- world mouse picker mode from inside the window;
- persistent square highlights / hover highlight;
- rectangular area selection;
- filtering object types.

Those features now have clean homes under World/ and UI/ instead of growing
Inspector.lua into another monolith.
