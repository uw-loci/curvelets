import tkinter as tk
from tkinter import filedialog, messagebox
from PIL import Image, ImageTk
import json
import numpy as np
import random

# Vector class
class Vector:
    def __init__(self, x=0.0, y=0.0):
        self.x = x
        self.y = y

    def normalize(self):
        norm = np.linalg.norm([self.x, self.y])
        if norm == 0:
            raise ValueError("Cannot normalize a zero vector")
        return Vector(self.x / norm, self.y / norm)

    def scalar_multiply(self, scalar):
        return Vector(self.x * scalar, self.y * scalar)

    def add(self, other):
        return Vector(self.x + other.x, self.y + other.y)

    def subtract(self, other):
        return Vector(self.x - other.x, self.y - other.y)

    def theta(self):
        return np.arctan2(self.y, self.x)

    def angle_with(self, other):
        if self.is_zero() or other.is_zero():
            raise ValueError("Cannot compute angle with zero vector")
        cos_theta = self.normalize().dot_product(other.normalize())
        cos_theta = np.clip(cos_theta, -1, 1)
        return np.arccos(cos_theta)

    def un_rotate(self, old_x_axis):
        if old_x_axis.is_zero():
            raise ValueError("New x-axis must be nonzero")
        old_x_axis = old_x_axis.normalize()
        new_y_axis = Vector(-old_x_axis.y, old_x_axis.x)
        x_rotated = old_x_axis.scalar_multiply(self.x)
        y_rotated = new_y_axis.scalar_multiply(self.y)
        return x_rotated.add(y_rotated)

    def dot_product(self, other):
        return self.x * other.x + self.y * other.y

    def is_zero(self):
        return self.x == 0 and self.y == 0

    def __repr__(self):
        return f"Vector({self.x}, {self.y})"

# Circle class
class Circle:
    def __init__(self, center, radius):
        self.center = np.array([center.x, center.y])
        self.radius = radius
        self.BUFF = 1e-10

    def contains(self, point):
        return np.linalg.norm(self.center - np.array([point.x, point.y])) <= self.radius + self.BUFF

    def intersects(self, other):
        d = np.linalg.norm(self.center - other.center)
        return d <= self.radius + other.radius + self.BUFF

    def intersection_point(self, other):
        if not self.intersects(other):
            raise ValueError("Circles do not intersect")
        
        intersections = self.circle_circle_intersect(self, other)
        return intersections[int(np.random.random() * len(intersections))]

    @staticmethod
    def circle_circle_intersect(circle1, circle2):
        d = np.linalg.norm(circle1.center - circle2.center)
        if d > circle1.radius + circle2.radius or d < abs(circle1.radius - circle2.radius):
            raise ArithmeticError("No intersection between circles")
        
        a = (circle1.radius ** 2 - circle2.radius ** 2 + d ** 2) / (2 * d)
        h = np.sqrt(circle1.radius ** 2 - a ** 2)
        P2 = circle1.center + (circle2.center - circle1.center) * (a / d)

        x3 = P2[0] + h * (circle2.center[1] - circle1.center[1]) / d
        y3 = P2[1] - h * (circle2.center[0] - circle1.center[0]) / d

        x4 = P2[0] - h * (circle2.center[1] - circle1.center[1]) / d
        y4 = P2[1] + h * (circle2.center[0] - circle1.center[0]) / d

        return [Vector(x3, y3), Vector(x4, y4)]

# Param class
class Param:
    def __init__(self, name="", hint="", value=None, use=False):
        self.value = value
        self.name = name
        self.hint = hint
        self.use = use

    def parse(self, string, parser):
        if self.use:
            if not string.strip():
                raise ValueError("Input string contains only whitespace")
            self.value = parser(string)

    def verify(self, bound, verifier):
        if self.use:
            verifier(self.value, bound)
            
# MiscUtility class
class MiscUtility:
    @staticmethod
    def new_gbc():
        return {'gridx': 0, 'gridy': 0}

    @staticmethod
    def gui_name(param):
        name = param.name()
        if len(name) == 0:
            return ":"
        uppercase = name[0].upper() + name[1:]
        return f"{uppercase}:"

    @staticmethod
    def show_error(message):
        messagebox.showerror("Error", message)

    @staticmethod
    def sq(val):
        return val * val

    @staticmethod
    def to_deltas(points):
        deltas = [points[i + 1] - points[i] for i in range(len(points) - 1)]
        return deltas

    @staticmethod
    def from_deltas(deltas, start):
        points = [start]
        for delta in deltas:
            points.append(points[-1] + delta)
        return points

