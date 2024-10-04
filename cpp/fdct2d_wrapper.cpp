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

int fdct2d_forward_wrap(int m, int n, int nscales, int nbangles)
{
  return 2;
}

PYBIND11_MODULE(fdct2d_wrapper, mod)
{
  mod.doc() = "fdct2d_wrapper";
  mod.def("fdct2d_forward_wrap", &fdct2d_forward_wrap, "fdct2d forward curvelet transform");
}
