from __future__ import annotations

from abc import ABC, abstractmethod
from typing import Any

from export_model import CanonicalSample


class ExtractorAdapter(ABC):
    name = "extractor"
    version: str | None = None

    @abstractmethod
    def parse(self, inputs: Any) -> CanonicalSample:
        raise NotImplementedError

    @abstractmethod
    def extractor_params(self) -> dict[str, Any]:
        raise NotImplementedError

    def provenance_patch(self) -> dict[str, Any]:
        return {
            "source_algorithm": self.name,
            "source_algorithm_version": self.version,
        }