# OptionPanel class
class OptionPanel(tk.Frame):
    FIELD_W = 5
    INNER_BUFF = 5

    def __init__(self, parent, border_text=None):
        super().__init__(parent)
        self.y = 0
        self.grid_columnconfigure(0, weight=1)
        self.grid_columnconfigure(1, weight=1)
        if border_text:
            self.config(borderwidth=2, relief="groove")
            self.border_label = tk.Label(self, text=border_text)
            self.border_label.grid(row=self.y, columnspan=2)
            self.y += 1

    def add_button_line(self, label_text, hint_text, button_text):
        self.add_label(label_text, hint_text)
        return self.add_button(button_text)

    def add_text_field_line(self, param):
        self.add_label(param.name(), param.hint())
        return self.add_text_field()

    def add_label(self, label_text, hint_text):
        label = tk.Label(self, text=label_text)
        label.grid(row=self.y, column=0, padx=(0, self.INNER_BUFF), sticky="w")
        label.bind("<Enter>", lambda e: self.show_hint(label, hint_text))
        label.bind("<Leave>", lambda e: self.hide_hint(label))
        return label

    def add_check_box(self, option):
        check_var = tk.BooleanVar(value=option.use)
        checkbox = tk.Checkbutton(self, text=self.gui_name(option), variable=check_var)
        checkbox.grid(row=self.y, column=0, padx=(0, self.INNER_BUFF), sticky="w")
        checkbox.bind("<Enter>", lambda e: self.show_hint(checkbox, option.hint()))
        checkbox.bind("<Leave>", lambda e: self.hide_hint(checkbox))
        self.y += 1
        return checkbox

    def add_button(self, label_text):
        button = tk.Button(self, text=label_text)
        button.grid(row=self.y, column=1, padx=(self.INNER_BUFF, 0), sticky="w")
        self.y += 1
        return button

    def add_text_field(self):
        entry = tk.Entry(self, width=self.FIELD_W)
        entry.grid(row=self.y, column=1, padx=(self.INNER_BUFF, 0), sticky="w")
        self.y += 1
        return entry

    def gui_name(self, param):
        name = param.name()
        if len(name) == 0:
            return ":"
        uppercase = name[0].upper() + name[1:]
        return f"{uppercase}:"

    def show_hint(self, widget, hint_text):
        widget.tooltip = tk.Toplevel(self, bg='yellow')
        widget.tooltip.wm_overrideredirect(True)
        x, y, _, _ = widget.bbox("insert")
        x += widget.winfo_rootx()
        y += widget.winfo_rooty()
        widget.tooltip.wm_geometry(f"+{x}+{y}")
        label = tk.Label(widget.tooltip, text=hint_text, bg='yellow', padx=5, pady=5)
        label.pack()

    def hide_hint(self, widget):
        if hasattr(widget, 'tooltip'):
            widget.tooltip.destroy()
            widget.tooltip = None

# Distribution and its subclasses
class Distribution:
    def __init__(self, lower_bound, upper_bound):
        self.lower_bound = lower_bound
        self.upper_bound = upper_bound
        self.distribution = []

    def next_value(self):
        pass

    def get_lower_bound(self):
        return self.lower_bound

    def get_upper_bound(self):
        return self.upper_bound

    def get_x_string(self):
        return ",".join(str(point[0]) for point in self.distribution)

    def get_y_string(self):
        return ",".join(str(point[1]) for point in self.distribution)

    def parse_xy_values(self, x_string, y_string):
        x_tokens = x_string.split(",")
        y_tokens = y_string.split(",")
        if len(x_tokens) != len(y_tokens):
            raise ValueError("Number of x points and y points must be equal")
        if len(x_tokens) == 0:
            raise ValueError("Must have a nonzero number of points in distribution")
        
        self.distribution = []
        for x, y in zip(x_tokens, y_tokens):
            try:
                point = [float(x), float(y)]
            except ValueError as e:
                raise ValueError(f"Invalid coordinate: {e}")
            self.distribution.append(point)

class Gaussian(Distribution):
    def __init__(self, lower_bound, upper_bound, mean, stddev):
        super().__init__(lower_bound, upper_bound)
        self.mean = mean
        self.stddev = stddev

    def next_value(self):
        return np.random.normal(self.mean, self.stddev)

class Uniform(Distribution):
    def next_value(self):
        return np.random.uniform(self.lower_bound, self.upper_bound)

