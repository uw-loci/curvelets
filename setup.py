import os

from pathlib import Path
from setuptools import setup
from pybind11.setup_helpers import Pybind11Extension, build_ext

try:
    FFTW = os.environ["FFTW"]
except KeyError:
    print("FFTW environment issue")

try:
    FDCT = os.environ["FDCT"]
except KeyError:
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
    name="fdct_wrapper",
    version=0.1,
    author="Dong Woo Lee",
    ext_modules=ext_modules,
    cmdclass={"build_ext": build_ext},
    install_requires=[
        "numpy>=2.0.1",
        "scipy>=1.14.1; python_version>='3.10'",
        "matplotlib",
    ],
    setup_requires=[
        "pybind11>=2.6.0",
        "setuptools_scm",
    ],
)
