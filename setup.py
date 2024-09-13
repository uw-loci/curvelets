import os
import sys

from pathlib import Path
from setuptools import find_packages, setup
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
        [str(fname) for fname in Path("src").glob("*.cpp")],
        include_dirs=["include"],
        libraries=["fftw"],
        library_dirs=[os.path.join(FFTW, "fftw", ".libs")],
        language="c++",
        extra_compile_args=["-O3"],
    ),
    Pybind11Extension(
        "fdct3d_wrapper",
        [str(fname) for fname in Path("src").glob("*.cpp")],
        include_dirs=["include"],
        libraries=["fftw"],
        library_dirs=[os.path.join(FDCT, "fdct", ".libs")],
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
        "pylops>=2.0",
    ],
    setup_requires=[
        "pybind11>=2.6.0",
        "setuptools_scm",
    ],
)
