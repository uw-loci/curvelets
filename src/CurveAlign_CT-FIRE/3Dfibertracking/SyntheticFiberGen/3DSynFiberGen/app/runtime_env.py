from __future__ import annotations

import os
from pathlib import Path


def configure_runtime_environment():
    project_root = Path(__file__).resolve().parent.parent
    cache_root = project_root / ".runtime_cache"
    matplotlib_cache = cache_root / "matplotlib"

    cache_root.mkdir(parents=True, exist_ok=True)
    matplotlib_cache.mkdir(parents=True, exist_ok=True)

    os.environ.setdefault("XDG_CACHE_HOME", str(cache_root))
    os.environ.setdefault("MPLCONFIGDIR", str(matplotlib_cache))
    os.environ.setdefault("QT_API", "pyqt6")

