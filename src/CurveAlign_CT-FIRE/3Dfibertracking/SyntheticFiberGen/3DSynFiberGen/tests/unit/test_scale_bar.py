import unittest


class ScaleBarSpecTest(unittest.TestCase):
    def test_scale_bar_spec_uses_pixels_per_micron(self):
        try:
            from generation.sample_2d import FiberImage
        except ModuleNotFoundError as exc:
            self.skipTest(f"Missing runtime dependency for unit test: {exc.name}")

        spec_1 = FiberImage.compute_scale_bar_spec(512, 512, 1.0)
        spec_10 = FiberImage.compute_scale_bar_spec(512, 512, 10.0)

        self.assertEqual(spec_1["label"], "100 um")
        self.assertEqual(spec_10["label"], "10 um")
        self.assertEqual(spec_1["right"] - spec_1["left"], spec_10["right"] - spec_10["left"])


if __name__ == '__main__':
    unittest.main()
