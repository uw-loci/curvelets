
from __future__ import annotations

import numpy as np
from PIL import Image, ImageOps
from scipy.ndimage import distance_transform_edt, gaussian_filter

from core.abort import _raise_if_aborted

class ImageUtility:

    @staticmethod
    def distance_function(image, falloff, abort_check=None):
        if image.mode != 'L':
            raise ValueError("Image must be in 'L' mode (8-bit pixels, black and white)")

        _raise_if_aborted(abort_check)
        input_array = np.array(image, dtype=np.uint8)
        foreground = input_array > 0
        if not np.any(foreground):
            return Image.fromarray(np.zeros_like(input_array))

        distances = distance_transform_edt(foreground)
        base = np.where(
            foreground,
            np.maximum(distances * float(falloff), 255.0 * (distances <= 0)),
            0.0,
        )
        scale = input_array.astype(np.float32) / 255.0
        output_array = np.clip(base * scale, 0, 255).astype(np.uint8)
        return Image.fromarray(output_array)

    @staticmethod
    def gaussian_blur(image, radius):
        input_array = np.array(image)
        output_array = gaussian_filter(input_array, sigma=radius / 3.0)
        return Image.fromarray(output_array)

    @staticmethod
    def scale(image, ratio, interpolation=Image.BILINEAR):
        new_size = (int(image.width * ratio), int(image.height * ratio))
        return image.resize(new_size, resample=interpolation)

    @staticmethod
    def cap(image, max_value):
        if image.mode != 'L':
            raise ValueError("Image must be in 'L' mode (8-bit pixels, black and white)")

        input_array = np.array(image)
        output_array = np.clip(input_array, 0, max_value)
        return Image.fromarray(output_array)

    @staticmethod
    def normalize(image, max_value):
        np_image = np.array(image).astype(np.float32)
        np_image = np_image / np_image.max() * max_value
        return Image.fromarray(np.clip(np_image, 0, max_value).astype(np.uint8))

    @staticmethod
    def zero_pad(image, pad):
        return ImageOps.expand(image, border=pad, fill=0)
