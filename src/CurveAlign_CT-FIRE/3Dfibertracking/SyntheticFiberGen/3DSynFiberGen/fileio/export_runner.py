from __future__ import annotations

import os

from export.builders import build_canonical_sample, build_dataset_manifest_rows
from export.writers import export_canonical_research_package, write_dataset_manifest
from generation.sample_2d import FiberImage
from generation.sample_3d import FiberImage3D


class ExportRunner2D:
    def write_results(self, collection, out_folder: str):
        os.makedirs(out_folder, exist_ok=True)

        dataset_rows = []
        for i in range(collection.size()):
            fiber_image = collection.get(i)
            fiber_image.ensure_joints()
            centerline_mask = (
                fiber_image.render_centerline_label_2d()
                if FiberImage.should_generate_centerline_label(fiber_image.params)
                else None
            )
            fiber_render = None
            if FiberImage.should_generate_fiber_image(fiber_image.params):
                base_image = fiber_image.render_fiber_image_2d()
                fiber_render = FiberImage.apply_postprocessing_2d(base_image, fiber_image.params)
            sample_name = f"2d_sample_{i:03d}"
            sample_dir = os.path.join(out_folder, sample_name)
            sample = build_canonical_sample(
                fiber_image,
                image_id=sample_name,
                sample_id=sample_name,
                centerline_mask=centerline_mask,
                fiber_image_array=fiber_render,
            )
            export_canonical_research_package(sample_dir, sample, include_excel=True)
            dataset_rows.append(build_dataset_manifest_rows(sample, sample_dir))
        if dataset_rows:
            write_dataset_manifest(out_folder, dataset_rows)


class ExportRunner3D:
    def write_results(self, collection, out_folder: str):
        os.makedirs(out_folder, exist_ok=True)

        dataset_rows = []
        for i in range(collection.size()):
            fiber_image = collection.get(i)
            centerline_mask = (
                fiber_image.render_centerline_volume_3d()
                if FiberImage3D.should_generate_centerline_label(fiber_image.params)
                else None
            )
            base_volume = (
                fiber_image.render_fiber_volume_3d()
                if FiberImage3D.should_generate_fiber_image(fiber_image.params)
                else None
            )
            if centerline_mask is not None or base_volume is not None:
                fiber_image.calculate_validation_metrics_3d(
                    fiber_volume=base_volume,
                    centerline_volume=centerline_mask,
                )
            fiber_render = (
                FiberImage3D.apply_postprocessing_3d(base_volume, fiber_image.params)
                if base_volume is not None
                else None
            )
            sample_name = f"3d_sample_{i:03d}"
            sample_dir = os.path.join(out_folder, sample_name)
            sample = build_canonical_sample(
                fiber_image,
                image_id=sample_name,
                sample_id=sample_name,
                centerline_mask=centerline_mask,
                fiber_image_array=fiber_render,
            )
            export_canonical_research_package(sample_dir, sample, include_excel=True)
            dataset_rows.append(build_dataset_manifest_rows(sample, sample_dir))
        if dataset_rows:
            write_dataset_manifest(out_folder, dataset_rows)
