from __future__ import annotations

from typing import Any

from .base import ExtractorAdapter


class SOAXAdapter(ExtractorAdapter):
    name = "soax"

    def parse(self, inputs: Any):
        raise NotImplementedError("SOAX adapter scaffold only; parser not implemented yet.")

    def extractor_params(self) -> dict[str, Any]:
        return {}
