"""
stage2_inference_viz.py
-----------------------
Two reusable functions for Stage 2 cGAN inference and result visualization.

Public API:
    run_stage2_inference(centerline_images_path, model_path, output_path, ...)
        -> list of (stem, centerline_np, generated_np)

    visualize_stage2_results(output_images, input_images=None, ...)
        -> None  (displays or saves a matplotlib figure)
"""

import os
import glob
import math

import numpy as np
import matplotlib.pyplot as plt
from PIL import Image

import torch
import torch.nn.functional as F
from torchvision.transforms import ToTensor

from modules.models import cGAN
from modules.utils.logger import Logger
from modules.utils.util_io import load_parameters, set_all_seeds, as_np
from modules.utils.util_model import load_model
from modules.utils.util_visualize import save_image

os.environ.setdefault('KMP_DUPLICATE_LIB_OK', 'True')

_DEFAULT_PARAM_PATH = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "parameters", "params_stage2.json"
)


# ---------------------------------------------------------------------------
# Private display helpers
# ---------------------------------------------------------------------------

def _load_image_as_float(path):
    """Load any supported image as float32 grayscale in [0, 1]."""
    img = Image.open(path)
    if img.mode != 'L':
        img = img.convert('L')
    return np.array(img, dtype=np.float32) / 255.0


def _dilate_for_display(image_np, radius=1):
    """Dilate thin centerline lines for display (does not modify source data). Returns float32 [0,1]."""
    import cv2
    img_uint8 = (np.clip(image_np, 0, 1) * 255).astype(np.uint8)
    k = 2 * radius + 1
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (k, k))
    return cv2.dilate(img_uint8, kernel, iterations=1).astype(np.float32) / 255.0


def _normalize_percentile(image_np, low=2, high=98):
    """Stretch contrast to [0,1] by clipping at percentiles. Returns float32 [0,1]."""
    p_low = np.percentile(image_np, low)
    p_high = np.percentile(image_np, high)
    if p_high <= p_low:
        return image_np.astype(np.float32)
    return np.clip((image_np - p_low) / (p_high - p_low), 0, 1).astype(np.float32)


def _enhance_clahe(image_np, clip_limit=2.0):
    """Apply CLAHE to a float [0,1] grayscale image. Returns float32 [0,1]."""
    import cv2
    img_uint8 = (np.clip(image_np, 0, 1) * 255).astype(np.uint8)
    clahe = cv2.createCLAHE(clipLimit=clip_limit, tileGridSize=(8, 8))
    return clahe.apply(img_uint8).astype(np.float32) / 255.0


# ---------------------------------------------------------------------------
# Public function 1: Inference
# ---------------------------------------------------------------------------

