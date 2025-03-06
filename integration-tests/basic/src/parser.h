// Given one line of Basic, remove the comment if there is one
// Make sure to avoid false positive in case REM is a substring of a longer word
// or in case it is within a quoted string
string removeComment(string);

// A line of Basic code may optionally have a label
// This may consist of one or more digits
// or a letter or underscore, followed by zero or more letters, digits or underscores
struct Line {
	string label;
	string text;

	Line(string label, string text): label(label), text(text) {
	}
};

// Parse a line of Basic code to extract the label
// This may consist of one or more digits
// or a letter or underscore, followed by zero or more letters, digits or underscores, and a colon
// In the latter case, the colon is not stored in the label
// The remainder of the line, after the label, is stored in the text field
Line parseLabel(string);

/*
Quoted strings make it more difficult to parse Basic
Factor them out into special variables
assigned at the start of the program
whose names begin with STRING_LITERAL_
For example, given input:

10 PRINT "FOO"+"BAR"

this function returns:

LET STRING_LITERAL_0$ = "FOO"
LET STRING_LITERAL_1$ = "FOO"
10 PRINT STRING_LITERAL_0+STRING_LITERAL_1
*/
vector<string> splitColons(vector<string>);

/*
Given a Basic program where lines can contain colons
split it up into strictly one statement per line
making sure to avoid splitting on colons that are within comments or quoted strings
*/
vector<string> splitColons(vector<string>);
