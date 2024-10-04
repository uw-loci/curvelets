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

int fdct2d_forward_wrap(int m, int n, int nbscales, int nbangles, int ac, vector<vector<CpxNumMat>> &c)
{
  return 0;
}

int fdct2d_inverse_wrap(int m, int n, int nbscales, int nbangles, int ac, vector<vector<CpxNumMat>> &c)
{
  return 0;
}

py::tuple fdct2d_param_wrap(int m, int n, int nbscales, int nbangles, int ac)
{
  vector<vector<double>> sx;
  vector<vector<double>> sy;
  vector<vector<double>> fx;
  vector<vector<double>> fy;
  vector<vector<int>> nx;
  vector<vector<int>> ny;

  fdct::fdct_wrapping_param(m, n, nbscales, nbangles, ac, sx, sy, fx, fy, nx, ny);
  py::tuple res = py::make_tuple(sx, sy, fx, fy, nx, ny);
  return res;
}

PYBIND11_MODULE(fdct2d_wrapper, mod)
{
  mod.doc() = "fdct2d_wrapper";
  mod.def("fdct2d_forward_wrap", &fdct2d_forward_wrap, "fdct2d forward curvelet transform");
  mod.def("fdct2d_inverse_wrap", &fdct2d_inverse_wrap, "fdct2d inverse curvelet transform");
  mod.def("fdct2d_param_wrap", &fdct2d_param_wrap, "fdct2d param wrapper");
}
