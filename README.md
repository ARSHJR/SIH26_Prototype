# SIH26038 — Diabetic Retinopathy Screening Pipeline

MATLAB-based, explainable AI pipeline for automated diabetic retinopathy (DR) screening in
primary healthcare settings. Built for **Smart India Hackathon 2026**, Problem Statement
**SIH26038** (sponsor: MathWorks).

## Results

Evaluated on a seeded, verified-disjoint 77-image held-out test set (IDRiD):

- 5-class exact accuracy: **54.5%**
- Quadratic Weighted Kappa: **0.693**
- Referable-DR (Grade 2+) sensitivity: **75.0%**
- Referable-DR (Grade 2+) specificity: **93.1%**

## Pipeline Status

| Stage | Status | Notes |
|---|---|---|
| 1 — Image Quality Assessment | ✅ Built & Verified | CLAHE enhancement, accept/reject gate; calibrated and negative-control tested |
| 2 — Structure Segmentation | ⚠️ Simplified | Classical CV for speed; trained U-Net segmentation planned for MVP |
| 3 — DR Severity Grading | ✅ Built, Trained & Evaluated | SqueezeNet transfer learning, verified disjoint test set |
| 4 — Explainability (Grad-CAM) | ✅ Built & Verified* | Real attention maps confirmed on real predictions; visual rendering polish in progress |
| 5 — Simulink Workflow Simulation | ✅ Built & Simulated | 100,000-patient stress-test |

## Repository Structure

```
SIH26/
├── README.md
├── trainedDRNet.mat                    (final trained model — seeded, disjoint split)
├── data_prep/
│   └── prepareDataset.m                (IDRiD loading, seeded train/val/test split)
├── stage1_quality/
│   ├── assessImageQuality.m            (quality gate)
│   └── enhanceImage.m                  (CLAHE enhancement)
├── stage3_classifier/
│   ├── trainDRClassifier.m
│   ├── evaluateClassifier.m
│   ├── runRetrainWithSeed.m
│   └── splitFileLists.mat              (exact, verified train/val/test file lists)
├── stage4_explainability/
│   └── generateGradCAM.m
├── stage5_simulink/
│   └── (Simulink model + simulation outputs)
└── demo/
    └── runDemoPipeline.m               (end-to-end demo: Stage 1 → 3 → 4)
```

## Getting Started

**Requirements:** MATLAB with Image Processing Toolbox, Computer Vision Toolbox, Deep
Learning Toolbox, Medical Imaging Toolbox, Simulink, and Statistics and Machine Learning
Toolbox.

```matlab
addpath(genpath('path/to/SIH26'))
load('path/to/SIH26/trainedDRNet.mat')     % loads variable `net`
sampleImg = 'path/to/an/IDRiD/visualization.png';
runDemoPipeline(sampleImg, net)
```

This prints the quality-gate decision, predicted ICDR grade, confidence, and referable-DR
flag, and displays a 3-panel figure (original / enhanced / Grad-CAM overlay).


## Status

Built as a feasibility prototype for the SIH26038 PPT round. Full MVP-phase work (trained
segmentation, stronger backbone, sensitivity-focused loss tuning, extended training) is
scoped and pending.
