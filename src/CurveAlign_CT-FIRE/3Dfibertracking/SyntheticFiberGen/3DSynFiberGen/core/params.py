
from __future__ import annotations

class Param:
    """A class for handling parameter values with optional bounds, parsing, and validation."""

    def __init__(self, value=None, name="", hint="", lower_bound=None, upper_bound=None):
        """Initializes a parameter with optional constraints."""
        self.value = value
        self.name = name
        self.hint = hint
        self.lower_bound = lower_bound
        self.upper_bound = upper_bound

    def get_value(self):
        """Returns the current value of the parameter."""
        return self.value

    def get_string(self) -> str:
        """Returns the string representation of the parameter value."""
        return str(self.value) if self.value is not None else ""

    def set_name(self, name: str):
        """Sets the name of the parameter."""
        self.name = name

    def get_name(self) -> str:
        """Returns the name of the parameter."""
        return self.name if self.name else ""

    def set_hint(self, hint: str):
        """Sets the hint (description) for the parameter."""
        self.hint = hint

    def get_hint(self) -> str:
        """Returns the hint (description) for the parameter."""
        return self.hint if self.hint else ""

    def set_bounds(self, lower_bound, upper_bound):
        """Sets the lower and upper bounds for the parameter."""
        self.lower_bound = lower_bound
        self.upper_bound = upper_bound

    def get_lower_bound(self):
        """Returns the lower bound of the parameter."""
        return self.lower_bound

    def get_upper_bound(self):
        """Returns the upper bound of the parameter."""
        return self.upper_bound

    def parse(self, string: str, parser):
        """
        Parses a string input and converts it into the expected data type.
        :param string: The input string to parse.
        :param parser: A function that converts the string into the desired type.
        :raises ValueError: If parsing fails or the input is empty.
        """
        if not string.strip():
            raise ValueError(f"Value of \"{self.get_name()}\" must be non-empty")
        try:
            if string.startswith("[") and string.endswith("]"):
                self.value = [parser(x.strip()) for x in string[1:-1].split(",")]
            else:
                self.value = parser(string)
        except Exception as e:
            raise ValueError(f"Unable to parse value \"{string}\" for parameter \"{self.get_name()}\": {e}")

    def verify(self, bound, verifier):
        """
        Verifies if the parameter's value meets the given condition.
        :param bound: The reference value for verification.
        :param verifier: A function that validates the value against the bound.
        :raises ValueError: If verification fails.
        """
        try:
            if isinstance(self.value, list):
                for val in self.value:
                    verifier(val, bound)
            else:
                verifier(self.value, bound)
        except ValueError as e:
            raise ValueError(f"Value of \"{self.get_name()}\" {e} {bound}")

    @staticmethod
    def less(value, max_value):
        """Ensures the value is less than the specified maximum."""
        if value >= max_value:
            raise ValueError("must be less than")

    @staticmethod
    def greater(value, min_value):
        """Ensures the value is greater than the specified minimum."""
        if value <= min_value:
            raise ValueError("must be greater than")

    @staticmethod
    def less_eq(value, max_value):
        """Ensures the value is less than or equal to the specified maximum."""
        if value > max_value:
            raise ValueError("must be less than or equal to")

    @staticmethod
    def greater_eq(value, min_value):
        """Ensures the value is greater than or equal to the specified minimum."""
        if value < min_value:
            raise ValueError("must be greater than or equal to")

    @staticmethod
    def from_dict(param_dict):
        """
        Creates a Param instance from a dictionary.
        :param param_dict: Dictionary containing parameter attributes.
        :return: A Param instance with the parsed values.
        """
        value = param_dict.get("value")
        if isinstance(value, list):
            value = [float(v) for v in value]
        return Param(
            value=value,
            name=param_dict.get("name", ""),
            hint=param_dict.get("hint", "")
        )

    def to_dict(self) -> dict:
        """Converts the Param instance into a dictionary representation."""
        return {
            "value": self.value,
            "name": self.name,
            "hint": self.hint
        }


class Optional(Param):
    """A subclass of Param that includes an option to enable or disable its usage."""

    def __init__(self, value=None, name="", hint="", use=False, lower_bound=None, upper_bound=None):
        """Initializes an optional parameter with an additional 'use' flag."""
        super().__init__(value, name, hint, lower_bound, upper_bound)
        self.use = use  # Indicates if this parameter should be used.

    def parse(self, use: bool, string: str, parser):
        """Parses the input string into the appropriate data type if 'use' is True."""
        self.use = use
        if self.use:
            super().parse(string, parser)

    def verify(self, bound, verifier):
        """Verifies the parameter's value against a specified constraint if 'use' is True."""
        if self.use:
            super().verify(bound, verifier)

    @staticmethod
    def from_dict(optional_dict: dict):
        """Creates an Optional instance from a dictionary."""
        return Optional(
            value=optional_dict.get("value"),
            name=optional_dict.get("name", ""),
            hint=optional_dict.get("hint", ""),
            use=optional_dict.get("use", False)
        )

    def to_dict(self) -> dict:
        """Converts the Optional instance into a dictionary representation."""
        return {
            "value": self.value,
            "name": self.name,
            "hint": self.hint,
            "use": self.use
        }
