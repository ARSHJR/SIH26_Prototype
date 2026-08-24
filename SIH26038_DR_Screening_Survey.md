# SIH26038 — MATLAB-Based Explainable AI Pipeline for Diabetic Retinopathy Screening
### Problem Statement Survey

**Prepared for:** SIH 2026 mentor review
**PS Category:** Software | MedTech/BioTech/HealthTech
**PS Origin:** MathWorks

---

## 1. Problem Statement Overview (context for the sections below)

Build a MATLAB-based (Image Processing / Computer Vision / Deep Learning / Medical Imaging / Simulink / Statistics & ML Toolboxes) pipeline that:
1. Assesses and enhances fundus image quality, rejecting ungradeable images
2. Segments clinically relevant retinal structures (optic disc, fovea, vessels, microaneurysms, exudates, hemorrhages, neovascularization)
3. Grades DR severity on the ICDR 0–4 scale, hitting >90% sensitivity / >85% specificity for **referable DR (Level 2+)**
4. Explains its decisions via Grad-CAM, lesion-level evidence, and calibrated confidence — reviewable by an ophthalmologist in <30 seconds
5. Simulates the telemedicine screening workflow in Simulink for district-scale deployment (100,000+ patients/year)

---

## 2. Data Sources Available

### 2.1 Public fundus image datasets (all usable for training/benchmarking)

**Status check:** APTOS and IDRiD are already downloaded and available locally (`\IDRiD\home\jd2899\project\IDRID`) — one setup step already done. EyePACS access is uncertain: the prior UQ project hit a dead end (Kaggle API 404s), but this may have been account/session-specific rather than a hard blocker — worth a quick 10-minute re-check (try the Kaggle API pull directly) rather than assuming either way. If it works, great, more data; if not, APTOS + IDRiD + Messidor-2 alone is a well-established, sufficient combination per the literature cited below — don't burn build time chasing it further than one attempt.

| Dataset | Size | Grading | Notes |
|---|---|---|---|
| **APTOS 2019** (Kaggle, Asia Pacific Tele-Ophthalmology Society) | 3,662 labeled images (5,590 incl. test) | ICDR 0–4 | Already acquired. Most commonly used for quick benchmarking; class-imbalanced (heavy "No DR" skew) |
| **EyePACS / Kaggle DR Detection** | ~88,700 images | ICDR 0–4 | Largest public set; California Healthcare Foundation-sponsored; noisy/variable image quality — good for testing your quality-assessment module specifically. Access uncertain — verify quickly, don't block on it |
| **IDRiD** (Indian Diabetic Retinopathy Image Dataset) | 516 images (413 for grading) | ICDR 0–4 + DME | Already acquired. **Collected in Nanded, India** — directly relevant to this PS's India framing; includes pixel-level lesion annotations (microaneurysms, hemorrhages, exudates) plus optic disc/fovea coordinates — extremely useful for the segmentation module specifically |
| **Messidor / Messidor-2** | 1,200 / 1,748 images | 4-class (Messidor) / ungraded pairs (Messidor-2, commonly re-labeled) | High image quality, minimal noise — good for clean-condition validation |
| **DDR** | 13,673 images | ICDR 0–4 | Larger, more class-balanced than APTOS |
| **DiaRetDB0/1, e-Ophtha, DRIVE, STARE, CHASE-DB1** | Smaller (89–169 images) | Lesion/vessel-level | Specialized — DRIVE/STARE/CHASE are vessel-segmentation-only benchmarks, e-Ophtha is lesion-focused |

**Recommendation:** Combine **APTOS + IDRiD + Messidor-2** as your primary training/validation set (a well-established combination in published literature, ~5,900 images), and use **IDRiD's pixel-level lesion masks specifically** for the segmentation module since it's the only one with that granularity. Cite IDRiD's Indian origin explicitly in your pitch — it's a direct tie-in to "field conditions" and portable-camera variability the PS calls out.

### 2.2 MATLAB-native access

MathWorks has an **official example** ("Multilabel Diabetic Retinopathy Fundus Image Classification Using Deep Learning") that classifies DR fundus images into the five ICDR stages using a ResNet-101 transfer-learning model trained via `trainnet`, including focal cross-entropy loss to handle class imbalance — this is close to a reference implementation for exactly this PS and is worth studying line-by-line before you design your own pipeline.

