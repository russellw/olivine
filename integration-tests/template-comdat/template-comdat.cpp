// comdat_example.cpp
// This is C++ code that will generate explicit COMDAT groups
// Compile with: clang++ -c comdat_example.cpp

// Inline function that will generate a COMDAT group
inline int inline_function(int x) {
	return x * x;
}

// Template function that will generate COMDAT groups
template <typename T> T template_function(T x) {
	return x + x;
}

// Class with inline methods that will generate COMDAT groups
class MyClass {
public:
	// Inline method definition
	inline int method1(int x) const {
		return x + 1;
	}

	// Method declaration
	int method2(int x) const;
};

// Out-of-line method definition that will generate a COMDAT
inline int MyClass::method2(int x) const {
	return x * 2;
}

// Instantiate the template with different types
template int template_function<int>(int);
template float template_function<float>(float);

// Create a global inline variable (C++17 feature)
inline int global_var = 42;

// Main function that uses all of the above
int main() {
	int result = 0;
	MyClass obj;

	result += inline_function(5);
	result += template_function(10);
	result += obj.method1(15);
	result += obj.method2(20);
	result += global_var;

	// 143
	return result;
}
