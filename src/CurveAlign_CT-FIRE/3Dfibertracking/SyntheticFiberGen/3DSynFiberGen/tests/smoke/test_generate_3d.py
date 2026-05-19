import unittest


class Generate3DSmokeTest(unittest.TestCase):
    def test_generate_3d_smoke(self):
        try:
            from fileio.params_io import DEFAULT_3D_PATH, load_params_3d_file
            from generation.collections import ImageCollection3D
        except ModuleNotFoundError as exc:
            self.skipTest(f"Missing runtime dependency for smoke test: {exc.name}")

        params = load_params_3d_file(str(DEFAULT_3D_PATH))
        params.nImages.value = 1
        collection = ImageCollection3D(params)
        collection.generate_images_3d()
        self.assertEqual(collection.size(), 1)
        self.assertGreaterEqual(len(collection.get(0).fibers), 1)


if __name__ == '__main__':
    unittest.main()
