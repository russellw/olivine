// The signedness of plain char is implementation-defined, typically signed
// and the ctype.h functions have undefined behavior on signed input
// so, unless we want to count on never forgetting to cast to unsigned at every call site,
// we need to provide our own
bool isSpace(int c);
bool isDigit(int c);
bool isLower(int c);
bool isUpper(int c);
bool isAlpha(int c);
bool isAlnum(int c);
bool isXDigit(int c);

// Is the input character a valid part of an LLVM identifier?
// This includes more punctuation than most programming languages
bool isIdPart(int c);

bool containsAt(const string& haystack, size_t position, const string& needle);
bool endsWith(const string& s, int c);

// Parse hexadecimal digits starting at a given position, updating pos accordingly
// Hexadecimal digits are classified by the function isXDigit
// Stops when it reaches the end of the string, or a character that is not a hexadecimal digit, or it has parsed maxLen digits
// At least one hexadecimal digit must be present, or an exception is thrown
unsigned parseHex(const string& s, size_t& pos, int maxLen = 8);

// Remove the leading sigil from an LLVM identifier or string, if there is one
string removeSigil(const string& s);

// Unwrap an LLVM identifier or string
// Remove the leading sigil if any
// If there are quotes, remove them, and evaluate escape sequences
// Check for validity, and throw runtime_error if the string is not valid
// The LLVM language manual doesn't say exactly what escape sequences are valid
// Testing what the LLVM parser actually accepts, it seems to be just \ or two hex digits
// Otherwise, the first \ is just treated as an ordinary character
string unwrap(string s);

// Parse an LLVM identifier or string to a reference containing index number or string as appropriate
// after removing the leading sigil if there is one
// Correctly distinguishes between %9 and %"9"
Ref parseRef(string s);

// Parser for LLVM `.ll` format
Module* parse(const string& text);
Module* parse(const string& file, const string& text);
