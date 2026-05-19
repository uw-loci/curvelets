from __future__ import annotations

from copy import deepcopy

from app.workers import GenerationWorker


class GenerationWorkflowMixin:
    def generate_pressed(self):
        try:
            if self.enhancement_worker is not None and self.enhancement_worker.isRunning():
                self.show_error("Wait for realism enhancement to finish before starting a new generation run.")
                return
            self.parse_params()

            if not self.use_joints_checkbox.isChecked():
                self.joint_points_field.clear()

            self.abort_requested = False
            self.abort_button.setText("Abort")
            self.abort_button.setEnabled(True)
            self.generate_button.setEnabled(False)
            self.reset_button.setEnabled(False)

            self.worker = GenerationWorker(
                is_3d_mode=self.is_3d_mode,
                params=self.params,
            )
            self.worker.generation_finished.connect(self.on_generation_finished)
            self.worker.generation_failed.connect(self.on_generation_failed)
            self.worker.start()

        except Exception as exc:
            self.abort_button.setText("Abort")
            self.show_error(str(exc))
            self.abort_button.setEnabled(False)
            self.generate_button.setEnabled(True)
            self.reset_button.setEnabled(True)

    def abort_pressed(self):
        if hasattr(self, 'worker') and self.worker.isRunning():
            self.worker.abort()
            self.abort_button.setText("Stopping...")
            self.abort_button.setEnabled(False)

    def on_generation_finished(self, collection, message):
        self.abort_button.setText("Abort")
        self.abort_button.setEnabled(False)
        self.generate_button.setEnabled(True)
        self.reset_button.setEnabled(True)

        if collection is not None:
            self.collection = collection
            self.display_index = 0
            self.clear_current_mode_enhanced_outputs()
            self.original_fibers_by_index = [deepcopy(self.collection.get(i).fibers) for i in range(self.collection.size())]
            self.store_mode_runtime_state()
            fiber_image = self.collection.get(self.display_index)
            self.original_fibers = deepcopy(self.original_fibers_by_index[self.display_index])
            self.redraw_image()
            self.update_image_counter()
            self.refresh_ui_state()

            if not self.use_joints_checkbox.isChecked():
                if not self.is_3d_mode:
                    fiber_image.ensure_joints()
                self.joint_points_field.setText(str(len(fiber_image.joint_points)))

        elif message:
            if message == "Generation aborted.":
                self.statusBar().showMessage(message, 3000)
            else:
                self.show_error(message)

    def on_generation_failed(self, error):
        self.abort_button.setText("Abort")
        self.abort_button.setEnabled(False)
        self.generate_button.setEnabled(True)
        self.reset_button.setEnabled(True)
        self.show_error(error)

    def _set_preview_target_if_available(self, label):
        index = self.preview_target_combo.findText(label)
        if index < 0:
            return
        block = self.preview_target_combo.blockSignals(True)
        self.preview_target_combo.setCurrentIndex(index)
        self.preview_target_combo.blockSignals(block)
