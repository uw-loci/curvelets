import math
from typing import Dict, Iterable, Tuple, Union

import numpy as np
from scipy.integrate import simpson
from scipy.special import j0, j1, jv


ArrayLike3D = np.ndarray


def _ensure_tuple(value: Iterable, length: int) -> Tuple[float, ...]:
    seq = tuple(value)
    if len(seq) != length:
        raise ValueError(f"Expected {length} values, received {len(seq)}")
    return seq


def generate_psf_gaussian(
    shape_pix: Tuple[int, int, int],
    voxel_size_um: Tuple[float, float, float],
    NA: float,
    wavelength_um: float,
) -> ArrayLike3D:
    """
    Generate an approximate 3D Gaussian PSF kernel.

    Args:
        shape_pix: Kernel shape in pixels as (z, y, x). Each dimension must be >= 1.
        voxel_size_um: Physical spacing between voxels in microns (z, y, x).
        NA: Numerical aperture of the objective.
        wavelength_um: Excitation wavelength in microns.

    Returns:
        Normalized PSF kernel whose sum equals 1.0.
    """
    z_pix, y_pix, x_pix = _ensure_tuple(shape_pix, 3)
    dz, dy, dx = _ensure_tuple(voxel_size_um, 3)

    if NA <= 0 or wavelength_um <= 0:
        raise ValueError("NA and wavelength must be positive.")

    z_pix = max(int(z_pix), 1)
    y_pix = max(int(y_pix), 1)
    x_pix = max(int(x_pix), 1)

    dz = max(float(dz), 1e-6)
    dy = max(float(dy), 1e-6)
    dx = max(float(dx), 1e-6)

    # Convert FWHM (Richards & Wolf) to sigma in microns
    sigma_to_fwhm = 2.0 * math.sqrt(2.0 * math.log(2.0))
    fwhm_xy = 0.51 * wavelength_um / NA
    fwhm_z = 0.88 * wavelength_um / (NA * NA)
    sigma_xy_um = max(fwhm_xy / sigma_to_fwhm, 1e-6)
    sigma_z_um = max(fwhm_z / sigma_to_fwhm, 1e-6)

    z_axis = (np.arange(z_pix) - (z_pix - 1) / 2.0) * dz
    y_axis = (np.arange(y_pix) - (y_pix - 1) / 2.0) * dy
    x_axis = (np.arange(x_pix) - (x_pix - 1) / 2.0) * dx

    zz, yy, xx = np.meshgrid(z_axis, y_axis, x_axis, indexing="ij")

    psf = np.exp(
        -0.5
        * (
            (zz / sigma_z_um) ** 2
            + (yy / sigma_xy_um) ** 2
            + (xx / sigma_xy_um) ** 2
        )
    )

    psf_sum = psf.sum()
    if psf_sum <= 0:
        raise ValueError("Generated Gaussian PSF has zero total energy.")
    return (psf / psf_sum).astype(np.float32)


def generate_psf_vectorial(
    params: Dict[str, Union[float, Tuple[float, float, float]]]
) -> ArrayLike3D:
    """
    Create a high-fidelity vectorial (Richards–Wolf) PSF suitable for SHG imaging.

    Required keys in params:
        - NA: Numerical aperture
        - n_medium: Refractive index of immersion medium
        - n_sample: Refractive index of the sample
        - wavelength_um: Excitation wavelength (microns)
        - polarization_angle_deg: Input polarization angle (degrees)
        - dims_um: Tuple(float) of physical extents (z, y, x) in microns
        - shape_pix: Tuple(int) of output samples (z, y, x)

    Returns:
        Normalized |E|^4 SHG PSF volume (sum equals 1.0).
    """
    required = (
        "NA",
        "n_medium",
        "n_sample",
        "wavelength_um",
        "polarization_angle_deg",
        "dims_um",
        "shape_pix",
    )
    for key in required:
        if key not in params:
            raise ValueError(f"Missing parameter '{key}' for vectorial PSF generation.")

    NA = float(params["NA"])
    n_medium = float(params["n_medium"])
    n_sample = float(params["n_sample"])
    wavelength_um = float(params["wavelength_um"])
    polarization_angle = math.radians(float(params["polarization_angle_deg"]))
    dims_um = _ensure_tuple(params["dims_um"], 3)
    shape_pix = tuple(int(max(1, int(v))) for v in _ensure_tuple(params["shape_pix"], 3))

    if wavelength_um <= 0:
        raise ValueError("Excitation wavelength must be positive.")
    if NA <= 0:
        raise ValueError("NA must be positive.")
    if NA >= n_medium:
        NA = 0.9999 * n_medium  # Clamp to stay within physical limits

    z_dim, y_dim, x_dim = dims_um
    z_pix, y_pix, x_pix = shape_pix

    z_axis = np.linspace(-z_dim / 2.0, z_dim / 2.0, z_pix)
    y_axis = np.linspace(-y_dim / 2.0, y_dim / 2.0, y_pix)
    x_axis = np.linspace(-x_dim / 2.0, x_dim / 2.0, x_pix)

    zz, yy, xx = np.meshgrid(z_axis, y_axis, x_axis, indexing="ij")
    rho = np.sqrt(xx**2 + yy**2)
    phi = np.arctan2(yy, xx)

    k0 = 2.0 * math.pi / wavelength_um
    k_medium = k0 * n_medium
    k_sample = k0 * n_sample
    alpha = math.asin(NA / n_medium)
    A = (math.pi * k_medium) / (wavelength_um * (n_medium**2))

    integration_steps = max(30, min(80, int(50 * NA)))
    theta_vec = np.linspace(0.0, alpha, integration_steps)
    theta_grid, _, _, _ = np.meshgrid(
        theta_vec, z_axis, y_axis, x_axis, indexing="ij", sparse=True
    )

    cos_theta = np.cos(theta_grid)
    sin_theta = np.sin(theta_grid)
    apodization = np.sqrt(np.clip(cos_theta, 1e-6, None))

    phase = np.exp(1j * k_sample * zz * cos_theta)
    common = A * apodization * sin_theta * (1 + cos_theta) * phase

    argument = k_sample * rho * sin_theta
    I0 = simpson(common * j0(argument), theta_vec, axis=0)
    I1 = simpson(common * j1(argument), theta_vec, axis=0)
    I2 = simpson(common * jv(2, argument), theta_vec, axis=0)

    Ex = I0 + I2 * np.cos(2.0 * (phi - polarization_angle))
    Ey = I2 * np.sin(2.0 * (phi - polarization_angle))
    Ez = -2j * I1 * np.cos(phi - polarization_angle)

    intensity = np.real(
        Ex * np.conj(Ex) + Ey * np.conj(Ey) + Ez * np.conj(Ez)
    )
    shg_psf = intensity**2  # SHG ~ |E|^4
    shg_sum = shg_psf.sum()
    if shg_sum <= 0:
        raise ValueError("Vectorial PSF computation produced zero energy.")
    return (shg_psf / shg_sum).astype(np.float32)


__all__ = ["generate_psf_gaussian", "generate_psf_vectorial"]
