import unittest


class Generate2DSmokeTest(unittest.TestCase):
    def test_generate_2d_smoke(self):
        try:
            from fileio.params_io import DEFAULT_2D_PATH, load_params_2d_file
            from generation.collections import ImageCollection
        except ModuleNotFoundError as exc:
            self.skipTest(f"Missing runtime dependency for smoke test: {exc.name}")

        params = load_params_2d_file(str(DEFAULT_2D_PATH))
        params.nImages.value = 1
        collection = ImageCollection(params)
        collection.generate_images()
        self.assertEqual(collection.size(), 1)
        self.assertGreaterEqual(len(collection.get(0).fibers), 1)


if __name__ == '__main__':
    unittest.main()
