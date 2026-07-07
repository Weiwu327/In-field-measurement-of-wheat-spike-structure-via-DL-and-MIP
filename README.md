# In-field measurement of wheat spike structure via DL and MIP

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Data: Zenodo](https://img.shields.io/badge/Data-10.5281%2Fzenodo.21226407-blue.svg)](https://doi.org/10.5281/zenodo.21226407)

MATLAB + YOLO implementation of the wheat-spike trait measurement pipeline in
*"In-field measurement of awn, spikelet, and grain traits in wheat via deep learning
and morphological image processing."* A YOLO-series detector locates the ruler, ear
and grains; four decoupled MATLAB stages then quantify **twelve** spike traits (awn
number/length/area, ear length/width/area, grain and spikelet number, and four
spatial-distribution traits) from a single smartphone image.

The workflow is split into **four decoupled stages**. The two YOLO detection points
(full-image ROI detection, and grain detection on the EOA crop) are run by the Python
detector in `yolov8-pytorch/` (`predict.py` + `best_epoch_weights.pth`); the MATLAB
stages consume its `.txt` output. See
[Deep-learning detection](#deep-learning-detection-python) below.

## Citation

If you use this code or data, please cite:

> Wu, W., Zhao, Y., Wang, H., Liu, T., Zhong, X., Maes, W. H., Sun, C., Guo, W.,
> Sun, T., & Liu, S. In-field measurement of awn, spikelet, and grain traits in wheat
> via deep learning and morphological image processing. *Plant Phenomics* (under review).

```bibtex
@article{wu_wheat_spike_traits,
  title   = {In-field measurement of awn, spikelet, and grain traits in wheat
             via deep learning and morphological image processing},
  author  = {Wu, Wei and Zhao, Yuanyuan and Wang, Hui and Liu, Tao and
             Zhong, Xiaochun and Maes, Wouter H. and Sun, Chengming and
             Guo, Wenshan and Sun, Tan and Liu, Shengping},
  journal = {Plant Phenomics},
  year    = {2026},
  note    = {Data: \url{https://doi.org/10.5281/zenodo.21226407}}
}
```

## Class convention

YOLO labels are `<class> <cx> <cy> <w> <h>` (normalised). Classes (from
`test/classes.txt`): `0=eary (EWA)`, `1=earn (EOA)`, `2=grain`, `3=rect (10×100 mm)`.
One image = one spike.

## The four stages

| Stage | File | Input | Does | Output |
|------:|------|-------|------|--------|
| 1 | `stage1_detect.m` | original image | **YOLO-series** detect RECT/EOA/EWA | full-image `.txt` |
| 2 | `stage2_earSizeAndCrop.m` | image + `.txt` | **only** ear size (EL/EW, DL-box, px) + crop RECT/EWA/EOA | 3 crop `.jpg` |
| 3 | `stage3_scaleAwnGrain.m` | 3 crops | ASOP (RECT) · awn AN/AL/AS (EWA) · **pad EOA to square** (white `-w` for detection, black `-b` for masking) · **YOLO-series** grains on the white square | `EOA-w.jpg`/`EOA-b.jpg` + grain `.txt` |
| 4 | `stage4_remainingTraits.m` | EOA-b square + grain `.txt` + ASOP | ES · MBR ear size · GN · SPN · SPGN · GD · SPD · SPGD | trait struct |

The EOA crop is **centre-padded to a square** (side = max(H,W)) before grain
detection, because the single-grain detector expects square inputs. Padding (not
resizing) preserves the pixel scale, so ASOP still applies and grain coordinates
stay in the same frame as the Stage-4 ear-body mask (both use the square). The white
pad (`-w`) is the grain-YOLO input; the black pad (`-b`) makes ear-body masking
trivial. The grain label is written in the **square** frame.

Orchestrator `runPipeline.m` chains all four and returns a 1-row trait table.

```
runPipeline.m                 original image -> 1-row table of all 12 traits
├── stage1_detect.m           YOLO-series ROI detection (yolov8-pytorch/predict.py)
├── stage2_earSizeAndCrop.m
│   ├── readYoloLabels.m       parse full-image YOLO txt -> pixel boxes by class
│   └── cropROI.m              crop a [x1 y1 x2 y2] region
├── stage3_scaleAwnGrain.m     YOLO-series grain detection on the EOA square (predict.py)
│   ├── computeASOP.m          §2.5.1 Eq.6  pixel->mm scale from RECT
│   ├── preprocessSpike.m      §2.5.2(1) ExB (Eq.7) -> BEWA / BEOA / BA masks
│   ├── measureAwnNumber.m     §2.5.2(2) convex-hull ∩ skeleton, 50 dilations, ME/MD/TQ
│   ├── measureAwnLength.m     §2.5.2(3) DF / RA / ED
│   └── padToSquare.m          centre-pad EOA -> square (white -w / black -b)
└── stage4_remainingTraits.m
    ├── minBoundingBox.m       §2.5.3(1) MBR of the EOA ear body (Eq.8 angle) -> EL/EW/ES
    ├── readGrainLabel.m       grain label in the square frame -> pixel boxes
    ├── measureSpikeletNumber.m §2.5.3(2) PD/QD grouping fusion (Eq.9) -> GN, SPN
    └── measureDistributionTraits.m §2.5.4 SPGN, GD, SPD, SPGD

demo_pipeline.m               complete demo on ./data (all 12 traits + figure)
fullGrainsToEoaTxt.m          helper: full-image grains -> EOA-frame grain txt (fallback)
labelme2yolo.py               convert LabelMe JSON -> YOLO txt (Python)

yolov8-pytorch/               Python detector (Stages 1 & 3)
├── predict.py                run detection -> RECT/EOA/EWA/Grain label .txt
├── best_epoch_weights.pth    trained model weights
└── yolo.py                   model config (model_path, classes, conf, nms)
```

## Where each trait is produced

| Stage | Traits |
|------:|--------|
| 2 | EL, EW (DL-box method, pixels; → mm after ASOP) |
| 3 | ASOP · AN (ME/MD/**TQ**) · AL (**DF**/RA/ED) · AS |
| 4 | EL, EW (MBR method) · ES · GN · SPN · SPGN · GD · SPD · SPGD |

Ear size appears twice on purpose: the **DL** method (from the box, Stage 2) and the
**MBR** method (from the ear-body mask, Stage 4) — the two methods compared in the
paper. ASOP is computed in Stage 3, so Stage 2's ear size is returned in pixels and
converted to mm during final assembly.

## Usage

```matlab
addpath('Matlab_code')

% --- run the bundled complete demo on ./data (no YOLO needed) ---
run demo_pipeline        % prints all 12 traits + a verification figure

% --- production: after wiring your models into stage1 & stage3 ---
T = runPipeline('/path/spike.jpg');           % crops+txts go to spike_rois/
disp(T)
```

`data/` holds one worked example: `original image.jpg`+`.txt` (Stage 1 I/O),
`RECT/EWA/EOA.jpg` (Stage 2 crops), `EOA-w.jpg`+`EOA-w.txt` (grain-model I/O on the
white square) and `EOA-b.jpg` (black square for masking). `demo_pipeline.m` consumes
these directly and produces the full trait row.

Requires the Image Processing Toolbox (`adaptthresh`, `imbinarize`, `bwskel`,
`bwconvhull`, `bwareafilt`, `bwconncomp`, `imopen/imclose/imfill`).

## Deep-learning detection (Python)

The two detection steps (Stage 1 and Stage 3) are run by the YOLOv8 code in
`yolov8-pytorch/`:

- **`yolov8-pytorch/predict.py`** — inference entry point that detects **RECT, EOA
  (earn), EWA (eary) and Grain** and writes the normalised `<class> <cx> <cy> <w> <h>`
  label `.txt` files consumed by the MATLAB stages.
- **`yolov8-pytorch/best_epoch_weights.pth`** — the trained model weights. Point the
  detector at it by setting `model_path` in `yolov8-pytorch/yolo.py`:

  ```python
  "model_path"  : 'best_epoch_weights.pth',
  "classes_path": 'model_data/voc_classes.txt',   # eary / earn / grain / rect
  "input_shape" : [640, 640],
  "confidence"  : 0.5,
  "nms_iou"     : 0.3,
  ```

How it maps to the pipeline:

- **Stage 1** — run `predict.py` on the **original image** to get RECT/EOA/EWA boxes,
  producing the full-image `.txt` (classes 0/1/3) that `stage1_detect.m` reads.
- **Stage 3** — run `predict.py` on the **square-padded EOA crop** (`EOA-w.jpg`) to
  get the Grain boxes, producing the grain `.txt` (normalised to the square) that
  `stage3_scaleAwnGrain.m` reads.

In each MATLAB stage the detection call is a clearly marked user block. If you run
`predict.py` beforehand and drop the resulting `.txt` at the expected path, the empty
block simply **reuses that existing `.txt`** — so the MATLAB side needs no Python
bridge; it just consumes the label files.

## Data availability

The raw imagery is large (13 GB+), so it is not hosted on GitHub but on Zenodo:

- **2021–2022 original images**: <https://doi.org/10.5281/zenodo.21226407>
- **2023–2024 and 2025–2026 data**: available from the authors on request by email.

## Reconstruction assumptions (tune if needed)

1. **ASOP** = side length of one pixel, `sqrt(1000 / PN_rect)` mm; lengths use
   `px·ASOP`, areas use `px·ASOP²`.
2. **ExB**: `ExB = 2.7*B - R - G` on raw channels; the spike is *dark* in ExB and is
   segmented with `~imbinarize(ExB, adaptthresh(ExB,0.4,'ForegroundPolarity','dark',
   'Statistic','mean'))` — matches the original `extract_awn.m`.
3. **Awn-number dilation**: ear-body convex hull dilated by radius `k·H/50`,
   `k=1..50` (via a single `bwdist`, thin band = the disk-3 hull contour);
   intersections = connected components of (dilated-hull boundary ∧ awn
   skeleton).
4. **Opening radius** for awn removal is `round(15/1043·width)` (15 px at the ~1043 px
   reference width the method was tuned on); small-object thresholds (200/100/20 px)
   follow the original `extract_awn.m`.
5. **SPN**: grain *centres* rotated by `90−angle` (ear MBR) instead of re-running YOLO
   on a rotated crop — geometrically equivalent.
6. **QD slope** `k = ±0.4`, threshold `T = grainLen/3` (§2.5.3(2)(d)–(e)).
