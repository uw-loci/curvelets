
from __future__ import annotations

from abc import ABC, abstractmethod

import numpy as np

from core.params import Param

class Distribution(ABC):
    """Abstract base class for probability distributions with bounded values."""

    def __init__(self, lower_bound: float, upper_bound: float):
        """Initializes a distribution with lower and upper bounds."""
        self.lower_bound = lower_bound
        self.upper_bound = upper_bound

    @abstractmethod
    def clone(self):
        """Creates and returns a copy of the current distribution instance."""
        pass

    def set_bounds(self, lower_bound: float, upper_bound: float):
        """Updates the lower and upper bounds of the distribution."""
        self.lower_bound = lower_bound
        self.upper_bound = upper_bound

    @abstractmethod
    def get_type(self) -> str:
        """Returns the type of the distribution as a string."""
        pass

    @abstractmethod
    def get_string(self) -> str:
        """Returns a string representation of the distribution."""
        pass

    @abstractmethod
    def sample(self):
        """Generates a random sample from the distribution."""
        pass

    @abstractmethod
    def set_names(self):
        """Assigns human-readable names to the distribution parameters (if applicable)."""
        pass

    @abstractmethod
    def set_hints(self):
        """Provides user hints for distribution parameters (if applicable)."""
        pass

    @abstractmethod
    def verify(self):
        """Validates that the distribution parameters are correctly set."""
        pass


class Gaussian(Distribution):
    """Represents a Gaussian (Normal) distribution with configurable mean and standard deviation."""

    typename = "Gaussian"

    def __init__(self, lower_bound: float, upper_bound: float, mean_value: float = None, sigma_value: float = None):
        """Initializes a Gaussian distribution with given bounds, mean, and standard deviation."""
        super().__init__(lower_bound, upper_bound)
        self.mean = Param(mean_value)
        self.sigma = Param(sigma_value)
        self.set_names()
        self.set_hints()

    def clone(self) -> "Gaussian":
        """Creates a deep copy of this Gaussian distribution."""
        return Gaussian(self.lower_bound, self.upper_bound, self.mean.get_value(), self.sigma.get_value())

    def get_type(self) -> str:
        """Returns the type name of the distribution."""
        return self.typename

    def get_string(self) -> str:
        """Returns a formatted string representation of the Gaussian distribution."""
        return f"{self.get_type()}: μ={self.mean.get_string()}, σ={self.sigma.get_string()}"

    def sample(self) -> float:
        """Generates a random sample from the Gaussian distribution, ensuring it falls within the bounds."""
        val = None
        while val is None or val < self.lower_bound or val > self.upper_bound:
            val = np.random.normal(self.mean.get_value(), self.sigma.get_value())
        return val

    def set_names(self):
        """Sets the names for the distribution parameters."""
        self.mean.set_name("mean")
        self.sigma.set_name("sigma")

    def set_hints(self):
        """Sets tooltips (hints) for GUI-based representation."""
        self.mean.set_hint("Mean (μ) of the Gaussian distribution")
        self.sigma.set_hint("Standard deviation (σ) of the Gaussian distribution")

    def verify(self):
        """Ensures the Gaussian distribution parameters are valid."""
        if self.sigma.get_value() <= 0:
            raise ValueError(f"Standard deviation {self.sigma.get_value()} must be positive.")
        if self.mean.get_value() < self.lower_bound or self.mean.get_value() > self.upper_bound:
            raise ValueError(f"Mean {self.mean.get_value()} must be within bounds [{self.lower_bound}, {self.upper_bound}].")

    @staticmethod
    def from_dict(gaussian_dict: dict) -> "Gaussian":
        """Creates a Gaussian distribution instance from a dictionary."""
        return Gaussian(
            gaussian_dict.get("lower_bound", 0.0),
            gaussian_dict.get("upper_bound", float('inf')),
            gaussian_dict["mean"]["value"],
            gaussian_dict["sigma"]["value"]
        )

    def to_dict(self) -> dict:
        """Converts the Gaussian distribution to a dictionary format."""
        return {
            "lower_bound": self.lower_bound,
            "upper_bound": self.upper_bound,
            "mean": self.mean.to_dict(),
            "sigma": self.sigma.to_dict(),
            "type": self.typename,
        }