### 2.3 Real-world / field data (harder to access, worth knowing about)

- **AFMS + AIIMS RPC (Dr. Rajendra Prasad Centre) + eHealth AI Unit, Ministry of Health** recently launched India's first AI-driven community DR screening programme — a genuine current government initiative you can reference as the real-world deployment context your Simulink model should be optimizing for.
- **Ayushman Bharat's eye-care package** already mandates annual DR screening using non-mydriatic fundus cameras at Primary Health Centres (PHCs) — this is your actual target deployment environment; design your image-quality module around what non-mydriatic (non-dilated pupil), field-condition images from these cameras typically look like (lower contrast, more artifacts than clinical-grade dilated images).
- You will **not** get real patient data in 36–40 hrs (nor should you try — DPDP Act implications, see Section 10). Public datasets + synthetic degradation (simulate blur/poor illumination on top of clean images) is the correct substitute for demonstrating your quality-assessment module.

---

## 3. Stakeholders

| Stakeholder | Interest / Role |
|---|---|
| **Patients (77M+ diabetic adults in India)** | End beneficiaries; need fast, low-cost, accurate screening without traveling to a specialist |
| **ASHA workers / PHC technicians** | Front-line operators capturing fundus images with portable cameras — your system's usability for *non-specialist* operators matters as much as raw accuracy |
| **Ophthalmologists** | Human-in-the-loop reviewers — your explainability module exists specifically to earn their trust and speed their validation (<30 sec target) |
| **Ministry of Health & Family Welfare / NPCB&VI** (National Programme for Control of Blindness and Visual Impairment) | Policy owner; has explicitly been recommended by recent population studies to prioritize DR screening nationally |
| **Ayushman Bharat / AB-PMJAY** | Financing and delivery vehicle — DR/glaucoma screening was added to its eye-care package in April 2022; your system should be designed to plug into this existing pipeline, not invent a parallel one |
| **State health departments (e.g., Kerala's pilot DR programme)** | Existing state-level pilots you can reference as deployment precedent |
| **District hospitals / telemedicine hubs** | The referral endpoint for your "referable DR" positive cases |
| **MathWorks (PS sponsor)** | Evaluating toolbox usage correctness and MATLAB-idiomatic engineering, not just final accuracy |
| **AFMS/AIIMS AI screening initiative** | A live comparable government program — useful for your competitive positioning ("our approach validates against/complements this") |

---

## 4. Use Cases

1. **Primary screening at PHC level** — ASHA/technician captures image → system immediately flags "gradable/ungradeable," recaptures if needed → grades DR severity → routes referable cases to an ophthalmologist queue
2. **Ophthalmologist rapid-review workstation** — batch review of AI-flagged cases with Grad-CAM overlays, confidence scores, and lesion annotations, targeting <30 sec/case
3. **District program planning** — the Simulink workflow model used by health administrators to answer "how many camera units and reviewing ophthalmologists do we need to screen X patients/year within Y bandwidth constraints?"
4. **Longitudinal patient tracking** — repeat screenings over time to track DR progression (stretch use case — mentioned implicitly via "annual population-based screening")
5. **Telemedicine referral bridge** — sanitized image + grading + evidence report transmitted from PHC to a remote specialist, consistent with existing Indian DR telemedicine literature
6. **Quality-control audit** — a supervisor/administrator view showing image-rejection rates by camera/site, useful for identifying equipment or training issues in the field

---

## 5. Technical Approach

### 5.1 Pipeline stages (map directly to the PS's 5 numbered requirements)

**Stage 1 — Image Quality Assessment & Enhancement**
- Compute focus/sharpness (Laplacian variance), illumination uniformity, and field-of-view coverage metrics
- Apply CLAHE (Contrast Limited Adaptive Histogram Equalization) on the green channel (where DR lesions show best contrast), illumination normalization, and denoising for borderline images
- Threshold-based or lightweight classifier-based accept/reject gate; rejected images trigger a "recapture" prompt with the specific defect flagged (too dark, out of focus, poor FOV)

**Stage 2 — Retinal Structure Segmentation**
- Optic disc/fovea localization: intensity + Hough-transform-based or a small U-Net segmentation model
- Vessel segmentation: classical (matched filtering) or U-Net-based binary segmentation — DRIVE/STARE/CHASE-DB1 are the standard training sets for this sub-task specifically
- Microaneurysm/exudate segmentation: use IDRiD's pixel-level lesion masks to train a segmentation model (U-Net or similar); microaneurysms are sub-pixel/near-pixel scale and are explicitly flagged by the PS as difficult — a morphological top-hat filtering pre-pass combined with a CNN classifier on candidate regions is a well-established classical+DL hybrid approach worth using rather than end-to-end segmentation alone
- **Hemorrhage classification (not just detection):** the PS text specifically says "classification," and there's a genuine clinical rule to ground this in — the **4-2-1 rule** for severe NPDR: >20 intraretinal hemorrhages in each of 4 quadrants, OR venous beading in ≥2 quadrants, OR intraretinal microvascular abnormalities (IRMA) in ≥1 quadrant. Implementing hemorrhage counting-by-quadrant against this rule gives you an actual classification criterion (not just a segmentation mask) and directly satisfies Stage 4's "lesion-level evidence correlated with clinical criteria" ask with a real, citable clinical standard rather than a purely learned decision boundary.
- **Neovascularization detection — genuinely the hardest sub-task, needs its own plan, don't treat it as "more of the same."** IDRiD's segmentation masks don't include NV as a labeled class, so the same U-Net-on-masks approach used for MA/EX won't directly apply. Realistic approach: treat it as an auxiliary binary classification task (NV present/absent) using images already labeled Grade 4 (Proliferative DR) in your combined dataset as positive examples, focused on vessel-density/tortuosity patterns near the optic disc (NVD) and elsewhere (NVE) rather than pixel-level segmentation. Be upfront in your pitch that this is the least mature part of the pipeline — judges will respect an honest "this is the hardest sub-problem and here's our simplified approach" more than an overclaimed one.

**Stage 3 — DR Severity Grading**
- Transfer learning on a pretrained CNN backbone (ResNet-101, EfficientNet, or Inception-v3 are all well-precedented for this task) fine-tuned on your combined dataset
- **The deliverable is the full 0–4 ICDR grade — this is not reducible to a binary task.** The PS's >90%/>85% target is specifically the *accuracy bar used to evaluate the referable-DR (Level 2+) framing of your 0–4 output*, not a substitute task — you still need to output all 5 severity levels. Report both: the full 5-class grade (with quadratic weighted kappa, the standard metric for ordinal DR grading) as your actual system output, and sensitivity/specificity on the collapsed referable-DR framing as your headline accuracy claim against the PS's explicit target
- Class-imbalance handling (focal loss or weighted cross-entropy) — all these datasets are heavily skewed toward "No DR"
- **Do not replace this with a fine-tuned MedGemma (or other VLM) as the core classifier.** It fights the MATLAB-native build strategy (no native fine-tuning path for multi-billion-parameter VLMs in Deep Learning Toolbox), doesn't address Stages 1/2/5 regardless, and Grad-CAM (Stage 4) is far more standard against a CNN than a generative VLM's output. A CNN transfer-learning approach is simpler, faster, and better-precedented (Section 9) than fine-tuning a VLM you've only previously used zero-shot.

**Stage 4 — Explainability Module**
- Grad-CAM (`gradCAM` function, MATLAB Deep Learning Toolbox) for attention-map generation
- Correlate Grad-CAM hotspots against your Stage 2 lesion segmentation output — this "cross-validation" between two independent pipeline stages is a strong differentiator (most teams will only do Grad-CAM in isolation)
- Calibrated confidence scores (Platt scaling or temperature scaling on the classifier's softmax output — raw softmax is notoriously overconfident and shouldn't be presented as a calibrated probability)
- Auto-generated annotated report (image + grade + confidence + lesion overlay + plain-language summary) designed for a <30 second glance-and-confirm workflow

**Stage 5 — Simulink Workflow Simulation**
- Model the screening pipeline as a queueing/throughput system: image acquisition rate (patients/hour at a PHC) → local processing latency → network transmission (bandwidth-constrained) → server/reviewer queue → ophthalmologist review capacity
- Use Simulink's discrete-event or SimEvents-style blocks to simulate bottlenecks and let administrators vary parameters (number of camera stations, network bandwidth, number of reviewing ophthalmologists) to see throughput/backlog trade-offs at the 100,000-patient/year district scale the PS specifies

### 5.2 Validation approach

- Held-out test split (never seen during training) from your combined dataset, cleanly disjoint by patient/image source to avoid leakage
- Report sensitivity/specificity for referable DR + 5-class accuracy/QWK + confusion matrix
- Benchmark explicitly against published numbers (Section 9) — this is literally requested: *"validation... showing the integrated pipeline outperforms any single technique approach"*

### 5.3 Reusable assets from prior team work (UQ toolbox project)

One team member has prior hands-on work in this exact domain — a project quantifying uncertainty in zero-shot VLM-based DR grading (MedGemma-4B, InternVL2-1B, prompted directly with no fine-tuning). Being precise about what does and doesn't carry over avoids wasted time:

**Does NOT carry over (needs building from scratch for this PS):**
- No trained classifier exists — the prior project never fine-tuned or trained anything; it queried frozen pretrained VLMs via prompting
- No segmentation of any kind (no vessels, no lesions, no optic disc/fovea)
- No Grad-CAM / attention visualization
- No quadratic weighted kappa was ever computed
- No binary referable-DR framing was ever run — all prior evaluation was strict 5-class exact grading

**DOES carry over — genuinely useful:**
- **Dataset access playbook**: working scripts for acquiring IDRiD (real 4288×2848 full-res images from the official source) and APTOS (stratified subsets from Kaggle `train.csv`) — this alone can save meaningful setup time. Note: EyePACS access was blocked in the prior project (Kaggle API returning 404s) — budget for this being a dead end again and lean on IDRiD/APTOS/Messidor instead.
- **A concrete, first-hand data point confirming the zero-shot-VLM-is-the-wrong-approach conclusion from earlier in this survey**: MedGemma-4B, prompted zero-shot for exact 5-class ICDR grading, scored **35% accuracy on IDRiD and 45% on APTOS**, with a *documented systematic bias toward over-grading* (e.g., predicting Grade 3 when truth is Grade 1). This is strong, specific evidence — cite it directly in your pitch as the reason your team deliberately chose a trained, purpose-built segmentation+CNN pipeline (per the PS's actual architecture, Section 5.1) instead of an LLM/VLM-prompting shortcut.

**Team decision: NOT reusing the heavy UQ infrastructure (perturbation/clustering/consistency-testing pipeline).** It solves a different problem (probing an existing model's behavior) than what this PS needs (a calibrated confidence signal on a newly trained classifier), and pulling it in would be scope creep without a clear payoff. Instead:

- The PS's Stage 4 text explicitly requires **"calibrated confidence scores"** — satisfy this with lightweight **temperature scaling** (a single learned scalar rescaling your trained classifier's softmax output, fit on a held-out validation split) rather than reusing the prior project's consistency-based approach. This is a small, self-contained addition (well under an hour of work) that directly satisfies an explicit deliverable, without importing unrelated complexity.
- Worth keeping in mind as a documented lesson, even though you're not reusing the code: **consistency under perturbation is not the same as calibration**, and a model can be very "consistent" while still being confidently wrong in a systematic direction. This is exactly why temperature scaling (which checks whether stated confidence matches actual empirical accuracy) is the more directly relevant tool for this PS's ask, not something to treat as interchangeable with consistency-testing.

### 5.4 Where your ophthalmologist contact adds real, PS-relevant value

The PS's Expected Solution text specifically asks for *"explainable Grad-CAM outputs rated as clinically useful"* — not just generated, **rated**. That's an evaluation step your team can actually satisfy with a real clinician, and almost no competing team will have this. Concrete, scoped ways to use the contact (each tied to a specific PS requirement, not just generic "get feedback"):

1. **Grad-CAM plausibility rating (directly satisfies the "rated as clinically useful" requirement).** Show them Grad-CAM heatmaps for a sample of your test images (correct and incorrect predictions both) and ask a simple question per image: does the highlighted region correspond to real pathology, or does it look like noise? Even 20-30 images rated this way gives you a genuine, citable clinical-agreement number for your pitch — far stronger than just asserting "our explainability is clinically meaningful."
2. **Quality-gate sanity check (Stage 1).** Ask what actually makes a fundus image ungradeable in their real practice (e.g., minimum visible disc-diameter radius around the fovea, specific artifact types). A real clinical rule of thumb here is more credible than an ad-hoc sharpness threshold your team invents, and can directly inform the realism of your synthetic-degradation test suite (Section 8).
3. **Hemorrhage/severity criteria sanity check (Stage 2/3).** Confirm the 4-2-1 rule framing (Section 5.1, Stage 2) is being applied sensibly, and ask which lesion signs they'd weight most heavily in an actual referral decision — useful for prioritizing where to invest remaining build time if segmentation work runs short (e.g., is vessel segmentation or hemorrhage quadrant-counting more load-bearing for the referable-DR decision than optic disc localization).
4. **Label-quality spot check.** If time allows, have them review a handful of cases where your model disagrees with the dataset label — since inter-dataset labeling drift is a documented real issue (Section 2), a clinician catching a genuinely mislabeled example is more convincing evidence of your system's soundness than any automated metric alone.
5. **Pre-demo sanity pass.** A 15-minute review of your final pitch/demo before presenting, specifically checking for any clinically incorrect claims — cheap insurance against an embarrassing error in front of judges (some of whom may include domain reviewers).

None of this needs to be a large time commitment from them — even a single 30-45 minute session covering items 1-3 would give you genuine, citable clinical validation that most teams simply won't have.

---

## 6. Technology Stack

| Layer | Tools |
|---|---|
| Core language/environment | **MATLAB, built natively from the start** (mandatory-in-spirit — PS explicitly names MathWorks toolboxes and is MathWorks-sponsored; don't prototype in PyTorch and port, since Simulink/Medical Imaging Toolbox have no Python equivalent and judges will likely evaluate toolbox usage itself). Confirm license access (campus/hackathon-provided) today. |
| Image processing | Image Processing Toolbox (CLAHE, denoising, morphological ops) |
| Structure segmentation / vessel & lesion detection | Computer Vision Toolbox, Image Processing Toolbox |
| Deep learning (grading + segmentation models) | Deep Learning Toolbox (`trainnet`, pretrained ResNet/EfficientNet/Inception import, `gradCAM`) |
| Medical-image-specific I/O and handling | Medical Imaging Toolbox |
| Statistics, calibration, confidence scoring | Statistics and Machine Learning Toolbox |
| Workflow/throughput simulation | Simulink (+ SimEvents if available for discrete-event queueing) |
| UI (if building a reviewer dashboard) | MATLAB App Designer, or a lightweight web frontend if your team wants a browser-based reviewer UI wrapping the MATLAB backend via MATLAB Production Server / Compiler |
| Version control / dataset management | Git + Git LFS or DVC for the (fairly large) image datasets |

---

## 7. Functionality (Core Deliverables Matching Expected Solution)

- [ ] Fundus image ingestion (single + batch)
- [ ] Automated quality gate with recapture feedback
- [ ] Adaptive enhancement for borderline images
- [ ] Optic disc / fovea localization
- [ ] Vessel segmentation map
- [ ] Microaneurysm / exudate / hemorrhage detection with bounding/pixel-level markup
- [ ] Neovascularization flag (proliferative DR indicator)
- [ ] 5-class ICDR severity grade output
- [ ] Referable-DR binary flag with sensitivity/specificity reporting
- [ ] Grad-CAM heatmap overlay
- [ ] Ophthalmologist-rated Grad-CAM plausibility sample (satisfies "rated as clinically useful")
- [ ] Calibrated confidence score
- [ ] Auto-generated annotated report (<30-sec-reviewable format)
- [ ] Simulink throughput/resource-allocation model with adjustable parameters
- [ ] Benchmark comparison table against published DR-grading literature

---

## 8. Unique / Above-and-Beyond Features

- **Cross-validating Grad-CAM against explicit lesion segmentation** rather than presenting attention maps alone — shows your explainability is grounded in actual detected pathology, not just gradient noise that happens to look plausible
- **Confidence calibration, not raw softmax** — explicitly measuring and reporting calibration (e.g., via a reliability diagram) is rare in hackathon submissions and directly strengthens the "clinically meaningful explainability" ask
- **A synthetic field-degradation test suite**: programmatically apply realistic blur/illumination/noise degradations to clean dataset images to *quantitatively* demonstrate your quality-assessment module's recall/precision at catching ungradeable images — since you won't have real portable-camera field data, this is the credible substitute, and very few teams will bother building it properly
- **Benchmark table against published results** (Section 9) presented transparently, including where you fall short — a judge who's read the literature will trust a modest, well-cited 87–90% far more than an unsupported 99% claim
- **India-specific framing throughout**: IDRiD's Nanded origin, Ayushman Bharat's existing PHC fundus-camera deployment, NPCB&VI as the policy stakeholder, and the recent AFMS/AIIMS AI screening pilot as a real comparable — ties your technical work to the actual deployment ecosystem rather than a generic global DR-AI pitch
- **Simulink model as a genuine decision-support tool**, not just a checkbox simulation — let a judge input different PHC counts/bandwidth/staffing numbers live and see backlog projections change; this turns a static deliverable into an interactive demo moment
- **Stretch goal, not core path: a fine-tuned MedGemma (or similar VLM) as an additional benchmark comparison row**, alongside your zero-shot number (already in Section 9) and your CNN pipeline's result — directly serves the PS's explicit call for validation showing the integrated pipeline "outperforms any single technique approach." Only pursue this once the core CNN-based pipeline is working; it's a nice-to-have for the benchmark table, not a substitute for it.

---

## 9. Reference Implementations & Benchmarks (GitHub / Published Work)

Use these as *sanity-check targets*, not code to copy wholesale — the point is to land in a similar, credible range with your own trained models, and to cite them honestly in your comparison table.

| Source | Approach | Reported result | Link |
|---|---|---|---|
| MathWorks official example: *Multilabel Diabetic Retinopathy Fundus Image Classification* | ResNet-101 transfer learning, `trainnet`, focal loss | Reference MATLAB implementation — study this first | [mathworks.com](https://www.mathworks.com/help/medical-imaging/ug/multilabel-diabetic-retinopathy-fundus-image-classification-using-deep-learning.html) |
| MathWorks Deep Learning blog: *Diabetic Retinopathy Detection* | Inception-v3, no preprocessing, MATLAB CAM visualization | 98.0% accuracy, AUC 0.9947 on their test split | [blogs.mathworks.com](https://blogs.mathworks.com/deep-learning/2020/08/20/diabetic-retinopathy-detection/) |
| GDRNet / GDRBench (`chehx/DGDR` on GitHub) | Domain-generalization benchmark across 8 public DR datasets | Useful as a standardized multi-dataset evaluation harness reference | [github.com/chehx/DGDR](https://github.com/chehx/DGDR) |
| Dual-branch CNN on APTOS 2019 | Binary + 5-stage classification (ResNet50 + EfficientNetB0) | Binary: 98.5% accuracy / 99.46% sensitivity / 97.51% specificity; 5-stage: 89.6% accuracy, QWK 0.93 | [arxiv.org/abs/2308.09945](https://arxiv.org/abs/2308.09945) |
| RadFuse | Fusion architecture (Radon transform + image), multiple CNN backbones tested | Best backbone (ResNeXt-50): QWK 98.17%, 99.09% accuracy, F1 99.11% for binary framing — **verify exact numbers against the paper directly before citing to your mentor; the figure originally in this table was an approximation** | [arxiv.org/pdf/2504.15883](https://arxiv.org/pdf/2504.15883) |
| Gulshan et al. 2016 (Google, JAMA) | Landmark clinical-grade referable-DR detection | AUC 0.991 (EyePACS-1) / 0.990 (Messidor-2) for referable DR — the historical benchmark that established the field | [research.google.com](https://research.google.com/pubs/archive/45732.pdf) |
| GitHub topic `diabetic-retinopathy-detection` filtered to MATLAB | Multiple community MATLAB implementations (GLCM+SVM, texture-feature approaches) | Useful for seeing classical (pre-deep-learning) MATLAB approaches, several reaching 90%+ on smaller datasets — good historical context for your literature review slide | [github.com/topics](https://github.com/topics/diabetic-retinopathy-detection?l=matlab) |
| MATLAB File Exchange: "Fundus Image diabetic analysis using deep learning with CNN" | Community CNN implementation | Reference/starter code | [mathworks.com/matlabcentral](https://www.mathworks.com/matlabcentral/fileexchange/68162-fundus-image-diabetic-analysis-using-deep-learning-with-cnn) |
| **Our own prior work** (zero-shot MedGemma-4B, n=20 IDRiD, n=20 APTOS) | Frozen VLM, prompted directly, no training | **35% (IDRiD) / 45% (APTOS)** exact 5-class accuracy, with documented systematic over-grading bias — cite this as first-hand justification for why a trained pipeline beats a prompted-VLM shortcut | Internal (Edinburgh UQ project) |

**Search terms for your own further digging:** `diabetic-retinopathy-detection` GitHub topic (131+ repos across Python/MATLAB/Jupyter), `GDRBench`, `IDRiD segmentation baseline`.

---

## 10. YouTube / Video Resources

I don't have verified direct video links to hand you (didn't want to fabricate URLs), but these are the productive channels/searches to check yourselves before building:

- **MathWorks' official YouTube channel** — has published walkthroughs on `gradCAM`, transfer learning with `trainnet`, and medical imaging toolbox usage; given this PS is MathWorks-authored, their own tutorial content is the highest-value place to start
- Search: **"MATLAB Deep Network Designer transfer learning tutorial"** — covers the exact workflow (import pretrained net → replace final layers → fine-tune) you'll use for Stage 3
- Search: **"Kaggle APTOS 2019 blindness detection walkthrough"** — many public notebook walkthroughs (mostly Python/Keras, but useful for understanding the dataset's quirks and common preprocessing pitfalls even if you reimplement in MATLAB)
- Search: **"Grad-CAM explained"** (Selvaraju et al.'s original CVPR talk is on YouTube) — for a correct conceptual grounding of what Grad-CAM does and doesn't tell you, useful for your pitch's explainability section
- Search: **"Simulink SimEvents discrete event simulation tutorial"** — for Stage 5's queueing/throughput modeling

---

## 11. Security & Regulatory Aspects

This PS deals with sensitive health data and a medical-diagnostic-adjacent system — this section matters more here than in most PSs, and covering it well will visibly differentiate your submission.

### 11.1 Data privacy — DPDP Act, 2023 (India)

- Fundus images plus any linked patient identifiers qualify as **personal data**, and arguably **sensitive personal data**, under India's Digital Personal Data Protection Act, 2023 (DPDPA), which is now operative following the 2025 Rules notified in November 2025.
- Under DPDPA: **explicit, informed consent is mandatory** for collecting/using patient data (blanket/implied consent is invalid); individuals have rights to access, correct, and erase their data; only data necessary for the stated purpose may be processed; and organizations may need to appoint a Data Protection Officer depending on scale.
- **Practical implication for your build:** since you're using public, already-de-identified datasets (APTOS/IDRiD/etc.), you're not directly triggering DPDPA obligations in your MVP — but you should **explicitly design for consent-capture and data-minimization in your architecture doc** as though this were going into real PHC deployment, since judges will likely probe this.
- **Anonymization note:** DPDPA does not expressly exempt anonymized data from its scope, but properly and irreversibly anonymized data is generally understood to fall outside its purview — if your system pipeline includes any patient-identifying metadata alongside images, show that you strip/separate it before any processing or storage step.

### 11.2 Medical device / software regulation — CDSCO

- India's medical devices sector, **including AI-enabled diagnostic software**, falls under the Central Drugs Standard Control Organisation (CDSCO), governed by the Drugs and Cosmetics Act, 1940 and Medical Device Rules, 2017.
- You are **not** expected to seek actual regulatory clearance for a hackathon MVP, but **acknowledging this regulatory pathway explicitly in your submission** (e.g., "a production version would require CDSCO Software as a Medical Device classification and clinical validation before deployment") signals maturity and separates you from teams that treat this as a pure software exercise.
- ICMR has also published AI-in-health ethics guidelines relevant to diagnostic AI — worth a one-line mention in your architecture doc's "responsible AI" section.

### 11.3 Technical security considerations

- **Image transmission security**: if your pipeline includes any client→server transmission (e.g., PHC device → central review server), specify TLS encryption in transit and encryption at rest for stored images
- **Access control**: role-based access so ophthalmologist reviewers, PHC technicians, and administrators see only what they need (a reviewer shouldn't see raw patient identifiers if not required for their task)
- **Audit logging**: who reviewed which case, when, and what grade was assigned/confirmed — important both for clinical accountability and for demonstrating system trustworthiness to judges
- **Model robustness**: briefly address adversarial/edge-case robustness — e.g., what happens if a completely non-retinal image is uploaded (should be caught by your Stage 1 quality gate, not silently misclassified)
- **Bias/fairness note**: since your training data draws heavily from EyePACS (US-sourced) blended with IDRiD (India-sourced), briefly acknowledge the domain-shift/fairness consideration between population groups and camera types — shows genuine ML maturity beyond just chasing an accuracy number

---

## 12. Tech Stack Constraints (Ideal-Case Scope) & Roadblocks to Clear Early

### 12.1 What "MATLAB-based" actually restricts you to

MATLAB is a separate proprietary programming/numerical-computing language and environment (MathWorks), not a Python library — different syntax, own IDE, matrix-native. The PS's listed tools are each **separately licensed add-on products** on top of base MATLAB, not automatically bundled:

| Toolbox | What it's actually for in this pipeline |
|---|---|
| Image Processing Toolbox | CLAHE, denoising, illumination normalization, morphological ops (Stage 1 quality module) |
| Computer Vision Toolbox | Structure/feature detection support (Stage 2 segmentation) |
| Deep Learning Toolbox | CNN transfer learning (`trainnet`, Deep Network Designer GUI), `gradCAM` (Stages 3–4) |
| Medical Imaging Toolbox | Medical-image-specific I/O and handling — **newer/narrower toolbox, verify your license includes it specifically** |
| Statistics and Machine Learning Toolbox | Calibration (temperature scaling), confidence/statistical reporting |
| **Simulink** (+ SimEvents for discrete-event modeling) | A *separate graphical modeling environment*, not a function library — you build a block diagram representing the screening workflow (acquisition rate → transmission → review queue) and vary parameters (camera count, bandwidth, reviewer count) to show throughput/bottleneck trade-offs for Stage 5's district-scale resource-allocation ask. Minimal coding involved — more assemble-and-configure than programming. |

**In an ideal-case scenario, your entire pipeline lives inside this one ecosystem** — no Python, no separate ML framework, no porting. This is the recommended approach given a MathWorks-sponsored PS and a 6–7 day build window (see prior discussion): judges will likely evaluate toolbox usage itself, and Simulink/Medical Imaging Toolbox have no real Python equivalent anyway.

### 12.2 Roadblocks to clear before building — in priority order

1. ~~MATLAB + all required toolbox licenses, including Medical Imaging Toolbox specifically.~~ **RESOLVED** — college has a Total Headcount Academic license (MATLAB, valid through 30-Nov-2026), confirmed to include all required toolboxes (all shown as checkbox-selectable in the installer, Medical Imaging Toolbox included). Install everything now, before the build window starts, since it's a large download.
2. **GPU/compute access for training.** Fine-tuning a CNN (ResNet-101/EfficientNet) end-to-end needs real compute; a laptop CPU alone will be painfully slow over a full dataset. Check if your college's MATLAB license includes Parallel Computing Toolbox + cloud/cluster access, or plan to use a machine with a local GPU. (If genuinely stuck, training in Python on free Colab/Kaggle GPU and importing the trained network into MATLAB via ONNX or the Deep Learning Toolbox Converter is a fallback — but treat this as a last resort given the toolbox-usage evaluation concern above, not a default plan.)
3. **EyePACS access — status uncertain, don't over-invest.** Prior team experience with this exact dataset hit a dead end (Kaggle API 404s), but you believe you may have working access — worth one quick verification attempt, not a repeated troubleshooting session. If it doesn't work cleanly within ~10 minutes, fall back to APTOS + IDRiD + Messidor-2 (already a well-established combination per the literature in Section 9) rather than losing build time to it.
4. **Team MATLAB familiarity.** If nobody's used MATLAB/Simulink before, budget a few hours against MathWorks' own free "two-hour interactive" onboarding courses (referenced on their student/hackathon pages) before diving into the actual build — cheaper than learning core syntax mid-deadline.
5. **Simulink/SimEvents specifically**, since it's the least code-like and most likely be unfamiliar territory — again, low individual complexity (block diagram, not programming), but worth a short dedicated walkthrough before Day 5–6 rather than encountering it cold.

The strongest overall narrative thread across all sections above: **this is not a toy classifier — it's a full clinical-workflow pipeline (quality gate → segmentation → grading → explainability → deployment planning) built specifically for India's real DR-screening infrastructure (Ayushman Bharat PHCs, IDRiD's Indian provenance, NPCB&VI as policy owner), validated transparently against published benchmarks, and designed with DPDPA/CDSCO-aware data handling from day one.** That combination — technical rigor + honest benchmarking + regulatory/deployment awareness — is what should make this survey (and eventually your PPT) stand out relative to teams that only show a trained classifier and an accuracy number.
