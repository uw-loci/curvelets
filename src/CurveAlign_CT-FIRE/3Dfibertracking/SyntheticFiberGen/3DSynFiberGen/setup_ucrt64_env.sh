#!/usr/bin/env bash
# Run this script once from the MSYS2 UCRT64 terminal to create the Python
# environment for 3DSynFiberGen with ctfire_py support.
#
# Open the UCRT64 terminal from VS Code (Terminal → New Terminal → MSYS2 UCRT64)
# then run:  bash setup_ucrt64_env.sh
#
# Prerequisites:
#   1. MSYS2 installed at C:\msys64  (https://www.msys2.org)
#   2. Python 3.14 + scientific packages installed via pacman:
#        pacman -S mingw-w64-ucrt-x86_64-python \
#                   mingw-w64-ucrt-x86_64-python-numpy \
#                   mingw-w64-ucrt-x86_64-python-scipy \
#                   mingw-w64-ucrt-x86_64-python-pillow \
#                   mingw-w64-ucrt-x86_64-python-matplotlib \
#                   mingw-w64-ucrt-x86_64-python-vispy \
#                   mingw-w64-ucrt-x86_64-python-scikit-image
#   3. C:\msys64\ucrt64\bin added to Windows System PATH (for fiber_backend DLLs)
#      Control Panel → System → Advanced → Environment Variables → Path → New
#      Add: C:\msys64\ucrt64\bin

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "==> Creating .venv with UCRT64 Python 3.14 (inheriting pacman site-packages)..."
# --system-site-packages lets the venv use numpy/scipy/pillow/matplotlib
# installed via pacman, avoiding source-compilation from PyPI.
C:/msys64/ucrt64/bin/python3 -m venv --system-site-packages .venv

echo "==> Activating .venv..."
# MSYS2 Python creates bin/activate (Unix-style); Windows Python creates Scripts/activate
if [ -f .venv/bin/activate ]; then
    source .venv/bin/activate
else
    source .venv/Scripts/activate
fi

echo "==> Upgrading pip..."
python -m pip install --upgrade pip

echo "==> Installing 3DSynFiberGen base dependencies (no GUI — napari stays in the main app env)..."
# [gui] is excluded: vispy is not packaged for MSYS2 and would stall building from source.
# The UCRT64 venv only needs core + extractors to run run_ctfire_subprocess.py.
python -m pip install -e "."

echo "==> Adding ctfire_py to sys.path via .pth file..."
SITE=$(python -c "import site; print(site.getsitepackages()[0])")
CTFIRE_SRC="H:/GitHub.06.2022/tme-quant/src"
echo "$CTFIRE_SRC" > "$SITE/ctfire_src.pth"
echo "    Written: $SITE/ctfire_src.pth  ->  $CTFIRE_SRC"

echo "==> Verifying ctfire_py import..."
python -c "
import sys, types

# ctfire_py/ct_fire.py has top-level matplotlib imports; on MSYS2 UCRT64 the
# matplotlib._path C extension may fail with a DLL version mismatch.  Stub it
# out before importing ctfire_py (plotflag=0 never calls any matplotlib code).
def _stub_matplotlib():
    for _n in [
        'matplotlib', 'matplotlib.pyplot', 'matplotlib.cm',
        'matplotlib.colors', 'matplotlib.figure', 'matplotlib.transforms',
        'matplotlib.ticker', 'matplotlib.backends',
        'matplotlib.backends.backend_agg',
    ]:
        sys.modules[_n] = types.ModuleType(_n)

try:
    import matplotlib.pyplot
except (ImportError, OSError):
    _stub_matplotlib()

from ctfire_py import HAS_FIBER_BACKEND
if HAS_FIBER_BACKEND:
    from ctfire_py import fire_2d_angle
    print('ctfire_py OK — fiber_backend loaded')
else:
    print('WARNING: fiber_backend not loaded.')
    print('  Check that Python 3.14 is active and C:\\\\msys64\\\\ucrt64\\\\bin is on Windows PATH.')
"

echo ""
echo "Done. Set VS Code Python interpreter to .venv/bin/python.exe (or .venv/Scripts/python.exe)"
