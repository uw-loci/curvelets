from __future__ import annotations

import numpy as np
from PIL import Image, ImageDraw

from core.abort import _raise_if_aborted

TARGET_SCALE_SIZE = 0.2
CAP_RATIO = 0.01
BUFF_RATIO = 0.015


def get_mask_line_width(params):
    try:
        width_value = int(round(float(getattr(params.centerlineMaskWidthPx, "value", 1))))
    except (TypeError, ValueError):
        width_value = 1
    return max(1, width_value)


def render_fibers_to_image(
    fibers,
    size,
    default_intensity=255.0,
    binary=False,
    line_width_override=None,
    abort_check=None,
):
    width, height = size
    base = np.zeros((height, width), dtype=np.float32)
    for fiber_index, fiber in enumerate(fibers):
        if fiber_index % 8 == 0:
            _raise_if_aborted(abort_check)
        intensity = 255.0 if binary else getattr(fiber, "intensity", default_intensity)
        if intensity is None:
            intensity = default_intensity
        try:
            intensity = float(intensity)
        except (TypeError, ValueError):
            intensity = default_intensity
        if intensity <= 0:
            continue
        intensity = max(0.0, min(255.0, intensity))
        overlay = Image.new("L", (width, height), 0)
        draw = ImageDraw.Draw(overlay)
        for segment_index, segment in enumerate(fiber):
            if segment_index % 32 == 0:
                _raise_if_aborted(abort_check)
            if line_width_override is not None:
                line_width = max(1, int(round(float(line_width_override))))
            else:
                line_width = max(1, int(round(float(segment.width))))
            draw.line(
                [(segment.start.x, segment.start.y), (segment.end.x, segment.end.y)],
                fill=int(round(intensity)),
                width=line_width,
            )
        overlay_np = np.array(overlay, dtype=np.float32)
        if binary:
            base = np.maximum(base, overlay_np)
        else:
            base += overlay_np
    base = np.clip(base, 0, 255).astype(np.uint8)
    return Image.fromarray(base, "L")


def format_scale_bar_label(length_um):
    if np.isclose(length_um, round(length_um)):
        return f"{int(round(length_um))} um"
    if 1e-2 <= abs(length_um) < 1e3:
        compact = f"{length_um:.2f}".rstrip("0").rstrip(".")
        return f"{compact} um"
    return f"{length_um:.1e} um"


def compute_scale_bar_spec(
    image_width,
    image_height,
    pixels_per_micron,
    target_scale_size=TARGET_SCALE_SIZE,
    cap_ratio=CAP_RATIO,
    buff_ratio=BUFF_RATIO,
):
    if pixels_per_micron <= 0:
        raise ValueError("Scale must be greater than zero.")

    target_size_um = target_scale_size * image_width / pixels_per_micron
    floor_pow = np.floor(np.log10(target_size_um))
    options = [10**floor_pow, 5 * 10**floor_pow, 10**(floor_pow + 1)]
    best_size_um = float(min(options, key=lambda x: abs(target_size_um - x)))

    cap_size = int(cap_ratio * image_height)
    x_buff = int(buff_ratio * image_width)
    y_buff = int(buff_ratio * image_height)
    scale_height = image_height - y_buff - cap_size
    scale_right = x_buff + int(best_size_um * pixels_per_micron)
    return {
        "label": format_scale_bar_label(best_size_um),
        "left": x_buff,
        "right": scale_right,
        "height": scale_height,
        "cap_size": cap_size,
        "text_x": x_buff,
        "text_y": scale_height - cap_size - y_buff,
        "physical_length_um": best_size_um,
    }


def draw_scale_bar_on_image(
    image,
    params,
    target_scale_size=TARGET_SCALE_SIZE,
    cap_ratio=CAP_RATIO,
    buff_ratio=BUFF_RATIO,
):
    if not hasattr(params, "scale") or not params.scale.use:
        return image
    output = image.copy()
    spec = compute_scale_bar_spec(
        output.width,
        output.height,
        float(params.scale.get_value()),
        target_scale_size=target_scale_size,
        cap_ratio=cap_ratio,
        buff_ratio=buff_ratio,
    )

    draw = ImageDraw.Draw(output)
    draw.line((spec["left"], spec["height"], spec["right"], spec["height"]), fill=255)
    draw.line(
        (spec["left"], spec["height"] + spec["cap_size"], spec["left"], spec["height"] - spec["cap_size"]),
        fill=255,
    )
    draw.line(
        (spec["right"], spec["height"] + spec["cap_size"], spec["right"], spec["height"] - spec["cap_size"]),
        fill=255,
    )
    draw.text((spec["text_x"], spec["text_y"]), spec["label"], fill=255)
    return output


__all__ = [
    "BUFF_RATIO",
    "CAP_RATIO",
    "TARGET_SCALE_SIZE",
    "compute_scale_bar_spec",
    "draw_scale_bar_on_image",
    "format_scale_bar_label",
    "get_mask_line_width",
    "render_fibers_to_image",
]
