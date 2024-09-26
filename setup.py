import os

from pathlib import Path
from setuptools import setup, find_packages
from pybind11.setup_helpers import Pybind11Extension, build_ext

# change paths to the respective folders
FFTW_path = "~/opt/fftw-3.3.10"
FDCT_path = "~/opt/CurveLab-2.1.3"

FFTW = os.environ.get("FFTW", FFTW_path)
FDCT = os.environ.get("FDCT", FDCT_path)

if not os.path.exists(FFTW):
    print("FFTW environment issue")

if not os.path.exists(FDCT):
    print("FDCT environment issue")

ext_modules = [
    Pybind11Extension(
        "fdct2d_wrapper",
        sources=["./cpp/fdct2d_wrapper.cpp"],
        include_dirs=["include", os.path.join(FFTW, "include")],
        libraries=["fftw3"],
        library_dirs=[
            os.path.join(FFTW, "lib"),
            os.path.join(FDCT, "fdct_wrapping_cpp"),
        ],
        language="c++",
        extra_compile_args=["-O3"],
    ),
    Pybind11Extension(
        "fdct3d_wrapper",
        sources=["./cpp/fdct3d_wrapper.cpp"],
        include_dirs=["include", os.path.join(FFTW, "include")],
        libraries=["fftw3"],
        library_dirs=[
            os.path.join(FFTW, "lib"),
            os.path.join(FDCT, "fdct3d"),
        ],
        language="c++",
        extra_compile_args=["-O3"],
    ),
]

setup(
    name="pycurvelets",
    version=0.1,
    author="Dong Woo Lee",
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
