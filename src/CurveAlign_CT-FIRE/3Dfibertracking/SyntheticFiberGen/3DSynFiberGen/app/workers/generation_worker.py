
from __future__ import annotations

import threading

from PyQt6.QtCore import QThread, pyqtSignal

from core.abort import GenerationAborted
from generation.collections import ImageCollection, ImageCollection3D

class GenerationWorker(QThread):
    generation_finished = pyqtSignal(object, object)
    generation_failed = pyqtSignal(str)

    def __init__(self, is_3d_mode, params):
        super().__init__()
        self.is_3d_mode = is_3d_mode
        self.params = params
        self._abort_event = threading.Event()

    def run(self):
        try:
            if self.is_3d_mode:
                collection = ImageCollection3D(self.params)
                collection.generate_images_3d(abort_check=self.abort_requested_check)
            else:
                collection = ImageCollection(self.params)
                collection.generate_images(abort_check=self.abort_requested_check)

            if not self.abort_requested_check():
                # Manual save: do not auto-write results here. Emit collection for UI.
                self.generation_finished.emit(collection, None)
            else:
                self.generation_finished.emit(None, "Generation aborted.")

        except GenerationAborted:
            self.generation_finished.emit(None, "Generation aborted.")
        except Exception as e:
            self.generation_failed.emit(str(e))

    def abort(self):
        self._abort_event.set()

    def abort_requested_check(self):
        return self._abort_event.is_set()
