from __future__ import annotations

from PyQt6.QtCore import QThread, pyqtSignal

from extractors.ct_fire import CTFireAdapter


class ExtractionWorker(QThread):
    extraction_finished = pyqtSignal(object)
    extraction_failed = pyqtSignal(str)

    def __init__(self, inputs: dict):
        super().__init__()
        self.inputs = inputs

    def run(self):
        try:
            sample = CTFireAdapter().parse(self.inputs)
            self.extraction_finished.emit(sample)
        except Exception as e:
            self.extraction_failed.emit(str(e))
