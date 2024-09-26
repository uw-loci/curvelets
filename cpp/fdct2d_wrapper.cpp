#include <iostream>
#include <pybind11/pybind11.h>
#include <pybind11/numpy.h>
#include <pybind11/stl.h>
#include <pybind11/complex.h>
#include <string>
#include <fstream>
#include <vector>
#include "fdct_wrapping.hpp"
#include "fdct_wrapping_inline.hpp"

using namespace std;
namespace py = pybind11;
using namespace pybind11::literals;

PYBIND11_MODULE(fdct2d_wrapper, mod)
{
}