class Uniform(Distribution):
    """Represents a uniform distribution with configurable minimum and maximum values."""

    typename = "Uniform"

    def __init__(self, lower_bound: float, upper_bound: float, min_value: float = None, max_value: float = None):
        """Initializes a uniform distribution within the given bounds."""
        super().__init__(lower_bound, upper_bound)
        self.min = Param(min_value)
        self.max = Param(max_value)
        self.set_names()
        self.set_hints()

    def clone(self) -> "Uniform":
        """Creates a deep copy of this uniform distribution."""
        return Uniform(self.lower_bound, self.upper_bound, self.min.get_value(), self.max.get_value())

    def get_type(self) -> str:
        """Returns the type name of the distribution."""
        return self.typename

    def get_string(self) -> str:
        """Returns a formatted string representation of the uniform distribution."""
        return f"{self.get_type()}: {self.min.get_string()}-{self.max.get_string()}"

    def sample(self) -> float:
        """Generates a random sample from the uniform distribution, ensuring it falls within the bounds."""
        trim_min = max(self.lower_bound, self.min.get_value())
        trim_max = min(self.upper_bound, self.max.get_value())
        return np.random.uniform(trim_min, trim_max)

    def set_names(self):
        """Sets the names for the distribution parameters."""
        self.min.set_name("minimum")
        self.max.set_name("maximum")

    def set_hints(self):
        """Sets hints for GUI-based representation."""
        self.min.set_hint("Minimum of the uniform distribution (inclusive)")
        self.max.set_hint("Maximum of the uniform distribution (inclusive)")

    def verify(self):
        """Ensures that the uniform distribution parameters are valid."""
        if self.min.get_value() > self.max.get_value():
            raise ValueError(f"Minimum {self.min.get_value()} cannot exceed maximum {self.max.get_value()}.")
        if self.min.get_value() < self.lower_bound:
            raise ValueError(f"Minimum {self.min.get_value()} is below lower bound {self.lower_bound}.")
        if self.max.get_value() > self.upper_bound:
            raise ValueError(f"Maximum {self.max.get_value()} exceeds upper bound {self.upper_bound}.")

    @staticmethod
    def from_dict(uniform_dict: dict) -> "Uniform":
        """Creates a uniform distribution instance from a dictionary."""
        return Uniform(
            uniform_dict.get("lower_bound", 0.0),
            uniform_dict.get("upper_bound", float('inf')),
            uniform_dict["min"]["value"],
            uniform_dict["max"]["value"]
        )

    def to_dict(self) -> dict:
        """Converts the uniform distribution to a dictionary format."""
        return {
            "lower_bound": self.lower_bound,
            "upper_bound": self.upper_bound,
            "min": self.min.to_dict(),
            "max": self.max.to_dict(),
            "type": self.typename,
        }


