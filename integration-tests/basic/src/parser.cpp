#include "all.h"

// Read a file into a vector of strings, one per line
vector<string> readLines(string file) {
	std::ifstream inFile(file);
	if (!inFile.is_open()) {
		throw runtime_error("Failed to open file: " + file);
	}

	vector<string> lines;
	string line;
	while (std::getline(inFile, line)) {
		lines.push_back(line);
	}

	if (inFile.bad()) {
		throw runtime_error("Error while reading file: " + file);
	}

	inFile.close();
	return lines;
}

vector<string> splitColons(vector<string> lines) {
    vector<string> result;
    
    for (const string& line : lines) {
        if (line.empty()) {
            result.push_back(line);
            continue;
        }
        
        // Skip processing if the line is already a single statement or has no colons
        if (line.find(':') == string::npos) {
            result.push_back(line);
            continue;
        }
        
        string currentStatement;
        bool inQuotes = false;
        bool inComment = false;
        
        for (size_t i = 0; i < line.size(); ++i) {
            char c = line[i];
            
            // Check for comments (REM or ')
            if (!inQuotes && !inComment && 
                (c == '\'' || (c == 'R' && i + 2 < line.size() && 
                 line[i+1] == 'E' && line[i+2] == 'M' && 
                 (i + 3 == line.size() || isspace(line[i+3]))))) {
                inComment = true;
            }
            
            // Check for quotes
            if (c == '"' && !inComment) {
                inQuotes = !inQuotes;
            }
            
            // Process colons that are not in quotes or comments
            if (c == ':' && !inQuotes && !inComment) {
                // Add current statement if it's not empty
                if (!currentStatement.empty()) {
                    result.push_back(currentStatement);
                }
                currentStatement.clear();
                continue;
            }
            
            // Add character to current statement
            currentStatement += c;
        }
        
        // Add the last statement if not empty
        if (!currentStatement.empty()) {
            result.push_back(currentStatement);
        }
    }
    
    return result;
}