def run_stage2_inference(
    centerline_images_path,
    model_path,
    output_path,
    save_output=True,
    param_path=None,
    device=None,
):
    """
    Run Stage 2 cGAN inference: translate centerline images into realistic SHG-like images.

    Args:
        centerline_images_path (str): Folder containing input centerline images
                                     (.png, .jpg, .jpeg, .tif, .tiff).
        model_path (str): Path to the model directory containing G.pt, or a direct
                          path to G.pt itself.
        output_path (str): Folder where generated images and a log file are saved.
        save_output (bool): If True, save each generated image as {stem}_recon.png
                            in output_path. Default: True.
        param_path (str): Path to params_stage2.json. Defaults to the parameters/
                          folder next to this script file.
        device (str): 'cuda:0', 'cpu', or None for automatic detection.

    Returns:
        list of tuples: Each tuple is (stem, centerline_np, generated_np) where
            - stem (str): filename without extension
            - centerline_np (np.ndarray): input centerline, float32 [0,1], shape (H, W)
            - generated_np (np.ndarray): generated image, float32 [0,1], shape (H, W)
    """
    # --- resolve param_path ---
    if param_path is None:
        param_path = _DEFAULT_PARAM_PATH
    if not os.path.isfile(param_path):
        raise FileNotFoundError(f"Parameter file not found: {param_path}")

    # --- resolve model directory ---
    if os.path.isfile(model_path):
        model_dir = os.path.dirname(os.path.abspath(model_path))
    elif os.path.isdir(model_path):
        model_dir = model_path
    else:
        raise FileNotFoundError(f"model_path does not exist: {model_path}")
    if not os.path.isfile(os.path.join(model_dir, "G.pt")):
        raise FileNotFoundError(f"G.pt not found in model directory: {model_dir}")

    # --- resolve device ---
    if device is None:
        if torch.cuda.is_available():
            device = "cuda:0"
        elif hasattr(torch.backends, 'mps') and torch.backends.mps.is_available():
            device = "mps"
        else:
            device = "cpu"

    # --- validate input folder ---
    if not os.path.isdir(centerline_images_path):
        raise NotADirectoryError(
            f"centerline_images_path is not a directory: {centerline_images_path}"
        )

    # --- setup ---
    os.makedirs(output_path, exist_ok=True)
    logger = Logger(save_path=os.path.join(output_path, "log.txt"), muted=False)
    logger.print(f"run_stage2_inference")
    logger.print(f"  input  : {centerline_images_path}")
    logger.print(f"  model  : {model_dir}")
    logger.print(f"  output : {output_path}")
    logger.print(f"  device : {device}")
    logger.print(f"  save   : {save_output}")

    set_all_seeds(0)
    params = load_parameters(param_path=param_path, copy_to_dir=None)

    # --- build and load model ---
    model = cGAN(params=params, is_train=False, device=device)
    load_model(model, model_dir, world_size=1, logger=logger)
    model = model.to(device)
    model.eval()

    # --- discover images ---
    exts = ("*.png", "*.jpg", "*.jpeg", "*.tif", "*.tiff")
    image_paths = []
    for ext in exts:
        image_paths.extend(glob.glob(os.path.join(centerline_images_path, ext)))
    image_paths = sorted(image_paths)
    if not image_paths:
        raise FileNotFoundError(f"No images found in: {centerline_images_path}")
    logger.print(f"Found {len(image_paths)} image(s).")

    # --- inference loop ---
    to_tensor = ToTensor()
    results = []

    with torch.no_grad():
        for i, img_path in enumerate(image_paths):
            stem = os.path.splitext(os.path.basename(img_path))[0]
            try:
                pil_image = Image.open(img_path).convert('L')
                centerline_np = np.array(pil_image, dtype=np.float32) / 255.0

                centerline_t = to_tensor(pil_image).to(device)   # (1, H, W)
                centerline_t = centerline_t.unsqueeze(0)          # (1, 1, H, W)

                # reflect-pad to multiple of 64 (6-level U-Net requirement)
                _, _, h, w = centerline_t.shape
                pad_h = (64 - h % 64) % 64
                pad_w = (64 - w % 64) % 64
                if pad_h > 0 or pad_w > 0:
                    centerline_t = F.pad(centerline_t, (0, pad_w, 0, pad_h), mode='reflect')

                model.centerline = centerline_t
                generated_t = model.forward(model.centerline)

                if pad_h > 0 or pad_w > 0:
                    generated_t = generated_t[:, :, :h, :w]

                # denormalize: tanh output [-1, 1] -> [0, 1]
                generated_np = (as_np(generated_t).squeeze() + 1.0) / 2.0
                generated_np = generated_np.astype(np.float32)

                if save_output:
                    save_path = os.path.join(output_path, f"{stem}_recon.png")
                    save_image(generated_np, save_path)

                results.append((stem, centerline_np, generated_np))
                logger.print(f"[{i+1}/{len(image_paths)}] {stem}")

            except Exception as exc:
                logger.print(f"ERROR on {os.path.basename(img_path)}: {exc}")

    logger.print(f"Done. {len(results)}/{len(image_paths)} image(s) processed.")
    return results


# ---------------------------------------------------------------------------
# Public function 2: Visualization
# ---------------------------------------------------------------------------

