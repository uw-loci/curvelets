from __future__ import annotations

from copy import deepcopy
import multiprocessing as mp
import os
import time

import numpy as np

from core.abort import GenerationAborted
from core.rng import RngUtility
from generation.sample_2d import FiberImage
from generation.sample_3d import FiberImage3D


def should_use_parallel_batch(n_images: int) -> bool:
    return int(n_images) > 1 and (os.cpu_count() or 1) > 1


def _derive_sample_seed(base_seed, index: int):
    if base_seed is None:
        return None
    sequence = np.random.SeedSequence([int(base_seed), int(index)])
    return int(sequence.generate_state(1, dtype=np.uint32)[0])


def _generate_single_sample(task):
    params = deepcopy(task["params"])
    seed = task["seed"]
    index = int(task["index"])
    is_3d_mode = bool(task["is_3d_mode"])

    if hasattr(params, "nImages"):
        params.nImages.value = 1
    if hasattr(params, "seed"):
        params.seed.use = seed is not None
        if seed is not None:
            params.seed.value = int(seed)

    if seed is not None:
        RngUtility.rng.seed(seed)
        np.random.seed(seed)

    if is_3d_mode:
        sample = FiberImage3D(params)
        sample.generate_fibers_3d()
        sample.smooth_3d()
        timing_summary = {
            "generation_seconds": float(sample.performance_timings.get("generate_fibers_3d_seconds", 0.0)),
            "smoothing_seconds": float(sample.performance_timings.get("smooth_3d_seconds", 0.0)),
        }
    else:
        sample = FiberImage(params)
        sample.generate_fibers()
        sample.smooth()
        timing_summary = {
            "generation_seconds": float(sample.performance_timings.get("generate_fibers_2d_seconds", 0.0)),
            "joint_count_seconds": float(sample.performance_timings.get("joint_count_2d_seconds", 0.0)),
            "smoothing_seconds": float(sample.performance_timings.get("smooth_2d_seconds", 0.0)),
        }

    return index, sample, timing_summary


def _resolve_worker_count(n_images: int, max_workers=None) -> int:
    available = os.cpu_count() or 1
    if max_workers is None:
        return max(1, min(int(n_images), available))
    return max(1, min(int(n_images), int(max_workers), available))


def generate_parallel_batch(params, is_3d_mode: bool, abort_check=None, max_workers=None):
    n_images = int(params.nImages.get_value())
    worker_count = _resolve_worker_count(n_images, max_workers=max_workers)
    base_seed = int(params.seed.value) if getattr(params.seed, "use", False) else None
    tasks = [
        {
            "index": index,
            "params": params,
            "seed": _derive_sample_seed(base_seed, index),
            "is_3d_mode": is_3d_mode,
        }
        for index in range(n_images)
    ]

    total_start = time.perf_counter()
    samples = [None] * n_images
    stage_totals = {
        "generation_seconds": 0.0,
        "smoothing_seconds": 0.0,
    }
    if not is_3d_mode:
        stage_totals["joint_count_seconds"] = 0.0

    ctx = mp.get_context("spawn")
    pool = ctx.Pool(processes=worker_count)
    async_results = []
    try:
        for task in tasks:
            async_results.append(pool.apply_async(_generate_single_sample, (task,)))
        pool.close()

        pending = set(range(len(async_results)))
        while pending:
            if abort_check is not None and abort_check():
                pool.terminate()
                pool.join()
                raise GenerationAborted()

            progressed = False
            for result_index in list(pending):
                async_result = async_results[result_index]
                if not async_result.ready():
                    continue
                index, sample, timing_summary = async_result.get()
                samples[index] = sample
                for key, value in timing_summary.items():
                    stage_totals[key] = stage_totals.get(key, 0.0) + float(value)
                pending.remove(result_index)
                progressed = True

            if pending and not progressed:
                time.sleep(0.05)

        pool.join()
    except Exception:
        try:
            pool.terminate()
            pool.join()
        except Exception:
            pass
        raise

    timing_summary = {"total_seconds": float(time.perf_counter() - total_start)}
    timing_summary.update({key: float(value) for key, value in stage_totals.items()})
    return samples, timing_summary
