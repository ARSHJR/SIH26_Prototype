# SIH26038 — 12-Hour Prototype Build

**Goal:** demonstrate the full pipeline works end-to-end, not hit 90%/85% accuracy targets.
That target is for the MVP phase; this prototype exists to get through the PPT round by
proving feasibility.

## How this project was assembled

- Classical image-processing scripts (Stage 1) were written directly — MATLAB's Image
  Processing Toolbox functions used here (`adapthisteq`, `imfilter`, `entropy`, etc.) have
  stable, long-established syntax, low risk of being wrong.
- The classifier training script (Stage 3) and Grad-CAM script (Stage 4) are **skeletons
  based on MathWorks' own official example**, not written from scratch — adapt them
  side-by-side with the live reference page rather than trusting this code blindly:
  https://www.mathworks.com/help/medical-imaging/ug/multilabel-diabetic-retinopathy-fundus-image-classification-using-deep-learning.html
- **Run everything through Claude Code in VSCode, not by hand.** It can execute
  `matlab -batch "script"` against your actual license and fix real errors — much faster
  than debugging blind. Point it at this folder and the MathWorks example link above.
- Stage 5 (Simulink) has no code file — it's a graphical block diagram. See
  `stage5_simulink/SIMULINK_SPEC.md` for exactly what to build.

## Suggested 12-hour order (adjust as you go — this is a plan, not a script)

| Hours | Task |
|---|---|
| 0–1 | Verify MATLAB + toolboxes run, point `data_prep/prepareDataset.m` at your local IDRiD/APTOS paths, run it |
| 1–3 | Stage 1: run/tune `stage1_quality/*.m` on a handful of images, sanity-check CLAHE output visually |
| 3–7 | Stage 3: adapt `stage3_classifier/trainDRClassifier.m` against the MathWorks example, fine-tune on a subset (don't aim for convergence — even a few epochs showing the loss curve trending down is enough to prove the pipeline works) |
| 7–8 | Stage 4: Grad-CAM on your trained net (`stage4_explainability/generateGradCAM.m`) |
| 8–9 | Stage 2 (simplified): classical optic-disc/vessel detection — see note in that folder; skip deep-learning segmentation, not worth the time for a feasibility demo |
| 9–10 | Stage 5: build the Simulink block diagram per the spec |
| 10–11 | `demo/runDemoPipeline.m` — chain everything on 2-3 sample images, produce the annotated report |
| 11–12 | Buffer / record screen capture for the PPT |

## What "solid prototype" means here, concretely

- One real trained classifier checkpoint (even mediocre accuracy) — not a mock
- One real Grad-CAM heatmap on a real prediction
- One real quality-gate accept/reject decision shown on a good vs. bad image
- One real Simulink model you can adjust parameters on live
- Chained together on at least one sample end-to-end

That's what proves feasibility to judges — not accuracy numbers.
