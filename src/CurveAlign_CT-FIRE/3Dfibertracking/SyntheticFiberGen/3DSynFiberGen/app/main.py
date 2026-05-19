
from __future__ import annotations

import sys
from pathlib import Path

if __package__ in (None, ""):
    project_root = Path(__file__).resolve().parent.parent
    project_root_str = str(project_root)
    if project_root_str not in sys.path:
        sys.path.insert(0, project_root_str)

from PyQt6.QtWidgets import QApplication

from app.main_window import MainWindow
from fileio.export_runner import ExportRunner2D, ExportRunner3D
from fileio.params_io import load_params_file_auto
from generation.collections import ImageCollection, ImageCollection3D

class EntryPoint:
    @staticmethod
    def main(args):
        if len(args) > 1:
            export_runner_2d = ExportRunner2D()
            export_runner_3d = ExportRunner3D()
            try:
                params, is_3d = load_params_file_auto(args[1])
                if is_3d:
                    collection = ImageCollection3D(params)
                    output_folder = "output_3d"
                    collection.generate_images_3d()
                    export_runner_3d.write_results(collection, output_folder)
                else:
                    collection = ImageCollection(params)
                    output_folder = "output_2d"
                    collection.generate_images()
                    export_runner_2d.write_results(collection, output_folder)
            except Exception as e:
                print(f"Error: {e}")
        else:
            app = QApplication(sys.argv)
            window = MainWindow()
            window.show()
            sys.exit(app.exec())


if __name__ == "__main__":
    EntryPoint.main(sys.argv)
