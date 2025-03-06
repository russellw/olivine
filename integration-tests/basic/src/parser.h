// Read a file into a vector of strings, one per line
vector<string> readLines(string file);

//Given one line of Basic, remove the comment if there is one
//Make sure to avoid false positive in case REM is a substring of a longer word
//or in case it is within a quoted string
string removeComment(string);

// Given a Basic program where lines can contain colons
// split it up into strictly one statement per line
// making sure to avoid splitting on colons that are within comments or quoted strings
vector<string> splitColons(vector<string>);
