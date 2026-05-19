from __future__ import annotations

import napari
import numpy as np
from PIL import Image, ImageDraw

from generation.sample_3d import FiberImage3D


class NapariPreviewMixin:
    def show_2d_viewer(self):
        if hasattr(self, 'image_display_2d_stack') and self.image_display_2d_stack is not None:
            self.image_display_2d_stack.setCurrentWidget(self.image_display_2d_viewer_widget)
        if hasattr(self, 'image_display_2d_viewer_widget') and self.image_display_2d_viewer_widget is not None:
            self.image_display_2d_viewer_widget.show()

    def show_3d_viewer(self):
        if hasattr(self, 'image_display_3d_stack') and self.image_display_3d_stack is not None:
            self.image_display_3d_stack.setCurrentWidget(self.image_display_3d_viewer_widget)
        if hasattr(self, 'image_display_3d_viewer_widget') and self.image_display_3d_viewer_widget is not None:
            self.image_display_3d_viewer_widget.show()

    def get_viewer_camera_state(self):
        try:
            return {
                "angles": tuple(self.viewer.camera.angles),
                "center": tuple(self.viewer.camera.center),
                "zoom": float(self.viewer.camera.zoom),
                "perspective": float(self.viewer.camera.perspective),
            }
        except Exception:
            return None

    def restore_viewer_camera_state(self, state):
        if not state:
            return
        try:
            self.viewer.camera.angles = state["angles"]
            self.viewer.camera.center = state["center"]
            self.viewer.camera.zoom = state["zoom"]
            self.viewer.camera.perspective = state["perspective"]
        except Exception:
            pass

    def _set_advanced_viewer_closed(self, *_args):
        self.advanced_viewer = None
        self.advanced_viewer_is_3d = None

    def _get_or_create_advanced_napari_viewer(self, is_3d):
        viewer = getattr(self, "advanced_viewer", None)
        viewer_mode = getattr(self, "advanced_viewer_is_3d", None)
        if viewer is not None and viewer_mode == is_3d:
            try:
                _ = len(viewer.layers)
                return viewer
            except Exception:
                self.advanced_viewer = None
                self.advanced_viewer_is_3d = None
        elif viewer is not None:
            try:
                viewer.window._qt_window.close()
            except Exception:
                pass
            self.advanced_viewer = None
            self.advanced_viewer_is_3d = None

        try:
            viewer = napari.Viewer(ndisplay=3 if is_3d else 2, show=False)
        except TypeError:
            viewer = napari.Viewer(ndisplay=3 if is_3d else 2)
        self.advanced_viewer = viewer
        self.advanced_viewer_is_3d = is_3d
        try:
            mode_label = "3D" if is_3d else "2D"
            viewer.window._qt_window.setWindowTitle(f"Fiber Generator - Advanced {mode_label} Viewer")
            viewer.window._qt_window.destroyed.connect(self._set_advanced_viewer_closed)
        except Exception:
            pass
        return viewer

    def update_3d_centerline_layer_for_viewer(self, viewer, fiber_image=None, visible=True, display_shape=None):
        if viewer is None:
            return

        layer_name = 'Centerline Overlay'
        centerline_layer = viewer.layers[layer_name] if layer_name in viewer.layers else None
        if not visible:
            if centerline_layer is not None:
                centerline_layer.visible = False
            return

        if fiber_image is None:
            if self.collection is None:
                return
            fiber_image = self._build_render_fiber_image(self.display_index)

        if not isinstance(fiber_image, FiberImage3D):
            if centerline_layer is not None:
                centerline_layer.visible = False
            return

        if display_shape is None:
            display_shape = self.get_viewer_image_shape(viewer)
        centerline_paths = self.get_centerline_paths_3d(fiber_image, display_shape=display_shape)
        if not centerline_paths:
            if centerline_layer is not None:
                centerline_layer.visible = False
            return

        _, napari_color = self.get_centerline_overlay_style_from_ui()
        edge_width = self.get_centerline_overlay_width_3d(display_shape=display_shape, fiber_image=fiber_image)

        if centerline_layer is None:
            viewer.add_shapes(
                data=centerline_paths,
                name=layer_name,
                shape_type='path',
                edge_color=napari_color,
                edge_width=edge_width,
                opacity=1.0,
            )
        else:
            centerline_layer.data = centerline_paths
            centerline_layer.edge_color = napari_color
            centerline_layer.edge_width = edge_width
            centerline_layer.opacity = 1.0
            centerline_layer.visible = True

    def update_3d_centerline_layer(self, fiber_image=None):
        if not hasattr(self, 'viewer') or self.viewer is None:
            return

        camera_state = self.get_viewer_camera_state()
        self.update_3d_centerline_layer_for_viewer(
            self.viewer,
            fiber_image=fiber_image,
            visible=(
                self.show_centerline_checkbox.isChecked()
                and self.get_active_preview_target() != "centerline_mask"
            ),
        )
        self.restore_viewer_camera_state(camera_state)

    def populate_2d_viewer(self, viewer, image, fiber_image=None, include_overlay=False, include_joints=False, reset_view=True):
        if viewer is None:
            return

        viewer.layers.clear()

        if not isinstance(image, Image.Image):
            try:
                image = Image.fromarray(np.array(image))
            except Exception:
                image = self.collection.get_image(self.display_index)

        if fiber_image is None and self.collection is not None:
            fiber_image = self.collection.get(self.display_index)

        display_image = image
        if include_overlay and fiber_image is not None:
            centerline_rgb, _ = self.get_centerline_overlay_style_from_ui()
            display_image = self.overlay_centerlines_on_image(display_image, fiber_image, color=centerline_rgb)

        base_image = display_image.convert('RGBA')
        if include_joints and fiber_image is not None:
            overlay = Image.new('RGBA', base_image.size, (0, 0, 0, 0))
            draw = ImageDraw.Draw(overlay)
            for joint in fiber_image.joint_points:
                draw.ellipse(
                    (joint.x - 3, joint.y - 3, joint.x + 3, joint.y + 3),
                    outline='red',
                    fill='red'
                )
            base_image = Image.alpha_composite(base_image, overlay)

        image_data = np.array(base_image.convert('RGB'))
        viewer.dims.ndisplay = 2
        viewer.add_image(
            image_data,
            name='2D Image',
            rgb=True,
            interpolation2d='nearest',
        )
        if reset_view:
            viewer.reset_view()

    def populate_3d_viewer(self, viewer, image, fiber_image=None, include_overlay=False, reset_view=True, view_mode=None):
        if viewer is None:
            return

        viewer.layers.clear()

        if isinstance(image, np.ndarray):
            image_data = image
        else:
            try:
                image_data = np.array(image)
            except Exception:
                image_data = None

        if image_data is None or image_data.ndim != 3:
            image_data = self.collection.get_image(self.display_index)
        if image_data.ndim == 2:
            image_data = image_data[np.newaxis, ...]

        if fiber_image is None and self.collection is not None:
            fiber_image = self.collection.get(self.display_index)

        selected_view_mode = view_mode or self.get_3d_view_mode()
        image_kwargs = {
            'name': '3D Image',
            'colormap': 'gray',
            'contrast_limits': (0, 255),
        }
        viewer.dims.ndisplay = 3
        rendering_mode = {
            "projection": "mip",
            "attenuated": "attenuated_mip",
            "isosurface": "iso",
        }.get(selected_view_mode, "mip")
        image_kwargs['rendering'] = rendering_mode
        image_kwargs['interpolation3d'] = 'nearest'
        if rendering_mode == "iso":
            nonzero = image_data[image_data > 0]
            image_kwargs['iso_threshold'] = float(np.percentile(nonzero, 35)) if nonzero.size else 1.0

        try:
            viewer.add_image(image_data, **image_kwargs)
        except Exception:
            fallback_kwargs = {
                'name': '3D Image',
                'colormap': 'gray',
                'contrast_limits': (0, 255),
                'rendering': 'mip',
                'interpolation3d': 'nearest',
            }
            viewer.dims.ndisplay = 3
            viewer.add_image(image_data, **fallback_kwargs)

        if fiber_image is not None:
            self.update_3d_centerline_layer_for_viewer(
                viewer,
                fiber_image=fiber_image,
                visible=include_overlay,
                display_shape=image_data.shape,
            )
        if reset_view:
            viewer.reset_view()

    def open_current_preview_in_napari(self):
        if self.collection is None or self.collection.size() == 0:
            self.show_error(f"No generated {'3D' if self.is_3d_mode else '2D'} preview to open.")
            return
        preview_target = self.get_active_preview_target()
        if preview_target is None:
            self.show_error("Enable a centerline or fiber output before opening a preview.")
            return

        viewer = self._get_or_create_advanced_napari_viewer(self.is_3d_mode)
        fiber_image, rendered_output = self._render_output_for_index(self.display_index, output_target=preview_target)
        if self.is_3d_mode:
            self.populate_3d_viewer(
                viewer,
                rendered_output,
                fiber_image=fiber_image,
                include_overlay=(
                    self.show_centerline_checkbox.isChecked()
                    and preview_target != "centerline_mask"
                ),
                reset_view=True,
                view_mode=self.get_3d_view_mode(),
            )
        else:
            self.populate_2d_viewer(
                viewer,
                rendered_output,
                fiber_image=fiber_image,
                include_overlay=(
                    self.show_centerline_checkbox.isChecked()
                    and preview_target != "centerline_mask"
                ),
                include_joints=self.show_joints_checkbox.isChecked(),
                reset_view=True,
            )
        try:
            viewer.window._qt_window.show()
            viewer.window._qt_window.raise_()
            viewer.window._qt_window.activateWindow()
        except Exception:
            pass

    def update_3d_fiber_preview_layer(self, fiber_image=None):
        if not hasattr(self, 'viewer') or self.viewer is None:
            return

        fiber_layer = self.viewer.layers['Fiber Preview'] if 'Fiber Preview' in self.viewer.layers else None
        if self.get_active_preview_target() != "fiber_image":
            if fiber_layer is not None:
                fiber_layer.visible = False
            return

        if fiber_image is None:
            if self.collection is None:
                return
            fiber_image = self._build_render_fiber_image(self.display_index)

        segment_shapes, segment_widths = self.get_fiber_segment_shapes_3d(fiber_image)
        if not segment_shapes:
            if fiber_layer is not None:
                fiber_layer.visible = False
            return

        if fiber_layer is None:
            self.viewer.add_shapes(
                data=segment_shapes,
                name='Fiber Preview',
                shape_type='line',
                face_color=np.array([0.0, 0.0, 0.0, 0.0]),
                edge_color='white',
                edge_width=segment_widths,
                opacity=0.9
            )
        else:
            fiber_layer.data = segment_shapes
            fiber_layer.face_color = np.array([0.0, 0.0, 0.0, 0.0])
            fiber_layer.edge_color = 'white'
            fiber_layer.edge_width = segment_widths
            fiber_layer.opacity = 0.9
            fiber_layer.visible = True

    def display_image_2d(self, image, fiber_image=None):
        self.show_2d_viewer()
        self.populate_2d_viewer(
            self.viewer_2d,
            image,
            fiber_image=fiber_image,
            include_overlay=(
                self.show_centerline_checkbox.isChecked()
                and self.get_active_preview_target() != "centerline_mask"
            ),
            include_joints=self.show_joints_checkbox.isChecked(),
            reset_view=True,
        )

    def display_image_3d(self, image, fiber_image=None):
        self.show_3d_viewer()
        self.populate_3d_viewer(
            self.viewer,
            image,
            fiber_image=fiber_image,
            include_overlay=(
                self.show_centerline_checkbox.isChecked()
                and self.get_active_preview_target() != "centerline_mask"
            ),
            reset_view=True,
        )
