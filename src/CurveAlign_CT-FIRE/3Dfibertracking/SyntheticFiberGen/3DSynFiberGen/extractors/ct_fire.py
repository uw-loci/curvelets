from __future__ import annotations

from typing import Any

from .base import ExtractorAdapter


class CTFireAdapter(ExtractorAdapter):
    name = "ct_fire"

    def parse(self, inputs: Any):
        raise NotImplementedError("CT-FIRE adapter scaffold only; parser not implemented yet.")

    def extractor_params(self) -> dict[str, Any]:
        return {}
