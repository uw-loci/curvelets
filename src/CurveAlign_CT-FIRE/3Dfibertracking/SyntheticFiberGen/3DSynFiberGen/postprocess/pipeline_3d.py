
from __future__ import annotations

import numpy as np
from scipy.ndimage import distance_transform_edt, gaussian_filter

from core.abort import _raise_if_aborted
from postprocess.pipeline_2d import ImageUtility

class ImageUtility3D(ImageUtility):

    @staticmethod
    def distance_function_3d(image, falloff, abort_check=None):
        _raise_if_aborted(abort_check)
        input_array = np.array(image, dtype=np.uint8)
        foreground = input_array > 0
        if not np.any(foreground):
            return np.zeros_like(input_array)

        distances = distance_transform_edt(foreground)
        base = np.where(
            foreground,
            np.maximum(distances * float(falloff), 255.0 * (distances <= 0)),
            0.0,
        )
        scale = input_array.astype(np.float32) / 255.0
        return np.clip(base * scale, 0, 255).astype(np.uint8)

    @staticmethod
    def gaussian_blur_3d(image, radius):
        input_array = np.array(image)
        output_array = gaussian_filter(input_array, sigma=radius / 3.0)
        return output_array

    @staticmethod
    def normalize_3d(image, max_value):
        np_image = np.array(image).astype(np.float32)
        np_image = np_image / np_image.max() * max_value
        return np.clip(np_image, 0, max_value).astype(np.uint8)

    @staticmethod
    def cap_3d(image, max_value):
        input_array = np.array(image)
        output_array = np.clip(input_array, 0, max_value)
        return output_array

    @staticmethod
    def zero_pad_3d(image, pad):
        return np.pad(image, pad, mode='constant', constant_values=0)