def visualize_stage2_results(
    output_images,
    input_images=None,
    pairs_per_row=5,
    enhance_contrast=False,
    clip_limit=2.0,
    bg_threshold=None,
    dilate_centerline=1,
    normalize=False,
    norm_low=2,
    norm_high=98,
    save_figure=None,
    dpi=150,
):
    """
    Visualize Stage 2 inference results as a matplotlib figure.

    The figure shows input centerlines (top row) paired with generated images
    (bottom row) when input data is available, or a grid of generated images only.

    Args:
        output_images: One of three forms:
            - list of (stem, centerline_np, generated_np) tuples returned by
              run_stage2_inference()  →  shows input/output pairs
            - str folder path containing *_recon.png files  →  shows pairs if
              input_images folder is also provided, otherwise output-only grid
            - list of numpy arrays [H, W]  →  shows pairs if input_images is
              also a list of arrays, otherwise output-only grid

        input_images: Optional. Used when output_images is a folder path or
            array list. Either a matching folder path or a list of numpy arrays.

        pairs_per_row (int): Number of image pairs (or images) per row. Default 5.
        enhance_contrast (bool): Apply CLAHE to generated images for display. Default False.
        clip_limit (float): CLAHE clip limit (higher = more contrast). Default 2.0.
        bg_threshold (float): Display vmin in [0-255] scale. Pixels below this
            intensity appear black without modifying saved pixel values. Default None.
        dilate_centerline (int): Dilation radius for centerline display (makes thin
            lines visible at small sizes). 0 to disable. Default 1.
        normalize (bool): Apply percentile-based contrast normalization to generated
            images for display. Default False.
        norm_low (float): Lower percentile for normalization. Default 2.
        norm_high (float): Upper percentile for normalization. Default 98.
        save_figure (str): Path to save the figure (e.g. 'results.png'). If None,
            the figure is shown interactively. Default None.
        dpi (int): DPI for saved figure. Default 150.
    """
    # --- normalize inputs into display_items and has_pairs flag ---
    display_items = None
    has_pairs = False

    # Mode 1: direct result of run_stage2_inference — list of 3-tuples
    if (isinstance(output_images, list)
            and len(output_images) > 0
            and isinstance(output_images[0], tuple)
            and len(output_images[0]) == 3):
        display_items = output_images
        has_pairs = True

    # Mode 1b: list of (stem, gen_np) 2-tuples — output only with names
    elif (isinstance(output_images, list)
            and len(output_images) > 0
            and isinstance(output_images[0], tuple)
            and len(output_images[0]) == 2):
        display_items = output_images

    # Mode 2: folder path string
    elif isinstance(output_images, str) and os.path.isdir(output_images):
        recon_paths = sorted(glob.glob(os.path.join(output_images, "*_recon.png")))
        if not recon_paths:
            raise FileNotFoundError(
                f"No *_recon.png files found in: {output_images}"
            )

        if input_images is not None and isinstance(input_images, str) and os.path.isdir(input_images):
            # build stem→path map for inputs
            inp_map = {}
            for ext in ("*.png", "*.jpg", "*.jpeg", "*.tif", "*.tiff"):
                for p in glob.glob(os.path.join(input_images, ext)):
                    inp_stem = os.path.splitext(os.path.basename(p))[0]
                    inp_map[inp_stem] = p

            pairs = []
            for rp in recon_paths:
                recon_stem = os.path.splitext(os.path.basename(rp))[0]
                original_stem = recon_stem[:-6] if recon_stem.endswith("_recon") else recon_stem
                if original_stem in inp_map:
                    pairs.append((
                        original_stem,
                        _load_image_as_float(inp_map[original_stem]),
                        _load_image_as_float(rp),
                    ))
                else:
                    print(f"[WARN] No matching input for: {os.path.basename(rp)}")

            if pairs:
                display_items = pairs
                has_pairs = True
            else:
                display_items = [
                    (os.path.splitext(os.path.basename(p))[0], _load_image_as_float(p))
                    for p in recon_paths
                ]
        else:
            display_items = [
                (os.path.splitext(os.path.basename(p))[0], _load_image_as_float(p))
                for p in recon_paths
            ]

    # Mode 3: list of numpy arrays
    elif (isinstance(output_images, list)
          and len(output_images) > 0
          and isinstance(output_images[0], np.ndarray)):
        if (input_images is not None
                and isinstance(input_images, list)
                and len(input_images) > 0
                and isinstance(input_images[0], np.ndarray)):
            if len(input_images) != len(output_images):
                raise ValueError(
                    f"input_images and output_images must have equal length "
                    f"({len(input_images)} vs {len(output_images)})"
                )
            display_items = [
                (str(i), inp, out)
                for i, (inp, out) in enumerate(zip(input_images, output_images))
            ]
            has_pairs = True
        else:
            display_items = [(str(i), arr) for i, arr in enumerate(output_images)]

    else:
        raise TypeError(
            "output_images must be a list of (stem, cl_np, gen_np) tuples, "
            "a folder path string, or a list of numpy arrays. "
            f"Got: {type(output_images)}"
        )

    n = len(display_items)
    if n == 0:
        print("visualize_stage2_results: nothing to display.")
        return

    # --- layout ---
    n_col = min(pairs_per_row, n)
    n_bands = math.ceil(n / pairs_per_row)
    n_rows = n_bands * (2 if has_pairs else 1)

    cell_size = 3
    fig, axes = plt.subplots(
        n_rows, n_col,
        figsize=(n_col * cell_size, n_rows * cell_size),
        gridspec_kw={'hspace': 0.05, 'wspace': 0.05},
    )

    # normalize axes to always be 2-D
    if n_rows == 1 and n_col == 1:
        axes = np.array([[axes]])
    elif n_rows == 1:
        axes = axes[np.newaxis, :]
    elif n_col == 1:
        axes = axes[:, np.newaxis]

    # hide all cells first
    for r in range(n_rows):
        for c in range(n_col):
            axes[r, c].axis('off')

    # figure title
    title_parts = [f"Stage 2 Inference  |  {n} image{'s' if n > 1 else ''}"]
    if normalize:
        title_parts.append(f"norm p{norm_low}-p{norm_high}")
    if enhance_contrast:
        title_parts.append(f"CLAHE clip={clip_limit}")
    if bg_threshold is not None:
        title_parts.append(f"BG threshold={bg_threshold}/255 (display range)")
    fig.suptitle("  |  ".join(title_parts), fontsize=11, y=1.005)

    vmin_gen = (bg_threshold / 255.0) if bg_threshold is not None else 0.0

    for idx, item in enumerate(display_items):
        band = idx // pairs_per_row
        col = idx % pairs_per_row
        short = item[0] if len(item[0]) <= 20 else item[0][:9] + '…' + item[0][-9:]

        if has_pairs:
            _, cl_np, gen_np = item
            row_cl = band * 2
            row_gen = band * 2 + 1

            cl_disp = _dilate_for_display(cl_np, radius=dilate_centerline) \
                if dilate_centerline > 0 else cl_np.copy()

            gen_disp = gen_np.copy()
            if normalize:
                gen_disp = _normalize_percentile(gen_disp, low=norm_low, high=norm_high)
            if enhance_contrast:
                gen_disp = _enhance_clahe(gen_disp, clip_limit=clip_limit)

            ax_cl = axes[row_cl, col]
            ax_cl.imshow(cl_disp, cmap='gray', vmin=0, vmax=1, interpolation='nearest')
            ax_cl.axis('off')
            ax_cl.set_title(short, fontsize=7, pad=3)
            if col == 0:
                ax_cl.set_ylabel("Centerline", fontsize=8, labelpad=4)
                ax_cl.yaxis.set_label_position('left')
                axes[row_gen, col].set_ylabel("Generated", fontsize=8, labelpad=4)
                axes[row_gen, col].yaxis.set_label_position('left')

            ax_gen = axes[row_gen, col]
            ax_gen.imshow(gen_disp, cmap='gray', vmin=vmin_gen, vmax=1, interpolation='lanczos')
            ax_gen.axis('off')

        else:
            _, gen_np = item
            row_gen = band

            gen_disp = gen_np.copy()
            if normalize:
                gen_disp = _normalize_percentile(gen_disp, low=norm_low, high=norm_high)
            if enhance_contrast:
                gen_disp = _enhance_clahe(gen_disp, clip_limit=clip_limit)

            ax_gen = axes[row_gen, col]
            ax_gen.imshow(gen_disp, cmap='gray', vmin=vmin_gen, vmax=1, interpolation='lanczos')
            ax_gen.axis('off')
            ax_gen.set_title(short, fontsize=7, pad=3)
            if col == 0:
                ax_gen.set_ylabel("Generated", fontsize=8, labelpad=4)
                ax_gen.yaxis.set_label_position('left')

    plt.tight_layout()

    if save_figure:
        fig_dir = os.path.dirname(os.path.abspath(save_figure))
        if fig_dir:
            os.makedirs(fig_dir, exist_ok=True)
        plt.savefig(save_figure, dpi=dpi, bbox_inches='tight')
        print(f"Figure saved: {save_figure}")
    else:
        plt.show()
