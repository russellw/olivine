#define _CRT_SECURE_NO_WARNINGS

// C++ standard library
#include <algorithm>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <limits>
#include <memory>
#include <set>
#include <sstream>
#include <stdexcept>
#include <string>
#include <type_traits>
#include <unordered_map>
#include <unordered_set>
#include <utility>
#include <vector>
using std::cerr;
using std::cout;
using std::hash;
using std::ostream;
using std::pair;
using std::runtime_error;
using std::string;
using std::to_string;
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
#include "queue.h"

// Data structures
#include "ref.h"
#include "type.h"

// clang-format sorts includes
// This is normally useful, but in cases like this, where there is a required order
// it is necessary to insert the occasional blank line to prevent inappropriate sorting
#include "term.h"

#include "inst.h"

#include "fn.h"
#include "global.h"
#include "module.h"
#include "program.h"

// Algorithms
#include "check.h"
#include "fixed.h"
#include "link.h"
#include "replace.h"
#include "simplify.h"
#include "ssa.h"

// Logically the code for printing terms should perhaps be ordered later
// but it is useful to place it before the parser so it can be used for debug output
#include "printer.h"

#include "parser.h"
