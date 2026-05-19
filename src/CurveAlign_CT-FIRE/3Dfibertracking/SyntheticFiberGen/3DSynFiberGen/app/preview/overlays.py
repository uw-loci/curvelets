from __future__ import annotations

import numpy as np
from PIL import ImageDraw

from generation.sample_3d import FiberImage3D


class OverlayMixin:
    @staticmethod
    def resolve_centerline_overlay_color(color_name, brightness):
        base_colors = {
            "green": (0, 255, 0),
            "neon green": (57, 255, 20),
            "cyan": (0, 255, 255),
            "magenta": (255, 0, 255),
            "yellow": (255, 255, 0),
        }
        key = str(color_name).strip().lower()
        base_color = base_colors.get(key, base_colors["neon green"])
        try:
            brightness_value = float(brightness)
        except (TypeError, ValueError):
            brightness_value = 1.0
        brightness_value = max(brightness_value, 0.1)
        return tuple(min(255, int(round(channel * brightness_value))) for channel in base_color)

    @classmethod
    def get_centerline_overlay_style(cls, params):
        color_name = getattr(getattr(params, "centerlineOverlayColor", None), "value", "Neon Green")
        brightness = getattr(getattr(params, "centerlineOverlayBrightness", None), "value", 1.0)
        rgb = cls.resolve_centerline_overlay_color(color_name, brightness)
        napari_color = "#{:02X}{:02X}{:02X}".format(*rgb)
        return rgb, napari_color

    def get_centerline_overlay_style_from_ui(self):
        color_name = self.centerline_color_combo.currentText() if hasattr(self, "centerline_color_combo") else "Neon Green"
        rgb = self.resolve_centerline_overlay_color(color_name, 1.2)
        napari_color = "#{:02X}{:02X}{:02X}".format(*rgb)
        return rgb, napari_color

    @staticmethod
    def get_centerline_overlay_width_2d(base_image, fiber_image=None):
        if base_image is None:
            return 1
        try:
            output_width = float(base_image.width)
            output_height = float(base_image.height)
            source_width = float(fiber_image.params.imageWidth.get_value()) if fiber_image is not None else output_width
            source_height = float(fiber_image.params.imageHeight.get_value()) if fiber_image is not None else output_height
            scale_factor = min(
                output_width / max(source_width, 1.0),
                output_height / max(source_height, 1.0),
            )
        except Exception:
            scale_factor = 1.0
        min_dim = float(min(base_image.width, base_image.height))
        dimension_factor = min(1.0, max(0.25, min_dim / 128.0))
        return max(1, int(round(2.0 * scale_factor * dimension_factor)))

    @staticmethod
    def overlay_centerlines_on_image(base_image, fiber_image, color, width=None):
        rgb = base_image.convert("RGB") if base_image.mode != "RGB" else base_image.copy()
        draw = ImageDraw.Draw(rgb)
        try:
            width_px = float(fiber_image.params.imageWidth.get_value())
            height_px = float(fiber_image.params.imageHeight.get_value())
            if width_px <= 0 or height_px <= 0:
                return rgb
            scale_x = rgb.width / width_px
            scale_y = rgb.height / height_px
        except Exception:
            scale_x = 1.0
            scale_y = 1.0

        line_width = width if width is not None else OverlayMixin.get_centerline_overlay_width_2d(rgb, fiber_image)
        max_x = max(rgb.width - 1, 0)
        max_y = max(rgb.height - 1, 0)
        for fiber in getattr(fiber_image, "fibers", []):
            points = getattr(fiber, "points", None)
            if not points or len(points) < 2:
                continue
            line_points = []
            for point in points:
                x = int(round(point.x * scale_x))
                y = int(round(point.y * scale_y))
                if x < 0 or y < 0 or x > max_x or y > max_y:
                    x = min(max(x, 0), max_x)
                    y = min(max(y, 0), max_y)
                line_points.append((x, y))
            if len(line_points) >= 2:
                draw.line(line_points, fill=color, width=line_width)
        return rgb

    @staticmethod
    def get_centerline_paths_3d(fiber_image, display_shape=None):
        paths = []
        scale_z = scale_y = scale_x = 1.0
        max_z = max_y = max_x = None
        if display_shape is not None:
            try:
                display_depth, display_height, display_width = [float(v) for v in display_shape[:3]]
                source_depth = float(fiber_image.params.imageDepth.get_value())
                source_height = float(fiber_image.params.imageHeight.get_value())
                source_width = float(fiber_image.params.imageWidth.get_value())
                scale_z = (display_depth - 1.0) / max(source_depth - 1.0, 1.0) if source_depth > 1 else 1.0
                scale_y = (display_height - 1.0) / max(source_height - 1.0, 1.0) if source_height > 1 else 1.0
                scale_x = (display_width - 1.0) / max(source_width - 1.0, 1.0) if source_width > 1 else 1.0
                max_z = max(display_depth - 1.0, 0.0)
                max_y = max(display_height - 1.0, 0.0)
                max_x = max(display_width - 1.0, 0.0)
            except Exception:
                scale_z = scale_y = scale_x = 1.0
                max_z = max_y = max_x = None
        for fiber in getattr(fiber_image, "fibers", []):
            points = getattr(fiber, "points", [])
            if len(points) < 2:
                continue
            path_points = []
            paths.append(np.asarray([], dtype=float))
            for point in points:
                z = point.z * scale_z
                y = point.y * scale_y
                x = point.x * scale_x
                if max_z is not None:
                    z = min(max(z, 0.0), max_z)
                    y = min(max(y, 0.0), max_y)
                    x = min(max(x, 0.0), max_x)
                candidate = [z, y, x]
                if not path_points or any(abs(candidate[idx] - path_points[-1][idx]) > 1e-6 for idx in range(3)):
                    path_points.append(candidate)
            if len(path_points) >= 2:
                paths[-1] = np.asarray(path_points, dtype=float)
            else:
                paths.pop()
        return paths

    @staticmethod
    def get_centerline_overlay_width_3d(display_shape=None, fiber_image=None):
        min_scale = 1.0
        min_dim = 128.0
        try:
            if display_shape is not None:
                display_shape = [float(v) for v in display_shape[:3]]
                min_dim = min(display_shape)
                if fiber_image is not None:
                    source_shape = [
                        float(fiber_image.params.imageDepth.get_value()),
                        float(fiber_image.params.imageHeight.get_value()),
                        float(fiber_image.params.imageWidth.get_value()),
                    ]
                    ratios = [
                        display_shape[i] / max(source_shape[i], 1.0)
                        for i in range(3)
                    ]
                    min_scale = min(ratios)
        except Exception:
            min_scale = 1.0
            min_dim = 128.0
        dimension_factor = min(1.0, max(0.5, min_dim / 96.0))
        return max(0.5, min(1.0, min_scale) * dimension_factor)

    @staticmethod
    def get_viewer_image_shape(viewer, layer_name='3D Image'):
        try:
            if viewer is not None and layer_name in viewer.layers:
                data = viewer.layers[layer_name].data
                if hasattr(data, "shape") and len(data.shape) >= 3:
                    return tuple(int(v) for v in data.shape[:3])
        except Exception:
            pass
        return None

    @staticmethod
    def get_fiber_segment_shapes_3d(fiber_image):
        segments = []
        widths = []
        for fiber in getattr(fiber_image, "fibers", []):
            for segment in fiber:
                segments.append(
                    np.asarray(
                        [
                            [segment.start.z, segment.start.y, segment.start.x],
                            [segment.end.z, segment.end.y, segment.end.x],
                        ],
                        dtype=float,
                    )
                )
                widths.append(FiberImage3D.get_rendered_tube_diameter_3d(segment.width, min_diameter=1))
        return segments, np.asarray(widths, dtype=float)
