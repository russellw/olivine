#include"all.h"

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