
from __future__ import annotations

import numpy as np
from scipy.signal import fftconvolve

from core.abort import _raise_if_aborted
from postprocess.psf_kernels import generate_psf_gaussian, generate_psf_vectorial

LAST_PSF_STATS = None


def get_last_psf_stats():
    return LAST_PSF_STATS


def set_last_psf_stats(stats):
    global LAST_PSF_STATS
    LAST_PSF_STATS = stats

class PSFManager:
    """Encapsulates PSF parameter handling, kernel caching, and convolution helpers."""

    MAX_PSF_SIZE = 129

    def __init__(self, params):
        self.params = params
        self._cache = getattr(self.params, "_psf_cache", {})

    def apply(self, data: np.ndarray, volume: bool, abort_check=None):
        """
        Convolve data with the configured PSF.

        Args:
            data: Numpy array representing either a 2D image (H, W) or 3D volume (Z, Y, X).
            volume: True for 3D data, False for 2D.

        Returns:
            uint8 array with the same shape as the input, or None if PSF is disabled.
        """
        kernel = self.get_kernel()
        if kernel is None:
            return None

        _raise_if_aborted(abort_check)
        np_data = np.asarray(data, dtype=np.float32)
        np_data -= np_data.min()
        max_val = np_data.max()
        if max_val > 0:
            np_data /= max_val

        if volume:
            psf = kernel
        else:
            psf = kernel[kernel.shape[0] // 2]
            psf_sum = psf.sum()
            if psf_sum <= 0:
                return None
            psf = psf / psf_sum

        _raise_if_aborted(abort_check)
        convolved = fftconvolve(np_data, psf, mode="same")
        _raise_if_aborted(abort_check)
        convolved = np.clip(convolved, 0.0, None)
        convolved -= convolved.min()
        conv_max = convolved.max()
        if conv_max > 0:
            convolved /= conv_max
        return (convolved * 255.0).astype(np.uint8)

    # ------------------------------------------------------------------
    # Internal helpers

    def get_kernel(self):
        if not self._psf_is_enabled():
            return None

        psf_mode = self._normalized_psf_type()

        if psf_mode == "gaussian":
            shape, voxel_size = self._gaussian_psf_parameters()
            key = (
                "gaussian",
                tuple(shape),
                tuple(round(v, 6) for v in voxel_size),
                round(float(self.params.psfGaussianNA.get_value()), 6),
                round(float(self.params.psfGaussianWavelength.get_value()), 6),
            )
            kernel = self._cache.get(key)
            if kernel is None:
                kernel = generate_psf_gaussian(
                    shape,
                    voxel_size,
                    float(self.params.psfGaussianNA.get_value()),
                    float(self.params.psfGaussianWavelength.get_value()),
                )
                self._cache[key] = kernel
        elif psf_mode == "vectorial":
            dims_um, shape_pix = self._vectorial_psf_parameters()
            key = (
                "vectorial",
                tuple(round(v, 4) for v in dims_um),
                tuple(shape_pix),
                round(float(self.params.psfVectorialNA.get_value()), 6),
                round(float(self.params.psfVectorialMediumRI.get_value()), 6),
                round(float(self.params.psfVectorialSampleRI.get_value()), 6),
                round(float(self.params.psfVectorialWavelength.get_value()), 6),
                round(float(self.params.psfVectorialPolarization.get_value()), 6),
            )
            kernel = self._cache.get(key)
            if kernel is None:
                kernel = generate_psf_vectorial(
                    {
                        "NA": float(self.params.psfVectorialNA.get_value()),
                        "n_medium": float(self.params.psfVectorialMediumRI.get_value()),
                        "n_sample": float(self.params.psfVectorialSampleRI.get_value()),
                        "wavelength_um": float(self.params.psfVectorialWavelength.get_value()),
                        "polarization_angle_deg": float(self.params.psfVectorialPolarization.get_value()),
                        "dims_um": dims_um,
                        "shape_pix": shape_pix,
                    }
                )
                self._cache[key] = kernel
        else:
            kernel = None

        self.params._psf_cache = self._cache
        return kernel

    def _psf_is_enabled(self) -> bool:
        return (
            hasattr(self.params, "psfEnabled")
            and getattr(self.params.psfEnabled, "use", False)
            and self._normalized_psf_type() != "none"
        )

    def _normalized_psf_type(self) -> str:
        if not hasattr(self.params, "psfType"):
            return "none"
        value = str(self.params.psfType.get_value() or "").strip().lower()
        if "gaussian" in value:
            return "gaussian"
        if "vectorial" in value:
            return "vectorial"
        return "none"

    def _gaussian_psf_parameters(self):
        voxel_size = (
            float(self.params.psfPixelSizeZ.get_value()),
            float(self.params.psfPixelSizeY.get_value()),
            float(self.params.psfPixelSizeX.get_value()),
        )
        shape = self._auto_gaussian_shape(voxel_size)
        return shape, voxel_size

    def _auto_gaussian_shape(self, voxel_size):
        na = max(float(self.params.psfGaussianNA.get_value()), 1e-6)
        wavelength = max(float(self.params.psfGaussianWavelength.get_value()), 1e-6)
        dz, dy, dx = [max(v, 1e-6) for v in voxel_size]
        sigma_to_fwhm = 2.0 * np.sqrt(2.0 * np.log(2.0))
        fwhm_xy = 0.51 * wavelength / na
        fwhm_z = 0.88 * wavelength / (na * na)
        sigma_xy_um = max(fwhm_xy / sigma_to_fwhm, 1e-6)
        sigma_z_um = max(fwhm_z / sigma_to_fwhm, 1e-6)

        def radius(sigma_um, spacing_um):
            return max(1, int(np.ceil(3.0 * sigma_um / spacing_um)))

        rz = min(self.MAX_PSF_SIZE // 2, radius(sigma_z_um, dz))
        ry = min(self.MAX_PSF_SIZE // 2, radius(sigma_xy_um, dy))
        rx = min(self.MAX_PSF_SIZE // 2, radius(sigma_xy_um, dx))

        def to_odd(length):
            length = max(1, length * 2 + 1)
            if length % 2 == 0:
                length += 1
            return min(self.MAX_PSF_SIZE | 1, length)

        return (to_odd(rz), to_odd(ry), to_odd(rx))

    def _vectorial_psf_parameters(self):
        dims = (
            max(float(self.params.psfVectorialVolumeZ.get_value()), 1e-3),
            max(float(self.params.psfVectorialVolumeY.get_value()), 1e-3),
            max(float(self.params.psfVectorialVolumeX.get_value()), 1e-3),
        )

        def clamp_size(value):
            value = max(3, int(value))
            if value % 2 == 0:
                value += 1
            return min(self.MAX_PSF_SIZE | 1, value)

        shape = (
            clamp_size(self.params.psfVectorialShapeZ.get_value()),
            clamp_size(self.params.psfVectorialShapeY.get_value()),
            clamp_size(self.params.psfVectorialShapeX.get_value()),
        )
        return dims, shape
