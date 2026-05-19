import tempfile
import unittest
from pathlib import Path


class ParamsRoundTripSmokeTest(unittest.TestCase):
    def test_params_roundtrip_smoke(self):
        try:
            from fileio.params_io import (
                DEFAULT_2D_PATH,
                load_params_2d_file,
                load_params_file_auto,
                read_json,
                write_json,
            )
        except ModuleNotFoundError as exc:
            self.skipTest(f"Missing runtime dependency for smoke test: {exc.name}")

        params = load_params_2d_file(str(DEFAULT_2D_PATH))
        payload = params.to_dict()

        with tempfile.TemporaryDirectory(prefix="fibergen-params-") as temp_dir:
            path = Path(temp_dir) / "params.json"
            write_json(path, payload)
            roundtrip_payload = read_json(path)
            loaded_params, is_3d = load_params_file_auto(str(path))

        self.assertFalse(is_3d)
        self.assertEqual(roundtrip_payload["nFibers"]["value"], payload["nFibers"]["value"])
        self.assertEqual(loaded_params.nFibers.value, params.nFibers.value)


if __name__ == "__main__":
    unittest.main()
