
from __future__ import annotations

from PyQt6.QtCore import QThread, pyqtSignal

from realism import run_stage2_cgan

class EnhancementWorker(QThread):
    enhancement_finished = pyqtSignal(object, object)
    enhancement_failed = pyqtSignal(str)

    def __init__(self, sample_inputs, model_dir, device, recipe):
        super().__init__()
        self.sample_inputs = list(sample_inputs)
        self.model_dir = model_dir
        self.device = device
        self.recipe = dict(recipe)

    def run(self):
        try:
            results = {}
            for index, centerline_input in self.sample_inputs:
                results[index] = run_stage2_cgan(
                    centerline_input,
                    model_dir=self.model_dir,
                    device=self.device,
                )
            self.enhancement_finished.emit(results, self.recipe)
        except Exception as exc:
            self.enhancement_failed.emit(str(exc))
