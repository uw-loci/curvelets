import os
import unittest


class EmbeddedPreviewRegressionTest(unittest.TestCase):
    def test_embedded_viewer_methods_switch_stacks(self):
        os.environ["QT_QPA_PLATFORM"] = "offscreen"

        try:
            from PyQt6.QtWidgets import QApplication, QLabel, QStackedWidget, QWidget
            from app.preview.napari_bridge import NapariPreviewMixin
        except ModuleNotFoundError as exc:
            self.skipTest(f"Missing GUI dependency for embedded preview test: {exc.name}")

        class DummyPreviewHost(NapariPreviewMixin):
            def __init__(self):
                self.image_display_2d_stack = QStackedWidget()
                self.image_display_2d_placeholder = QLabel("placeholder-2d")
                self.image_display_2d_viewer_widget = QWidget()
                self.image_display_2d_stack.addWidget(self.image_display_2d_placeholder)
                self.image_display_2d_stack.addWidget(self.image_display_2d_viewer_widget)
                self.image_display_2d_stack.setCurrentWidget(self.image_display_2d_placeholder)

                self.image_display_3d_stack = QStackedWidget()
                self.image_display_3d_placeholder = QLabel("placeholder-3d")
                self.image_display_3d_viewer_widget = QWidget()
                self.image_display_3d_stack.addWidget(self.image_display_3d_placeholder)
                self.image_display_3d_stack.addWidget(self.image_display_3d_viewer_widget)
                self.image_display_3d_stack.setCurrentWidget(self.image_display_3d_placeholder)

        app = QApplication.instance() or QApplication([])
        host = DummyPreviewHost()
        host.show_2d_viewer()
        self.assertIs(
            host.image_display_2d_stack.currentWidget(),
            host.image_display_2d_viewer_widget,
        )

        host.show_3d_viewer()
        self.assertIs(
            host.image_display_3d_stack.currentWidget(),
            host.image_display_3d_viewer_widget,
        )

        app.processEvents()


if __name__ == "__main__":
    unittest.main()