# Fiber class
class Fiber:
    class Params:
        def __init__(self, segment_length, width_change, n_segments, start_width, straightness, start, end):
            self.segment_length = segment_length
            self.width_change = width_change
            self.n_segments = n_segments
            self.start_width = start_width
            self.straightness = straightness
            self.start = np.array(start)
            self.end = np.array(end)
    
    class Segment:
        def __init__(self, start, end, width):
            self.start = np.array(start)
            self.end = np.array(end)
            self.width = width
    
    def __init__(self, params):
        self.params = params
        self.segments = self.create_fiber(params)

    def create_fiber(self, params):
        segments = []
        current_point = params.start
        current_width = params.start_width
        direction = (params.end - params.start) / params.n_segments

        for _ in range(params.n_segments):
            next_point = self.perturb(current_point, direction, params.segment_length)
            segments.append(Fiber.Segment(current_point, next_point, current_width))
            current_point = next_point
            current_width += params.width_change
        
        return segments

    def perturb(self, point, direction, distance):
        perturbation = np.random.randn(3) * distance * (1 - self.params.straightness)
        perturbed_point = point + direction * distance + perturbation
        return perturbed_point

    def smooth(self, beta, iterations):
        for _ in range(iterations):
            for i in range(1, len(self.segments) - 1):
                prev_segment = self.segments[i - 1]
                curr_segment = self.segments[i]
                next_segment = self.segments[i + 1]

                prev_vec = prev_segment.end - prev_segment.start
                next_vec = next_segment.end - next_segment.start
                avg_vec = (prev_vec + next_vec) / 2

                curr_segment.end = curr_segment.start + beta * avg_vec + (1 - beta) * (curr_segment.end - curr_segment.start)

    def try_swap(self, deltas, u, v):
        old_diff = self.local_diff_sum(deltas, u, v)
        deltas[u], deltas[v] = deltas[v], deltas[u]
        new_diff = self.local_diff_sum(deltas, u, v)
        if new_diff > old_diff:
            deltas[u], deltas[v] = deltas[v], deltas[u]

    def local_diff_sum(self, deltas, u, v):
        i1, i2 = min(u, v), max(u, v)
        if i1 < 0 or i2 >= len(deltas):
            raise IndexError("u and v must be within the array")
        
        sum_diff = 0.0
        if i1 > 0:
            sum_diff += self.angle_between(deltas[i1 - 1], deltas[i1])
        if i1 < i2:
            sum_diff += self.angle_between(deltas[i1], deltas[i1 + 1])
        if i1 < i2 - 1:
            sum_diff += self.angle_between(deltas[i2 - 1], deltas[i2])
        if i2 < len(deltas) - 1:
            sum_diff += self.angle_between(deltas[i2], deltas[i2 + 1])
        
        return sum_diff

    def angle_between(self, vec1, vec2):
        unit_vec1 = vec1 / np.linalg.norm(vec1)
        unit_vec2 = vec2 / np.linalg.norm(vec2)
        return np.arccos(np.clip(np.dot(unit_vec1, unit_vec2), -1.0, 1.0))

# FiberImage class
class FiberImage:
    class Params:
        def __init__(self, n_fibers, segment_length, alignment, mean_angle, width_change, image_width, image_height, image_buffer):
            self.n_fibers = n_fibers
            self.segment_length = segment_length
            self.alignment = alignment
            self.mean_angle = mean_angle
            self.width_change = width_change
            self.image_width = image_width
            self.image_height = image_height
            self.image_buffer = image_buffer

            self.length = Uniform(0.0, float('inf'))
            self.width = Uniform(0.0, float('inf'))
            self.straightness = Uniform(0.0, 1.0)

            self.scale = None
            self.down_sample = None
            self.blur = None
            self.noise = None
            self.distance = None
            self.cap = None
            self.normalize = None
            self.bubble = None
            self.swap = None

    def __init__(self, params):
        self.params = params
        self.image = np.zeros((params.image_width, params.image_height, 3), dtype=np.uint8)
        self.fibers = self.generate_fibers(params)

    def generate_fibers(self, params):
        fibers = []
        for _ in range(params.n_fibers):
            start = np.random.rand(3) * [params.image_width, params.image_height, params.image_buffer]
            end = np.random.rand(3) * [params.image_width, params.image_height, params.image_buffer]
            fiber_params = Fiber.Params(
                segment_length=params.segment_length,
                width_change=params.width_change,
                n_segments=int(np.linalg.norm(end - start) / params.segment_length),
                start_width=np.random.uniform(1, 5),
                straightness=params.straightness.next_value(),
                start=start,
                end=end
            )
            fiber = Fiber(fiber_params)
            fibers.append(fiber)
            self.draw_fiber(fiber)
        return fibers

    def draw_fiber(self, fiber):
        for segment in fiber.segments:
            self.draw_segment(segment)

    def draw_segment(self, segment):
        pass

    def add_noise(self):
        if self.params.noise is not None:
            noise_level = self.params.noise
            self.image += np.random.poisson(noise_level, self.image.shape)
            self.image = np.clip(self.image, 0, 255)

    def smooth_image(self):
        if self.params.blur is not None:
            sigma = self.params.blur
            self.image = gaussian_filter(self.image, sigma=sigma)

    def draw_scale_bar(self):
        pass

# Image