#define _CRT_SECURE_NO_WARNINGS

// C++ standard library
#include <algorithm>
#include <fstream>
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
