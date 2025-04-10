// This version isolates the code generated for the functions
// by avoiding iostream
const char* out;

// Standard function with default visibility
void default_visibility_function() {
	out = "Default visibility function";
}

// Function with explicit default visibility
__attribute__((visibility("default"))) void explicit_default_visibility() {
	out = "Explicit default visibility function";
}

// Function with hidden visibility (not exported from shared libraries)
__attribute__((visibility("hidden"))) void hidden_visibility_function() {
	out = "Hidden visibility function";
}

// Function with protected visibility
__attribute__((visibility("protected"))) void protected_visibility_function() {
	out = "Protected visibility function";
}

// Function with internal linkage (static)
static void internal_linkage_function() {
	out = "Internal linkage function";
}

// Function with external linkage (default in C++)
extern void external_linkage_function() {
	out = "External linkage function";
}

// Function with weak symbol
__attribute__((weak)) void weak_function() {
	out = "Weak function (may be overridden)";
}

// Function with weak alias (using proper mangled name)
void original_c_function() {
	out = "Original C function";
}

// Using C linkage so the name doesn't need mangling
__attribute__((weak, alias("original_c_function"))) void weak_aliased_function();

// Function in a specific section
__attribute__((section(".custom_section"))) void custom_section_function() {
	out = "Function in custom section";
}

// COMDAT for variables (fixed extern initializer warning)
// Removed 'extern' since variables with initializers can't be extern
__attribute__((visibility("default"))) int comdat_variable = 42;

// Function that always_inline
__attribute__((always_inline)) inline void always_inline_function() {
	out = "Always inlined function";
}

// Function that is never inlined
__attribute__((noinline)) void never_inline_function() {
	out = "Never inlined function";
}

// Function with the used attribute (prevents elimination even if unused)
__attribute__((used)) static void used_function() {
	out = "Used function (not eliminated even if unused)";
}

// Function with the unused attribute (suppresses unused warnings)
__attribute__((unused)) static void unused_function() {
	out = "Unused function (no warnings)";
}

// Function with C linkage (instead of C++ name mangling)
void c_linkage_function() {
	out = "C linkage function";
}

// Function with constructor attribute (runs before main)
__attribute__((constructor)) void constructor_function() {
	out = "Constructor function (runs before main)";
}

// Function with destructor attribute (runs after main)
__attribute__((destructor)) void destructor_function() {
	out = "Destructor function (runs after main)";
}

// Function with cold attribute (rarely executed, like error paths)
__attribute__((cold)) void cold_function() {
	out = "Cold function (rarely executed)";
}

// Function with hot attribute (frequently executed code)
__attribute__((hot)) void hot_function() {
	out = "Hot function (frequently executed)";
}

// Weak function
__attribute__((weak)) void weak_comdat_function() {
	out = "Weak function";
}

// Function in a custom section
__attribute__((section(".text.custom_section"))) void custom_section_function2() {
	out = "Function in named custom section";
}

// Function in another custom section
__attribute__((section(".text.largest_section"))) void largest_section_function() {
	out = "Function in another custom section";
}

// Function with Microsoft-specific declspec dllexport (for Windows)
#ifdef _WIN32
__declspec(dllexport)
#endif
void dllexport_function() {
	out = "DLL export function";
}

// Fix for dllimport function - provide the implementation in all cases
// but mark it as dllexport on Windows so it can be properly linked
#ifdef _WIN32
__declspec(dllexport)  // Using dllexport instead of dllimport for this demo
#endif
void dllimport_function() {
	out = "DLL import/export function";
}

// Using GNU specific __attribute__((format)) for printf-like functions
__attribute__((format(printf, 1, 2))) void format_function(const char* format, ...) {
	// This would normally implement a printf-like function
	out = "Format function with printf format checking";
}

// Function with deprecated attribute
__attribute__((deprecated("Use new_function instead"))) void deprecated_function() {
	out = "Deprecated function";
}

// Function with aligned attribute
__attribute__((aligned(16))) void aligned_function() {
	out = "Function aligned to 16-byte boundary";
}

// Function with warn_unused_result attribute
__attribute__((warn_unused_result)) int function_with_result() {
	return 42;
}

// Function with pure attribute (no side effects except return value)
__attribute__((pure)) int pure_function(int x) {
	return x * 2;
}

// Function with const attribute (no side effects, no memory access except args)
__attribute__((const)) int const_function(int x) {
	return x * x;
}

int result;

// Main function to call some of our visible functions
int main() {
	out = "Demonstrating various function visibility attributes:";

	default_visibility_function();
	explicit_default_visibility();
	hidden_visibility_function();
	protected_visibility_function();
	internal_linkage_function();
	external_linkage_function();
	weak_function();
	original_c_function();
	weak_aliased_function();
	custom_section_function();
	out = "COMDAT variable: ";
	result = comdat_variable;
	always_inline_function();
	never_inline_function();
	c_linkage_function();
	cold_function();
	hot_function();
	weak_comdat_function();
	custom_section_function2();
	largest_section_function();
	dllexport_function();
	dllimport_function();
	format_function("Test %s", "format");
	aligned_function();

	// Call functions with results (avoid unused result warnings)
	result = function_with_result();
	out = "Result: ";

	out = "Pure function result: ";
	result = pure_function(5);
	out = "Const function result: ";
	result = const_function(6);

	return 0;
}
