# Wheat spike trait measurement — MATLAB (morphological image-processing stage)

Reconstruction of the MATLAB code for **Section 2.5** of *"In-field measurement of
awn, spikelet, and grain traits in wheat via deep learning and morphological image
processing."* This is the second stage of the pipeline: the deep-learning (YOLO,
Python) stage locates the four ROIs, and this MATLAB stage quantifies the 12 traits
on those ROIs. No retraining is needed here — everything is parameter-free geometry.

## Interface with the YOLO stage

Each field image is processed with its YOLO detection file (standard format,
`<class> <cx> <cy> <w> <h>`, normalised). Classes (from `test/classes.txt`):

| class | name  | meaning              |
|-------|-------|----------------------|
| 0     | eary  | EWA — ear with awns  |
| 1     | earn  | EOA — ear body       |
| 2     | grain | individual grains    |
| 3     | rect  | 10×100 mm scale ruler |

One image = one spike (1 EWA + 1 EOA + N grains + 1 RECT).

## Files (call graph)

```
measureSpikeTraits.m      one image -> 1-row table of all 12 traits
├── readYoloLabels.m      parse YOLO txt -> pixel boxes by class
├── cropROI.m             crop a [x1 y1 x2 y2] region
├── computeASOP.m         §2.5.1 Eq.6  pixel->mm scale from RECT
├── preprocessSpike.m     §2.5.2(1) ExB (Eq.7) -> BEWA / BEOA / BA masks
├── measureAwnNumber.m    §2.5.2(2) convex-hull ∩ skeleton, 50 dilations, ME/MD/TQ
├── measureAwnLength.m    §2.5.2(3) DF / RA / ED
├── measureEarSize.m      §2.5.3(1) EL, EW by DL box and MBR
│   └── minBoundingBox.m  rotating-calipers minimum bounding rectangle (Eq.8 angle)
├── measureSpikeletNumber.m §2.5.3(2) PD/QD grouping fusion (Eq.9) -> GN, SPN
└── measureOtherTraits.m  §2.5.4 AS, ES, GD, SPD, SPGN, SPGD

batchMeasure.m            loop a folder, write CSV
```

## Trait ↔ method map (Table A3)

| Trait | Symbol | Method implemented |
|-------|--------|--------------------|
| Awn number | AN | 3rd quartile (TQ) of hull–skeleton intersections over 50 dilation steps (ME/MD also returned) |
| Awn length | AL | DF (EWA−EOA height, primary), RA (skeleton/AN), ED (top-to-top distance) |
| Awn area | AS | awn pixel count × ASOP² |
| Ear length | EL | MBR long side (primary), DL box height |
| Ear width | EW | MBR short side (primary), DL box width |
| Ear area | ES | ear-body pixel count × ASOP² |
| Grain number | GN | count of grain boxes |
| Spikelet number | SPN | fused PD/QD grouping |
| Spikelet grain number | SPGN | GN / SPN |
| Grain distribution | GD | mean pairwise grain distance |
| Spikelet distribution | SPD | mean ordinate gap of lowest grains of adjacent spikelets |
| Spikelet grain distribution | SPGD | mean within-spikelet grain distance |

## Usage

```matlab
% single image
T = measureSpikeTraits('test/xxx.jpg', 'labels/xxx.txt');

% whole folder (image basename must match label basename)
results = batchMeasure('test', 'labels', 'spike_traits.csv');
```

Requires the Image Processing Toolbox (`adaptthresh`, `imbinarize`, `bwskel`,
`bwconvhull`, `bwareafilt`, `bwconncomp`, `imopen/imclose/imfill`).

## Reconstruction assumptions (please confirm / tune)

These points were under-specified by the text and equation images; the choices are
documented at the call site so they are easy to change:

1. **ASOP** is the *side length* of one pixel, `sqrt(1000 / PN_rect)` mm, so lengths
   convert as `px·ASOP` and areas as `px·ASOP²`. If your original code stored area
   per pixel instead, adjust `computeASOP.m` and the `^2` factors.
2. **ExB polarity**: the spike is *dark/low* ExB against the light board, so the code
   works on `1 − ExB`. Flip if your board/lighting differ.
3. **Awn-number dilation**: the "expansion threshold" is implemented as a disk
   dilation of the ear-body convex hull, radius `k·H/50`, `k=1..50`; intersection
   points are counted as connected components of (dilated-hull boundary ∧ skeleton).
4. **Opening radius** for awn removal (`0.02·width`) and the small-object thresholds
   are scale-based defaults; set them to whatever your images used.
5. **Grain rotation for SPN**: grain *centres* are rotated by `90−angle` (from the ear
   MBR) instead of re-running YOLO on the rotated crop — geometrically equivalent for
   the PD/QD classification, and avoids a second detection pass.
6. **QD slope** `k = ±0.4` and threshold `T = grainLen/3` follow §2.5.3(2)(d)–(e).
```
