/*
Given one line of Basic, remove the comment if there is one
Make sure to avoid false positive in case REM is a substring of a longer word
or in case it is within a quoted string
*/
string removeComment(string);

/*
A line of Basic code may optionally have a label
This may consist of one or more digits
or a letter or underscore, followed by zero or more letters, digits or underscores
*/
struct Line {
	string label;
	string text;

	Line(string label, string text): label(label), text(text) {
	}

	bool operator==(const Line& b) const {
		return label == b.label && text == b.text;
	}

	bool operator!=(const Line& b) const {
		return !(*this == b);
	}
};

/*
Parse a line of Basic code to extract the label
This may consist of one or more digits
or a letter or underscore, followed by zero or more letters, digits or underscores, and a colon
In the latter case, the colon is not stored in the label
The remainder of the line, after the label, is stored in the text field
*/
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
vector<Line> extractStringLiterals(vector<Line>);

/*
Take a Basic line that may contain colons
and split it up into strictly one statement per line
If a line with a label, is split into several, only the first of the resulting group inherits the label
Lines beginning with `LET STRING_LITERAL_` are returned unchanged
*/
vector<Line> splitColons(Line);

/*
Take a Basic line that may be in mixed case
and convert it to all upper case, both label and text
Lines beginning with `LET STRING_LITERAL_` are returned unchanged
As all string literals have been factored out by now, that means we do not need to worry about quoted strings
*/
Line upper(Line);
