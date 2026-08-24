# Stage 2 (Segmentation) — Scope Decision for the 12-Hour Prototype

Full deep-learning segmentation (U-Net trained on IDRiD's pixel masks for
microaneurysms/exudates/hemorrhages) is real work worth doing for the MVP
phase, but likely not worth the time budget for a 12-hour feasibility demo.

**Recommended shortcut for now — classical methods, fast to implement:**

- **Optic disc localization**: the optic disc is the brightest, most circular
  region in a fundus image. A simple approach: threshold the top ~5% brightest
  pixels, then use `regionprops` to find the largest circular connected
  component. A handful of lines, no training needed.
- **Vessel enhancement**: apply a matched filter or simply invert + CLAHE the
  green channel and threshold — vessels appear as dark, thin structures.
  Doesn't need to be pixel-perfect for a demo; needs to visibly highlight
  vessel structure.
- **Lesion candidates**: for a fast demo, run a morphological top-hat filter
  (`imtophat`) on the green channel to highlight small bright/dark blobs
  (candidate exudates/microaneurysms) — don't bother classifying them
  individually for this prototype, just show the candidate-region overlay.

**In your PPT/pitch**, be upfront: "Stage 2 in this prototype uses classical
CV for speed; the MVP phase will replace this with the trained U-Net
segmentation approach on IDRiD's lesion masks, per our architecture doc."
That's an honest, credible statement — judges evaluating a PPT-round
prototype are checking for feasibility understanding, not full-fidelity
implementation.
