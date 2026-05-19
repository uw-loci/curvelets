import os
import unittest


class DistributionDialogTest(unittest.TestCase):
    def test_dialog_instantiates_with_uniform_distribution(self):
        os.environ.setdefault('QT_QPA_PLATFORM', 'offscreen')
        try:
            from PyQt6.QtWidgets import QApplication
            from app.dialogs.distribution_dialog import DistributionDialog
            from core.distributions import Uniform
        except ModuleNotFoundError as exc:
            self.skipTest(f"Missing GUI dependency for dialog test: {exc.name}")

        app = QApplication.instance() or QApplication([])
        dialog = DistributionDialog(Uniform(0.0, 1.0, 0.0, 1.0))
        try:
            self.assertEqual(dialog.comboBox.currentText(), 'Uniform')
        finally:
            dialog.close()
            dialog.deleteLater()
            app.processEvents()


if __name__ == '__main__':
    unittest.main()
