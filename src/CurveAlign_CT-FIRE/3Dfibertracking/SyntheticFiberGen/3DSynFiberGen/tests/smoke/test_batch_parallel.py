import unittest


class ParallelBatchSmokeTest(unittest.TestCase):
    def test_parallel_batch_smoke(self):
        try:
            from fileio.params_io import DEFAULT_2D_PATH, load_params_2d_file
            from generation.batch_parallel import generate_parallel_batch
        except ModuleNotFoundError as exc:
            self.skipTest(f"Missing runtime dependency for smoke test: {exc.name}")

        params = load_params_2d_file(str(DEFAULT_2D_PATH))
        params.nImages.value = 2
        params.seed.use = True
        params.seed.value = 123

        samples, timing_summary = generate_parallel_batch(params, is_3d_mode=False, max_workers=2)

        self.assertEqual(len(samples), 2)
        self.assertIn("total_seconds", timing_summary)
        self.assertGreaterEqual(len(samples[0].fibers), 1)
        self.assertGreaterEqual(len(samples[1].fibers), 1)


if __name__ == "__main__":
    unittest.main()
