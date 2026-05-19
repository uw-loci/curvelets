"""
run_example.py
--------------
Quick-start example: run Stage 2 cGAN inference on the centerline images in
this folder, save the generated images, and produce two figures:
  - results_pairs.png   : centerline (top) + generated image (bottom) for each input
  - results_output.png  : generated images only

Run from the collagen_stage2_inference/ directory:
    python example/run_example.py
"""

import os
import sys

# allow imports from the distribution root regardless of working directory
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from stage2_inference_viz import run_stage2_inference, visualize_stage2_results

DIST_ROOT    = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INPUT_DIR    = os.path.join(DIST_ROOT, "example", "data")
MODEL_DIR    = os.path.join(DIST_ROOT, "model")
OUTPUT_DIR   = os.path.join(DIST_ROOT, "example", "output")
PAIRS_FIG    = os.path.join(OUTPUT_DIR, "results_pairs.png")
OUTPUT_FIG   = os.path.join(OUTPUT_DIR, "results_output.png")

# --- 1. Run inference ---
results = run_stage2_inference(
    centerline_images_path=INPUT_DIR,
    model_path=MODEL_DIR,
    output_path=OUTPUT_DIR,
    save_output=True,
)

print(f"\nProcessed {len(results)} image(s).")
for stem, cl_np, gen_np in results:
    print(f"  {stem}: centerline {cl_np.shape}, generated {gen_np.shape}")

# --- 2a. Visualize input/output pairs (centerline top, generated bottom) ---
visualize_stage2_results(
    results,
    normalize=True,
    norm_low=2,
    norm_high=98,
    dilate_centerline=1,
    save_figure=PAIRS_FIG,
    dpi=150,
)
print(f"\nPairs figure saved:  {PAIRS_FIG}")

# --- 2b. Visualize generated images only ---
visualize_stage2_results(
    [(stem, gen_np) for stem, _, gen_np in results],  # drop centerline arrays
    normalize=True,
    norm_low=2,
    norm_high=98,
    save_figure=OUTPUT_FIG,
    dpi=150,
)
print(f"Output figure saved: {OUTPUT_FIG}")
print(f"Generated images in: {OUTPUT_DIR}")
