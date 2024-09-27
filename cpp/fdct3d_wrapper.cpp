#include <iostream>
#include <string>
#include <fstream>
#include <vector>

#include <pybind11/pybind11.h>
#include <pybind11/numpy.h>
#include <pybind11/stl.h>
#include <pybind11/complex.h>

#include "fdct3d.hpp"
#include "fdct3dinline.hpp"

namespace py = pybind11;

using namespace std;
using namespace pybind11::literals;

PYBIND11_MODULE(fdct3d_wrapper, mod)
{
}
