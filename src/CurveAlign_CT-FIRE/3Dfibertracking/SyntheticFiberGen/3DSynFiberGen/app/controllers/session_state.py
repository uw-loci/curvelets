from __future__ import annotations


class SessionStateMixin:
    def prev_pressed(self):
        if self.collection is None or self.collection.size() == 0 or self.display_index <= 0:
            return
        self.display_index -= 1
        if self.is_3d_mode:
            self.display_index_3d = self.display_index
        else:
            self.display_index_2d = self.display_index
        self.update_image_counter()
        self.restore_current_mode_preview()

    def next_pressed(self):
        if self.collection is None or self.collection.size() == 0 or self.display_index >= self.collection.size() - 1:
            return
        self.display_index += 1
        if self.is_3d_mode:
            self.display_index_3d = self.display_index
        else:
            self.display_index_2d = self.display_index
        self.update_image_counter()
        self.restore_current_mode_preview()

    def update_image_counter(self):
        if self.collection is not None and self.collection.size() > 0:
            self.image_counter_label.setText(f"{self.display_index + 1}/{self.collection.size()}")
        else:
            self.image_counter_label.setText("0/0")
        has_previous = self.collection is not None and self.collection.size() > 0 and self.display_index > 0
        has_next = self.collection is not None and self.collection.size() > 0 and self.display_index < self.collection.size() - 1
        self.prev_button.setEnabled(has_previous)
        self.next_button.setEnabled(has_next)

    def sync_mode_runtime_state(self):
        if self.is_3d_mode:
            self.collection = self.collection_3d
            self.display_index = self.display_index_3d
            self.original_fibers_by_index = self.original_fibers_by_index_3d
        else:
            self.collection = self.collection_2d
            self.display_index = self.display_index_2d
            self.original_fibers_by_index = self.original_fibers_by_index_2d

    def store_mode_runtime_state(self):
        if self.is_3d_mode:
            self.collection_3d = self.collection
            self.display_index_3d = self.display_index
            self.original_fibers_by_index_3d = list(self.original_fibers_by_index)
        else:
            self.collection_2d = self.collection
            self.display_index_2d = self.display_index
            self.original_fibers_by_index_2d = list(self.original_fibers_by_index)

    def clear_current_mode_runtime_state(self):
        if self.is_3d_mode:
            self.collection_3d = None
            self.display_index_3d = 0
            self.original_fibers_by_index_3d = []
        else:
            self.collection_2d = None
            self.display_index_2d = 0
            self.original_fibers_by_index_2d = []
        self.collection = None
        self.display_index = 0
        self.original_fibers_by_index = []
        self.clear_current_mode_enhanced_outputs()

    def toggle_mode(self):
        if self.enhancement_worker is not None and self.enhancement_worker.isRunning():
            self.show_error("Wait for realism enhancement to finish before switching modes.")
            return
        self._suspend_redraw = True
        self.store_mode_runtime_state()

        self.is_3d_mode = not self.is_3d_mode
        if self.is_3d_mode:
            self.params = self.params_3d
            self.out_folder = self.out_folder_3d
            self.mode_toggle_button.setText("Switch to 2D Mode")
            self.display_stack.setCurrentWidget(self.image_display_3d)
        else:
            self.params = self.params_2d
            self.out_folder = self.out_folder_2d
            self.mode_toggle_button.setText("Switch to 3D Mode")
            self.display_stack.setCurrentWidget(self.image_display_2d)

        self.sync_mode_runtime_state()
        self.update_ui_mode()
        self.display_params()
        self.update_image_counter()
        self._suspend_redraw = False
        self.restore_current_mode_preview()

    def clear_mode_views(self):
        try:
            if hasattr(self, 'viewer') and self.viewer is not None:
                self.viewer.layers.clear()
        except Exception:
            pass

        if hasattr(self, 'image_display_2d') and self.image_display_2d is not None:
            try:
                self.show_2d_placeholder()
            except Exception:
                pass

        if hasattr(self, 'image_display_3d_placeholder') and self.image_display_3d_placeholder is not None:
            try:
                self.show_3d_placeholder()
            except Exception:
                pass

    def show_2d_placeholder(self, message='No 2D preview yet.\nClick "Generate" to create a 2D image.'):
        if hasattr(self, 'viewer_2d') and self.viewer_2d is not None:
            try:
                self.viewer_2d.layers.clear()
            except Exception:
                pass
        if hasattr(self, 'image_display_2d_placeholder') and self.image_display_2d_placeholder is not None:
            self.image_display_2d_placeholder.setText(message)
        if hasattr(self, 'image_display_2d_stack') and self.image_display_2d_stack is not None:
            self.image_display_2d_stack.setCurrentWidget(self.image_display_2d_placeholder)

    def show_3d_placeholder(self, message='No 3D preview yet.\nClick "Generate" to create a 3D volume.'):
        if hasattr(self, 'viewer') and self.viewer is not None:
            try:
                self.viewer.layers.clear()
            except Exception:
                pass
        if hasattr(self, 'image_display_3d_placeholder') and self.image_display_3d_placeholder is not None:
            self.image_display_3d_placeholder.setText(message)
        if hasattr(self, 'image_display_3d_stack') and self.image_display_3d_stack is not None:
            self.image_display_3d_stack.setCurrentWidget(self.image_display_3d_placeholder)

    def show_placeholder_for_current_mode(self, missing_output=False):
        if self.is_3d_mode:
            message = (
                "Enable a centerline or fiber output to preview 3D images."
                if missing_output else
                "No 3D preview yet.\nClick \"Generate\" to create a 3D volume."
            )
            self.show_3d_placeholder(message)
        else:
            message = (
                "Enable a centerline or fiber output to preview 2D images."
                if missing_output else
                "No 2D preview yet.\nClick \"Generate\" to create a 2D image."
            )
            self.show_2d_placeholder(message)

    def restore_current_mode_preview(self):
        self.refresh_preview_export_summary()
        active_target = self.get_active_preview_target()
        if active_target is None:
            self.show_placeholder_for_current_mode(missing_output=True)
            return
        # Input image and CT-FIRE centerlines can be displayed without a generated collection
        if active_target not in ("ctfire_centerlines", "input_image"):
            if self.collection is None or self.collection.size() == 0:
                self.show_placeholder_for_current_mode()
                return
        fiber_image, rendered_output = self._render_output_for_index(self.display_index)
        self.display_image(rendered_output, fiber_image=fiber_image)