class PiecewiseLinear(Distribution):
    """Represents a piecewise linear probability distribution."""

    typename = "Piecewise Linear"

    def __init__(self, lower_bound: float, upper_bound: float, distribution: list = None):
        """Initializes a piecewise linear distribution."""
        super().__init__(lower_bound, upper_bound)
        self.distribution = distribution if distribution else []
        self.set_names()
        self.set_hints()

    def clone(self) -> "PiecewiseLinear":
        """Creates a deep copy of this piecewise linear distribution."""
        return PiecewiseLinear(self.lower_bound, self.upper_bound, list(self.distribution))

    def get_type(self) -> str:
        """Returns the type name of the distribution."""
        return self.typename

    def get_string(self) -> str:
        """Returns a string representation of the distribution."""
        return "Piecewise linear"

    def sample(self) -> float:
        """Samples a random value from the piecewise linear distribution within the bounds."""
        if not self.distribution:
            raise ValueError("Piecewise linear distribution is empty.")

        # Compute total area under the piecewise linear curve (integral)
        integral = sum(0.5 * (p1[1] + p2[1]) * (p2[0] - p1[0])
                       for p1, p2 in zip(self.distribution, self.distribution[1:]))

        # Normalize the distribution
        normalized = [[p[0], p[1] / integral] for p in self.distribution]

        # Generate a random sample from the cumulative distribution function (CDF)
        i, cdf, rand, cdf_prev = 0, 0.0, np.random.uniform(), 0.0
        while i < len(normalized) - 1 and cdf < rand:
            cdf_prev = cdf
            p1, p2 = normalized[i], normalized[i + 1]
            cdf += 0.5 * (p1[1] + p2[1]) * (p2[0] - p1[0])
            i += 1

        cdf_remain = rand - cdf_prev

        if i == 0:
            return normalized[0][0]
        if i == len(normalized):
            return normalized[-1][0]

        # Solve for the sample x value
        p1, p2 = normalized[i - 1], normalized[i]
        x1, y1, x2, y2 = p1[0], p1[1], p2[0], p2[1]

        m = (y2 - y1) / (x2 - x1)  # Slope
        a = 0.5 * m
        b = y1 - m * x1
        c = 0.5 * m * x1 ** 2 - y1 * x1 - cdf_remain

        discriminant = b ** 2 - 4 * a * c
        if discriminant < 0:
            raise ArithmeticError("Sampling failure (no real quadratic roots)")

        # Compute the valid root within the segment bounds
        root0 = (-b + np.sqrt(discriminant)) / (2 * a)
        root1 = (-b - np.sqrt(discriminant)) / (2 * a)
        return root0 if x1 <= root0 <= x2 else root1

    def set_names(self):
        """Sets parameter names (not used in this class)."""
        pass

    def set_hints(self):
        """Sets tooltips for GUI representation (not used in this class)."""
        pass

    def verify(self):
        """Ensures that the piecewise linear distribution is valid."""
        last_x = float('-inf')
        for x, y in self.distribution:
            if x < self.lower_bound or x > self.upper_bound:
                raise ValueError(f"X-values must be within bounds [{self.lower_bound}, {self.upper_bound}]")
            if x < last_x:
                raise ValueError(f"Piecewise linear x-coordinates out of order ({last_x}, {x})")
            if y < 0:
                raise ValueError(f"Negative piecewise linear probability {y}")
            last_x = x

        if not self.distribution:
            raise ValueError("Piecewise linear distribution cannot be empty.")
        if self.distribution[0][0] < self.lower_bound:
            raise ValueError(f"Distribution extends below lower bound {self.lower_bound}")
        if self.distribution[-1][0] > self.upper_bound:
            raise ValueError(f"Distribution extends above upper bound {self.upper_bound}")

    def get_x_string(self) -> str:
        """Returns a comma-separated string of x-values."""
        return ",".join(str(point[0]) for point in self.distribution)

    def get_y_string(self) -> str:
        """Returns a comma-separated string of y-values."""
        return ",".join(str(point[1]) for point in self.distribution)

    def parse_xy_values(self, x_string: str, y_string: str):
        """Parses x and y values from comma-separated strings and updates the distribution."""
        x_tokens, y_tokens = x_string.split(","), y_string.split(",")

        if len(x_tokens) != len(y_tokens):
            raise ValueError("Number of x and y points must be equal")
        if not x_tokens:
            raise ValueError("Must have at least one point in the distribution")

        self.distribution = []
        for x, y in zip(x_tokens, y_tokens):
            try:
                x_val = float(x)
                y_val = float(y)
                if x_val < self.lower_bound or x_val > self.upper_bound:
                    raise ValueError(f"X-value {x_val} is out of bounds [{self.lower_bound}, {self.upper_bound}]")
                if y_val < 0:
                    raise ValueError(f"Negative probability {y_val} is not allowed")
                self.distribution.append([x_val, y_val])
            except ValueError:
                raise ValueError(f"Invalid coordinate values: {x}, {y}")

    @staticmethod
    def from_dict(piecewise_linear_dict: dict) -> "PiecewiseLinear":
        """Creates a piecewise linear distribution instance from a dictionary."""
        lower_bound = piecewise_linear_dict.get("lower_bound", 0.0)
        upper_bound = piecewise_linear_dict.get("upper_bound", float('inf'))
        x_values = piecewise_linear_dict.get("x_values", [])
        y_values = piecewise_linear_dict.get("y_values", [])

        if len(x_values) != len(y_values):
            raise ValueError("Mismatch between x_values and y_values length in dictionary")

        distribution = list(zip(x_values, y_values))
        return PiecewiseLinear(lower_bound, upper_bound, distribution)

    def to_dict(self) -> dict:
        """Converts the piecewise linear distribution to a dictionary format."""
        return {
            "lower_bound": self.lower_bound,
            "upper_bound": self.upper_bound,
            "x_values": [p[0] for p in self.distribution],
            "y_values": [p[1] for p in self.distribution],
            "type": self.typename
        }


def distribution_from_dict(dist_dict, fallback):
    """Create a Distribution from a dict, falling back to the provided instance."""
    if dist_dict is None:
        return fallback
    dist_type = dist_dict.get("type", getattr(fallback, "typename", None))
    if dist_type == Gaussian.typename:
        return Gaussian.from_dict(dist_dict)
    if dist_type == Uniform.typename:
        return Uniform.from_dict(dist_dict)
    if dist_type == PiecewiseLinear.typename:
        return PiecewiseLinear.from_dict(dist_dict)
    return fallback
