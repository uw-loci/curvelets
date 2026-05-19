
from __future__ import annotations

import time

from fileio.params_io import DEFAULT_2D_PATH, DEFAULT_3D_PATH, load_params_2d_file, load_params_3d_file
from generation.collections import ImageCollection, ImageCollection3D


def _run_2d():
    params = load_params_2d_file(str(DEFAULT_2D_PATH))
    params.nImages.value = 1
    collection = ImageCollection(params)
    start = time.perf_counter()
    collection.generate_images()
    return time.perf_counter() - start


def _run_3d():
    params = load_params_3d_file(str(DEFAULT_3D_PATH))
    params.nImages.value = 1
    collection = ImageCollection3D(params)
    start = time.perf_counter()
    collection.generate_images_3d()
    return time.perf_counter() - start


if __name__ == '__main__':
    print(f'2D generation: {_run_2d():.3f}s')
    print(f'3D generation: {_run_3d():.3f}s')
