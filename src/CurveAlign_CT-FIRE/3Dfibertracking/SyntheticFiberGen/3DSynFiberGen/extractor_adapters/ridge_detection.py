from __future__ import annotations

from typing import Any

from .base import ExtractorAdapter


class RidgeDetectionAdapter(ExtractorAdapter):
    name = "ridge_detection"

    def parse(self, inputs: Any):
        raise NotImplementedError("Ridge Detection adapter scaffold only; parser not implemented yet.")

    def extractor_params(self) -> dict[str, Any]:
        return {}
