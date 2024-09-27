#include <iostream>
#include <string>
#include <fstream>
#include <vector>

#include <pybind11/pybind11.h>
#include <pybind11/numpy.h>
#include <pybind11/stl.h>
#include <pybind11/complex.h>

#include "fdct_wrapping.hpp"
#include "fdct_wrapping_inc.hpp"
#include "fdct_wrapping_inline.hpp"

namespace py = pybind11;
namespace fdct = fdct_wrapping_ns;

using namespace std;
using namespace pybind11::literals;

using fdct_wrapping_ns::cpx;
using fdct_wrapping_ns::CpxNumMat;

py::tuple fdct2d_forward_wrap(py::array_t<double> input, int nscales, int nbangles)
{

  return py::make_tuple(1, 1, 1);
}

PYBIND11_MODULE(fdct2d_wrapper, mod)
{
}
