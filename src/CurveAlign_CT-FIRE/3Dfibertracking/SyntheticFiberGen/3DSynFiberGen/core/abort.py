
from __future__ import annotations

class GenerationAborted(Exception):
    """Raised when cooperative generation cancellation is requested."""


def _raise_if_aborted(abort_check):
    if abort_check and abort_check():
        raise GenerationAborted("Generation aborted.")
