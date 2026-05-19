import re
import unittest
from pathlib import Path


class SignalBindingRegressionTest(unittest.TestCase):
    def test_all_main_window_signal_targets_exist(self):
        app_root = Path(__file__).resolve().parents[2] / "app"
        signal_targets = []
        definitions = set()

        for python_file in app_root.rglob("*.py"):
            text = python_file.read_text()
            definitions.update(re.findall(r"def ([A-Za-z_][A-Za-z0-9_]*)\(", text))
            for line_number, line in enumerate(text.splitlines(), start=1):
                for target in re.findall(r"connect\(self\.([A-Za-z_][A-Za-z0-9_]*)\)", line):
                    signal_targets.append((target, python_file, line_number))

        missing = [
            f"{target} referenced at {python_file}:{line_number}"
            for target, python_file, line_number in signal_targets
            if target not in definitions
        ]
        self.assertEqual(missing, [])


if __name__ == "__main__":
    unittest.main()
