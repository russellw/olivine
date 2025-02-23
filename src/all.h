#define _CRT_SECURE_NO_WARNINGS

// C++ standard library
#include <algorithm>
#include <fstream>
#include <iostream>
#include <limits>
#include <memory>
#include <sstream>
#include <stdexcept>
#include <string>
#include <type_traits>
#include <unordered_map>
#include <unordered_set>
#include <utility>
#include <variant>
#include <vector>
using std::all_of;
using std::back_inserter;
using std::cerr;
using std::cout;
using std::hash;
using std::invalid_argument;
using std::invoke_result_t;
using std::ostream;
using std::ostringstream;
using std::pair;
using std::runtime_error;
using std::string;
using std::to_string;
using std::transform;
using std::unordered_map;
using std::unordered_set;
using std::vector;

// Boost
#include <boost/container_hash/hash.hpp>
#include <boost/multiprecision/cpp_int.hpp>
using boost::hash_combine;
using boost::multiprecision::cpp_int;

// Project header files
#include "etc.h"

// Data structures
#include "type.h"

// clang-format sorts includes
// This is normally useful, but in cases like this, where there is a required order
// it is necessary to insert the occasional blank line to prevent inappropriate sorting
#include "term.h"

#include "inst.h"

#include "func.h"
#include "global.h"
#include "module.h"

// Algorithms
#include "check.h"
#include "simplify.h"
#include "ssa.h"

// Logically the code for printing terms should perhaps be ordered later
// but it is useful to place it before the parser so it can be used for debug output
#include "printer.h"

#include "parser.h"
