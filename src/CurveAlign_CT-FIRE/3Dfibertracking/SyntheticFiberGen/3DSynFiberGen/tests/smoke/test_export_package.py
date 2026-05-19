import unittest


class ExportPackageSmokeTest(unittest.TestCase):
    def test_export_package_smoke(self):
        try:
            from export.builders import build_canonical_sample
            from fileio.params_io import DEFAULT_2D_PATH, load_params_2d_file
            from generation.collections import ImageCollection
        except ModuleNotFoundError as exc:
            self.skipTest(f"Missing runtime dependency for smoke test: {exc.name}")

        params = load_params_2d_file(str(DEFAULT_2D_PATH))
        params.nImages.value = 1
        collection = ImageCollection(params)
        collection.generate_images()
        sample = build_canonical_sample(
            collection.get(0),
            image_id='sample_0000',
            sample_id='sample_0000',
        )
        self.assertEqual(sample.image_id, 'sample_0000')


if __name__ == '__main__':
    unittest.main()
