# Stage 2 cGAN Inference — Self-Contained Distribution

Translate **centerline skeleton images** into realistic **SHG-like collagen fiber images** using a trained conditional GAN (cGAN). This package is fully self-contained: no training code or dataset is required.

---

## Overview

The model takes a binary/grayscale centerline skeleton (single-channel PNG/TIF) and generates a photorealistic second-harmonic generation (SHG) microscopy image showing the collagen fiber texture along those centerlines.

**Architecture:** 6-level U-Net Generator (UnetGenerator, ngf=32) trained with an L1 + adversarial loss against a PatchGAN discriminator.

---

## Installation

Requires **Python 3.8+**.

```bash
pip install -r requirements.txt
# If you encounter errors with numpy, install the compatible version:
pip install numpy==1.23.5
```

| Package | Minimum version | Purpose |
|---|---|---|
| torch | 1.12.0 | Neural network inference |
| torchvision | 0.13.0 | Image tensor transforms |
| numpy | 1.23.5 | Array operations (required for compatibility) |
| Pillow | 9.0.0 | Image I/O |
| matplotlib | 3.5.0 | Visualization |
| opencv-python | 4.5.0 | Display helpers (CLAHE, dilation) |
| GPUtil | 1.4.0 | GPU logging |

A CUDA-capable GPU is recommended but not required; the code falls back to CPU automatically.

> **Note:**
> This code requires numpy version 1.23.5 for compatibility. If you see errors like "Numpy is not available" or opencv-python warnings about numpy version, downgrade numpy as shown above. The code works with numpy 1.23.5 even if opencv-python issues a warning.

---

## Quick Start

```python
import sys
sys.path.insert(0, '/path/to/collagen_stage2_inference')

from stage2_inference_viz import run_stage2_inference, visualize_stage2_results

# 1. Run inference
results = run_stage2_inference(
    centerline_images_path='example/',   # folder with input centerlines
    model_path='model/',                 # folder containing G.pt
    output_path='my_output/',            # where to save generated images
)

# 2. Visualize input/output pairs
visualize_stage2_results(results, save_figure='my_output/results.png')
```

The generated PNG files are saved to `my_output/` alongside a `log.txt`. The figure shows centerline images (top row) paired with generated images (bottom row).

---

## API Reference

### `run_stage2_inference`

```python
results = run_stage2_inference(
    centerline_images_path,   # str  — folder with input images
    model_path,               # str  — model directory or path to G.pt
    output_path,              # str  — output folder
    save_output=True,         # bool — save generated PNGs to output_path
    param_path=None,          # str  — path to params JSON (auto-detected by default)
    device=None,              # str  — 'cuda:0' / 'cpu' / None (auto)
)
```

**Returns:** `list` of `(stem, centerline_np, generated_np)` tuples

| Field | Type | Description |
|---|---|---|
| `stem` | `str` | Filename without extension |
| `centerline_np` | `np.ndarray` float32 [0,1] | Input centerline, shape `(H, W)` |
| `generated_np` | `np.ndarray` float32 [0,1] | Generated image, shape `(H, W)` |

**Notes:**
- Accepts `.png`, `.jpg`, `.jpeg`, `.tif`, `.tiff` inputs.
- `model_path` can be a directory containing `G.pt` or a direct path to `G.pt`.
- Generated images are saved as `{stem}_recon.png`.
- A `log.txt` is always written to `output_path`.

---

### `visualize_stage2_results`

```python
visualize_stage2_results(
    output_images,            # see Input Modes below
    input_images=None,        # str folder, list of arrays, or None
    pairs_per_row=5,          # int  — columns per row
    enhance_contrast=False,   # bool — apply CLAHE to generated images
    clip_limit=2.0,           # float — CLAHE clip limit
    bg_threshold=None,        # float — display vmin in [0-255] scale
    dilate_centerline=1,      # int  — dilation radius for centerlines (0 = off)
    normalize=False,          # bool — percentile normalization for display
    norm_low=2,               # float — lower percentile (default p2)
    norm_high=98,             # float — upper percentile (default p98)
    save_figure=None,         # str  — save path (None = interactive display)
    dpi=150,                  # int  — DPI for saved figure
)
```

#### Input Modes for `output_images`

| Mode | `output_images` | `input_images` | Result |
|---|---|---|---|
| **1** | list of `(stem, cl_np, gen_np)` from `run_stage2_inference` | — | centerline + generated pairs |
| **2** | folder path (str) with `*_recon.png` files | folder path with input images | centerline + generated pairs |
| **2b** | folder path (str) with `*_recon.png` files | `None` | generated images only |
| **3** | list of numpy arrays | list of numpy arrays (same length) | pairs |
| **3b** | list of numpy arrays | `None` | generated images only |

---

## Visualization Options

All display options are applied **for display only** — they never modify the saved PNG files.

| Option | Description | Suggested value |
|---|---|---|
| `normalize=True` | Stretch contrast using image percentiles; removes flat mid-gray background | `norm_low=2, norm_high=98` |
| `enhance_contrast=True` | CLAHE (local histogram equalization) for more local contrast | `clip_limit=2.0`–`4.0` |
| `bg_threshold=20` | Suppress background by setting display vmin; pixels below appear black | `10`–`40` |
| `dilate_centerline=1` | Widen 1-pixel centerline lines so they remain visible at thumbnail size | `1`–`2` |

**Example — enhanced visualization:**

```python
visualize_stage2_results(
    results,
    normalize=True,
    norm_low=2, norm_high=98,
    enhance_contrast=True,
    clip_limit=2.0,
    bg_threshold=15,
    save_figure='results_enhanced.png',
    dpi=200,
)
```

---

## Usage Examples

### Inference without saving files

```python
results = run_stage2_inference(
    'example/', 'model/', 'tmp_output/', save_output=False
)
stem, cl_np, gen_np = results[0]
print(f"Input shape: {cl_np.shape}, Output shape: {gen_np.shape}")
```

### Visualize from folders (after running inference separately)

```python
# Mode 2: folder-to-folder
visualize_stage2_results(
    output_images='my_output/',
    input_images='example/',
    save_figure='my_output/results.png',
)
```

### Visualize output images only

```python
visualize_stage2_results('my_output/', save_figure='generated_only.png')
```

### Specify GPU or CPU explicitly

```python
results = run_stage2_inference(
    'example/', 'model/', 'my_output/', device='cpu'
)
```

---

## File Structure

```
collagen_stage2_inference/
├── README.md                     This file
├── requirements.txt              pip dependencies
├── stage2_inference_viz.py       run_stage2_inference + visualize_stage2_results
├── example/
│   └── sample_centerline.png     Sample input for quick testing
├── model/
│   └── G.pt                      Trained generator weights (~28 MB)
├── parameters/
│   └── params_stage2.json        Model configuration (cGAN hyperparameters)
└── modules/
    ├── models/
    │   ├── __init__.py
    │   └── cgan.py               cGAN class (Generator + Discriminator)
    └── utils/
        ├── util_io.py            load_parameters, set_all_seeds, as_np
        ├── util_model.py         load_model, save_model
        ├── util_visualize.py     save_image
        └── logger.py             Logger with timestamped output
```
