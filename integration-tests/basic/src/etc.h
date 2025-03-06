#define dbg(a) cout << __FILE__ << ':' << __LINE__ << ": " << (a) << '\n'

#define ASSERT(cond)                                                                          \
	do {                                                                                      \
		if (!(cond)) {                                                                        \
			throw runtime_error(string(__FILE__) + ':' + to_string(__LINE__) + ": " + #cond); \
		}                                                                                     \
	} while (0)

void stackTrace(std::ostream& out = std::cout);

// SORT FUNCTIONS

template <typename Iterator> size_t hashRange(Iterator first, Iterator last) {
	size_t h = 0;
	for (; first != last; ++first) {
		hash_combine(h, hash<typename Iterator::value_type>()(*first));
	}
	return h;
}

template <typename T> size_t hashVector(const vector<T>& v) {
	return hashRange(v.begin(), v.end());
}

//Let T be an element type and F a function T->std::invoke_result_t<F, T>
//Map F over each element of an input vector and return the result
template <typename T, typename F> vector<std::invoke_result_t<F, T>> map(const vector<T>& input, F func) {
	vector<std::invoke_result_t<F, T>> result;
	result.reserve(input.size());

	std::transform(input.begin(), input.end(), std::back_inserter(result), func);

	return result;
}


//Let T be an element type and F a function T->vector<T>
//Map F over each element of an input vector and return the concatenated results
template <typename T, typename F> vector<T> mapMulti(const vector<T>& input, F func) {
vector<T> result;
    
    // Pre-allocate memory for the result vector
    // This is an optimization to avoid frequent reallocations
    // If we knew the sizes of all output vectors in advance, we could be more precise here
    result.reserve(input.size()); // Start with at least as many elements as the input
    
    // For each element in the input vector
    for (const auto& element : input) {
        // Apply the function to get a vector result
        vector<T> subResult = func(element);
        
        // Append the elements of subResult to the result vector
        result.insert(result.end(), subResult.begin(), subResult.end());
    }
    
    return result;}

template <class K, class V> ostream& operator<<(ostream& os, const unordered_map<K, V>& m) {
	os << '{';
	for (auto i = begin(m); i != end(m); ++i) {
		if (i != begin(m)) {
			os << ", ";
		}
		os << i->first << ':' << i->second;
	}
	return os << '}';
}

template <class T> ostream& operator<<(ostream& os, const vector<T>& v) {
	os << '[';
	for (auto i = begin(v); i != end(v); ++i) {
		if (i != begin(v)) {
			os << ", ";
		}
		os << *i;
	}
	return os << ']';
}
