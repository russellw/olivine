// visibility_demo.cpp
// Demonstrates all possible function visibility attributes in C++
// Compile with: clang++ -S -emit-llvm visibility_demo.cpp -o visibility_demo.ll

#include <iostream>

// Standard function with default visibility
void default_visibility_function() {
    std::cout << "Default visibility function" << std::endl;
}

// Function with explicit default visibility
__attribute__((visibility("default")))
void explicit_default_visibility() {
    std::cout << "Explicit default visibility function" << std::endl;
}

// Function with hidden visibility (not exported from shared libraries)
__attribute__((visibility("hidden")))
void hidden_visibility_function() {
    std::cout << "Hidden visibility function" << std::endl;
}

// Function with protected visibility
__attribute__((visibility("protected")))
void protected_visibility_function() {
    std::cout << "Protected visibility function" << std::endl;
}

// Function with internal linkage (static)
static void internal_linkage_function() {
    std::cout << "Internal linkage function" << std::endl;
}

// Function with external linkage (default in C++)
extern void external_linkage_function() {
    std::cout << "External linkage function" << std::endl;
}

// Function with weak symbol
__attribute__((weak))
void weak_function() {
    std::cout << "Weak function (may be overridden)" << std::endl;
}

// Function with weak alias (using proper mangled name)
extern "C" void original_c_function() {
    std::cout << "Original C function" << std::endl;
}

extern "C" {
    // Using C linkage so the name doesn't need mangling
    __attribute__((weak, alias("original_c_function")))
    void weak_aliased_function();
}

// Function in a specific section
__attribute__((section(".custom_section")))
void custom_section_function() {
    std::cout << "Function in custom section" << std::endl;
}

// COMDAT for variables (fixed extern initializer warning)
// Removed 'extern' since variables with initializers can't be extern
__attribute__((visibility("default")))
int comdat_variable = 42;

// Function that always_inline
__attribute__((always_inline))
inline void always_inline_function() {
    std::cout << "Always inlined function" << std::endl;
}

// Function that is never inlined
__attribute__((noinline))
void never_inline_function() {
    std::cout << "Never inlined function" << std::endl;
}

// Function with the used attribute (prevents elimination even if unused)
__attribute__((used))
static void used_function() {
    std::cout << "Used function (not eliminated even if unused)" << std::endl;
}

// Function with the unused attribute (suppresses unused warnings)
__attribute__((unused))
static void unused_function() {
    std::cout << "Unused function (no warnings)" << std::endl;
}

// Function with C linkage (instead of C++ name mangling)
extern "C" void c_linkage_function() {
    std::cout << "C linkage function" << std::endl;
}

// Function with constructor attribute (runs before main)
__attribute__((constructor))
void constructor_function() {
    std::cout << "Constructor function (runs before main)" << std::endl;
}

// Function with destructor attribute (runs after main)
__attribute__((destructor))
void destructor_function() {
    std::cout << "Destructor function (runs after main)" << std::endl;
}

// Function with cold attribute (rarely executed, like error paths)
__attribute__((cold))
void cold_function() {
    std::cout << "Cold function (rarely executed)" << std::endl;
}

// Function with hot attribute (frequently executed code)
__attribute__((hot))
void hot_function() {
    std::cout << "Hot function (frequently executed)" << std::endl;
}

// Weak function
__attribute__((weak))
void weak_comdat_function() {
    std::cout << "Weak function" << std::endl;
}

// Function in a custom section
__attribute__((section(".text.custom_section")))
void custom_section_function2() {
    std::cout << "Function in named custom section" << std::endl;
}

// Function in another custom section
__attribute__((section(".text.largest_section")))
void largest_section_function() {
    std::cout << "Function in another custom section" << std::endl;
}

// Function with Microsoft-specific declspec dllexport (for Windows)
#ifdef _WIN32
__declspec(dllexport)
#endif
void dllexport_function() {
    std::cout << "DLL export function" << std::endl;
}

// Fix for dllimport function - provide the implementation in all cases
// but mark it as dllexport on Windows so it can be properly linked
#ifdef _WIN32
__declspec(dllexport)  // Using dllexport instead of dllimport for this demo
#endif
void dllimport_function() {
    std::cout << "DLL import/export function" << std::endl;
}

// Using GNU specific __attribute__((format)) for printf-like functions
__attribute__((format(printf, 1, 2)))
void format_function(const char* format, ...) {
    // This would normally implement a printf-like function
    std::cout << "Format function with printf format checking" << std::endl;
}

// Function with deprecated attribute
__attribute__((deprecated("Use new_function instead")))
void deprecated_function() {
    std::cout << "Deprecated function" << std::endl;
}

// Function with aligned attribute
__attribute__((aligned(16)))
void aligned_function() {
    std::cout << "Function aligned to 16-byte boundary" << std::endl;
}

// Function with warn_unused_result attribute
__attribute__((warn_unused_result))
int function_with_result() {
    return 42;
}

// Function with pure attribute (no side effects except return value)
__attribute__((pure))
int pure_function(int x) {
    return x * 2;
}

// Function with const attribute (no side effects, no memory access except args)
__attribute__((const))
int const_function(int x) {
    return x * x;
}

// Main function to call some of our visible functions
int main() {
    std::cout << "Demonstrating various function visibility attributes:" << std::endl;
    
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
    std::cout << "COMDAT variable: " << comdat_variable << std::endl;
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
    int result = function_with_result();
    std::cout << "Result: " << result << std::endl;
    
    std::cout << "Pure function result: " << pure_function(5) << std::endl;
    std::cout << "Const function result: " << const_function(6) << std::endl;
    
    return 0;
}