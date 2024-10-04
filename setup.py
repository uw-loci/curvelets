import os

from pathlib import Path
from setuptools import setup, find_packages
from pybind11.setup_helpers import Pybind11Extension, build_ext

# change path to the respective folder for FDCT #
FDCT_path = "~/opt/CurveLab-2.1.3"
# --------------------------------------------- #

FFTW = os.path.abspath(os.environ.get("FFTW", "./cpp/fftw-3.3.10"))
FDCT = os.path.expanduser(os.environ.get("FDCT", FDCT_path))

if not os.path.exists(FFTW):
    raise FileNotFoundError(f"FFTW path not found: {FFTW}")

if not os.path.exists(FDCT):
    raise FileNotFoundError(f"FDCT path not found: {FDCT}")

ext_modules = [
    Pybind11Extension(
        "fdct2d_wrapper",
        sources=[os.path.join("cpp", "fdct2d_wrapper.cpp")],
        include_dirs=[
            os.path.join(FFTW, "api"),
            os.path.join(FDCT, "fdct_wrapping_cpp", "src"),
        ],
        libraries=["fftw3"],
        library_dirs=[
            os.path.join(FFTW, ".libs"),
        ],
        language="c++",
        extra_compile_args=["-O3"],
    ),
    Pybind11Extension(
        "fdct3d_wrapper",
        sources=[os.path.join("cpp", "fdct3d_wrapper.cpp")],
        include_dirs=[
            os.path.join(FFTW, "api"),
            os.path.join(FDCT, "fdct3d", "src"),
        ],
        libraries=["fftw3"],
        library_dirs=[
            os.path.join(FFTW, ".libs"),
        ],
        language="c++",
        extra_compile_args=["-O3"],
    ),
]

setup(
    name="pycurvelets",
    version=0.1,
    author="Dong Woo Lee",
    packages=find_packages(),
    ext_package="pycurvelets",
    ext_modules=ext_modules,
    cmdclass={"build_ext": build_ext},
    python_requires=">=3.9",
    install_requires=[
        "numpy>=2.0.1",
        "scipy>=1.13; python_version>='3.9'",
        "matplotlib",
    ],
    setup_requires=[
        "pybind11>=2.6.0",
        "setuptools_scm",
    ],
)
