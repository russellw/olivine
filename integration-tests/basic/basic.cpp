#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <map>
#include <sstream>
#include <stack>
#include <string>
#include <vector>
#include <stdexcept>

class BasicInterpreter {
private:
    // Token types for lexical analysis
    enum TokenType {
        NUMBER,
        STRING,
        IDENTIFIER,
        OPERATOR,
        KEYWORD,
        EOL,
        END
    };

    // Structure to hold a token
    struct Token {
        TokenType type;
        std::string value;
        
        Token(TokenType t, const std::string& v) : type(t), value(v) {}
    };

    // Structure to hold a line of BASIC code
    struct Line {
        int number;
        std::string text;
        
        Line(int n, const std::string& t) : number(n), text(t) {}
    };

    // Structure to hold variable values
    struct Value {
        enum Type { NUMBER, STRING };
        
        Type type;
        double numValue;
        std::string strValue;
        
        Value() : type(NUMBER), numValue(0) {}
        Value(double v) : type(NUMBER), numValue(v) {}
        Value(const std::string& s) : type(STRING), strValue(s) {}
        
        bool isNumber() const { return type == NUMBER; }
        bool isString() const { return type == STRING; }
        
        std::string toString() const {
            if (type == STRING) return strValue;
            std::ostringstream oss;
            oss << numValue;
            return oss.str();
        }
        
        double toNumber() const {
            if (type == NUMBER) return numValue;
            try {
                return std::stod(strValue);
            } catch (...) {
                return 0;
            }
        }
    };

    // Program storage
    std::map<int, std::string> program;
    std::map<std::string, Value> variables;
    std::map<std::string, int> labels;
    
    // Execution state
    int currentLine;
    bool running;
    int nextLine;
    
    // FOR loop state
    struct ForLoopState {
        std::string variable;
        double step;
        double end;
        int returnLine;
        
        // Default constructor required for std::map
        ForLoopState() : step(0), end(0), returnLine(0) {}
        
        ForLoopState(const std::string& var, double s, double e, int line)
            : variable(var), step(s), end(e), returnLine(line) {}
    };
    std::map<std::string, ForLoopState> forLoops;
    
    // Stack for GOSUB/RETURN
    std::stack<int> returnStack;
    
    // Lexical analysis state
    std::string currentLineText;
    size_t currentPos;
    
    // Function to read the next token from input
    Token getNextToken() {
        // Skip whitespace
        while (currentPos < currentLineText.size() && std::isspace(currentLineText[currentPos])) {
            currentPos++;
        }
        
        // Check for end of line
        if (currentPos >= currentLineText.size()) {
            return Token(EOL, "");
        }
        
        // Check for numbers
        if (std::isdigit(currentLineText[currentPos])) {
            std::string number;
            while (currentPos < currentLineText.size() && 
                  (std::isdigit(currentLineText[currentPos]) || currentLineText[currentPos] == '.')) {
                number += currentLineText[currentPos++];
            }
            return Token(NUMBER, number);
        }
        
        // Check for strings
        if (currentLineText[currentPos] == '"') {
            std::string str;
            currentPos++; // Skip opening quote
            while (currentPos < currentLineText.size() && currentLineText[currentPos] != '"') {
                str += currentLineText[currentPos++];
            }
            if (currentPos < currentLineText.size()) currentPos++; // Skip closing quote
            return Token(STRING, str);
        }
        
        // Check for identifiers and keywords
        if (std::isalpha(currentLineText[currentPos])) {
            std::string identifier;
            while (currentPos < currentLineText.size() && 
                  (std::isalnum(currentLineText[currentPos]) || currentLineText[currentPos] == '_')) {
                identifier += static_cast<char>(std::toupper(currentLineText[currentPos++]));
            }
            
            // Check if it's a keyword
            static const std::vector<std::string> keywords = {
                "PRINT", "LET", "IF", "THEN", "GOTO", "INPUT", "END", "REM",
                "FOR", "TO", "STEP", "NEXT", "GOSUB", "RETURN"
            };
            
            if (std::find(keywords.begin(), keywords.end(), identifier) != keywords.end()) {
                return Token(KEYWORD, identifier);
            }
            
            return Token(IDENTIFIER, identifier);
        }
        
        // Check for operators
        std::string operators = "+-*/()=<>:,";
        if (operators.find(currentLineText[currentPos]) != std::string::npos) {
            std::string op;
            char current = currentLineText[currentPos++];
            op += current;
            
            // Handle multi-character operators like <=, >=, <>
            if (current == '<' && currentPos < currentLineText.size()) {
                if (currentLineText[currentPos] == '=' || currentLineText[currentPos] == '>') {
                    op += currentLineText[currentPos++];
                }
            } else if (current == '>' && currentPos < currentLineText.size() && currentLineText[currentPos] == '=') {
                op += currentLineText[currentPos++];
            }
            
            return Token(OPERATOR, op);
        }
        
        // Unrecognized token
        std::string unknown;
        unknown += currentLineText[currentPos++];
        return Token(OPERATOR, unknown);
    }

    // Parse and evaluate expressions
    Value parseExpression() {
        return parseRelationalExpression();
    }
    
    Value parseRelationalExpression() {
        Value left = parseAddExpression();
        
        Token token = getNextToken();
        if (token.type == OPERATOR && (token.value == "=" || token.value == "<" || 
                                       token.value == ">" || token.value == "<=" || 
                                       token.value == ">=" || token.value == "<>")) {
            Value right = parseAddExpression();
            
            if (left.isNumber() && right.isNumber()) {
                double l = left.numValue;
                double r = right.numValue;
                
                if (token.value == "=") return Value(l == r ? 1.0 : 0.0);
                if (token.value == "<") return Value(l < r ? 1.0 : 0.0);
                if (token.value == ">") return Value(l > r ? 1.0 : 0.0);
                if (token.value == "<=") return Value(l <= r ? 1.0 : 0.0);
                if (token.value == ">=") return Value(l >= r ? 1.0 : 0.0);
                if (token.value == "<>") return Value(l != r ? 1.0 : 0.0);
            } else {
                std::string l = left.toString();
                std::string r = right.toString();
                
                if (token.value == "=") return Value(l == r ? 1.0 : 0.0);
                if (token.value == "<") return Value(l < r ? 1.0 : 0.0);
                if (token.value == ">") return Value(l > r ? 1.0 : 0.0);
                if (token.value == "<=") return Value(l <= r ? 1.0 : 0.0);
                if (token.value == ">=") return Value(l >= r ? 1.0 : 0.0);
                if (token.value == "<>") return Value(l != r ? 1.0 : 0.0);
            }
        } else {
            // Put the token back
            currentPos -= token.value.size();
        }
        
        return left;
    }
    
    Value parseAddExpression() {
        Value left = parseMultExpression();
        
        while (true) {
            Token token = getNextToken();
            if (token.type == OPERATOR && (token.value == "+" || token.value == "-")) {
                Value right = parseMultExpression();
                
                if (token.value == "+") {
                    if (left.isNumber() && right.isNumber()) {
                        left = Value(left.numValue + right.numValue);
                    } else {
                        left = Value(left.toString() + right.toString());
                    }
                } else { // "-"
                    if (left.isNumber() && right.isNumber()) {
                        left = Value(left.numValue - right.numValue);
                    } else {
                        throw std::runtime_error("Cannot subtract strings");
                    }
                }
            } else {
                // Put the token back
                currentPos -= token.value.size();
                break;
            }
        }
        
        return left;
    }
    
    Value parseMultExpression() {
        Value left = parsePrimaryExpression();
        
        while (true) {
            Token token = getNextToken();
            if (token.type == OPERATOR && (token.value == "*" || token.value == "/")) {
                Value right = parsePrimaryExpression();
                
                if (!left.isNumber() || !right.isNumber()) {
                    throw std::runtime_error("Cannot perform multiplication or division on strings");
                }
                
                if (token.value == "*") {
                    left = Value(left.numValue * right.numValue);
                } else { // "/"
                    if (right.numValue == 0) {
                        throw std::runtime_error("Division by zero");
                    }
                    left = Value(left.numValue / right.numValue);
                }
            } else {
                // Put the token back
                currentPos -= token.value.size();
                break;
            }
        }
        
        return left;
    }
    
    Value parsePrimaryExpression() {
        Token token = getNextToken();
        
        if (token.type == NUMBER) {
            return Value(std::stod(token.value));
        } else if (token.type == STRING) {
            return Value(token.value);
        } else if (token.type == IDENTIFIER) {
            std::string varName = token.value;
            if (variables.find(varName) != variables.end()) {
                return variables[varName];
            }
            return Value(0.0); // Default value for undefined variables
        } else if (token.type == OPERATOR && token.value == "(") {
            Value result = parseExpression();
            
            token = getNextToken();
            if (token.type != OPERATOR || token.value != ")") {
                throw std::runtime_error("Expected closing parenthesis");
            }
            
            return result;
        } else if (token.type == OPERATOR && token.value == "-") {
            // Unary minus
            Value operand = parsePrimaryExpression();
            if (!operand.isNumber()) {
                throw std::runtime_error("Cannot negate a string");
            }
            return Value(-operand.numValue);
        } else {
            throw std::runtime_error("Unexpected token: " + token.value);
        }
    }

    // Execute a BASIC statement
    void executeStatement(const std::string& stmt) {
        currentLineText = stmt;
        currentPos = 0;
        
        Token token = getNextToken();
        
        if (token.type == KEYWORD) {
            if (token.value == "PRINT") {
                executePrint();
            } else if (token.value == "LET") {
                executeLet();
            } else if (token.value == "IF") {
                executeIf();
            } else if (token.value == "GOTO") {
                executeGoto();
            } else if (token.value == "INPUT") {
                executeInput();
            } else if (token.value == "END") {
                running = false;
            } else if (token.value == "REM") {
                // Comments - do nothing
            } else if (token.value == "FOR") {
                executeFor();
            } else if (token.value == "NEXT") {
                executeNext();
            } else if (token.value == "GOSUB") {
                executeGosub();
            } else if (token.value == "RETURN") {
                executeReturn();
            } else {
                throw std::runtime_error("Unknown keyword: " + token.value);
            }
        } else if (token.type == IDENTIFIER) {
            // Implicit LET statement (e.g., X = 10)
            currentPos = 0; // Reset position
            executeLet(true);
        }
    }
    
    // Execute PRINT statement
    void executePrint() {
        bool first = true;
        
        while (true) {
            Token token = getNextToken();
            
            if (token.type == EOL) {
                std::cout << std::endl;
                break;
            }
            
            if (!first && token.type == OPERATOR && token.value == ";") {
                // Print items separated by semicolons - no space
            } else if (!first && token.type == OPERATOR && token.value == ",") {
                // Print items separated by commas - add tab
                std::cout << "\t";
            } else {
                if (!first) {
                    // Put token back to be reprocessed
                    currentPos -= token.value.size();
                }
                
                Value expr = parseExpression();
                std::cout << expr.toString();
                first = false;
                
                continue;
            }
            
            first = false;
        }
    }
    
    // Execute LET statement
    void executeLet(bool implicit = false) {
        if (!implicit) {
            // Skip the LET keyword if it's an explicit LET statement
            Token token = getNextToken();
            if (token.type != IDENTIFIER) {
                throw std::runtime_error("Expected variable name after LET");
            }
        } else {
            // For implicit LET, we're already positioned at the identifier
            getNextToken();
        }
        
        std::string varName = currentLineText.substr(currentPos - 1, 1);
        while (currentPos < currentLineText.size() && 
              (std::isalnum(currentLineText[currentPos]) || currentLineText[currentPos] == '_')) {
            varName += static_cast<char>(std::toupper(currentLineText[currentPos++]));
        }
        
        // Check for '=' operator
        Token token = getNextToken();
        if (token.type != OPERATOR || token.value != "=") {
            throw std::runtime_error("Expected '=' in assignment");
        }
        
        // Evaluate the expression and assign to variable
        Value value = parseExpression();
        variables[varName] = value;
    }
    
    // Execute IF statement
    void executeIf() {
        // Evaluate the condition
        Value condition = parseExpression();
        
        // Check for THEN keyword
        Token token = getNextToken();
        if (token.type != KEYWORD || token.value != "THEN") {
            throw std::runtime_error("Expected THEN after IF condition");
        }
        
        // Check if condition is true
        if (condition.toNumber() != 0) {
            // Execute the statement or GOTO after THEN
            token = getNextToken();
            
            if (token.type == NUMBER) {
                // It's a line number for GOTO
                int lineNum = std::stoi(token.value);
                if (program.find(lineNum) != program.end()) {
                    nextLine = lineNum;
                } else {
                    throw std::runtime_error("Line number not found: " + std::to_string(lineNum));
                }
            } else {
                // It's a statement to execute
                currentPos -= token.value.size(); // Put token back
                std::string remainingLine = currentLineText.substr(currentPos);
                executeStatement(remainingLine);
            }
        }
    }
    
    // Execute GOTO statement
    void executeGoto() {
        Token token = getNextToken();
        if (token.type != NUMBER) {
            throw std::runtime_error("Expected line number after GOTO");
        }
        
        int lineNum = std::stoi(token.value);
        if (program.find(lineNum) != program.end()) {
            nextLine = lineNum;
        } else {
            throw std::runtime_error("Line number not found: " + std::to_string(lineNum));
        }
    }
    
    // Execute INPUT statement
    void executeInput() {
        Token token = getNextToken();
        
        // Optional prompt string
        if (token.type == STRING) {
            std::cout << token.value;
            
            token = getNextToken();
            if (token.type == OPERATOR && token.value == ";") {
                token = getNextToken();
            } else {
                throw std::runtime_error("Expected semicolon after prompt in INPUT");
            }
        } else {
            std::cout << "? ";
        }
        
        // Get variable name
        if (token.type != IDENTIFIER) {
            throw std::runtime_error("Expected variable name in INPUT");
        }
        
        std::string varName = token.value;
        
        // Read input from user
        std::string input;
        std::getline(std::cin, input);
        
        // Try to convert to number, otherwise treat as string
        try {
            double value = std::stod(input);
            variables[varName] = Value(value);
        } catch (...) {
            variables[varName] = Value(input);
        }
    }
    
    // Execute FOR statement
    void executeFor() {
        // Get variable name
        Token token = getNextToken();
        if (token.type != IDENTIFIER) {
            throw std::runtime_error("Expected variable name after FOR");
        }
        std::string varName = token.value;
        
        // Check for '=' operator
        token = getNextToken();
        if (token.type != OPERATOR || token.value != "=") {
            throw std::runtime_error("Expected '=' after variable in FOR");
        }
        
        // Get initial value
        Value initial = parseExpression();
        variables[varName] = initial;
        
        // Check for TO keyword
        token = getNextToken();
        if (token.type != KEYWORD || token.value != "TO") {
            throw std::runtime_error("Expected TO in FOR statement");
        }
        
        // Get end value
        Value end = parseExpression();
        
        // Check for optional STEP
        double step = 1.0;
        token = getNextToken();
        if (token.type == KEYWORD && token.value == "STEP") {
            Value stepValue = parseExpression();
            step = stepValue.toNumber();
        } else {
            // Put token back
            currentPos -= token.value.size();
        }
        
        // Save FOR loop state
        forLoops[varName] = ForLoopState(varName, step, end.toNumber(), currentLine);
    }
    
    // Execute NEXT statement
    void executeNext() {
        // Get variable name
        Token token = getNextToken();
        if (token.type != IDENTIFIER) {
            throw std::runtime_error("Expected variable name after NEXT");
        }
        std::string varName = token.value;
        
        // Check if FOR loop exists
        if (forLoops.find(varName) == forLoops.end()) {
            throw std::runtime_error("NEXT without FOR: " + varName);
        }
        
        ForLoopState& loop = forLoops[varName];
        
        // Update loop variable
        double currentValue = variables[varName].toNumber();
        currentValue += loop.step;
        variables[varName] = Value(currentValue);
        
        // Check if loop should continue
        bool continueLoop = (loop.step > 0) ? (currentValue <= loop.end) : (currentValue >= loop.end);
        
        if (continueLoop) {
            // Jump back to the FOR statement
            nextLine = loop.returnLine;
        } else {
            // Loop complete, remove the loop state
            forLoops.erase(varName);
        }
    }
    
    // Execute GOSUB statement
    void executeGosub() {
        Token token = getNextToken();
        if (token.type != NUMBER) {
            throw std::runtime_error("Expected line number after GOSUB");
        }
        
        int lineNum = std::stoi(token.value);
        if (program.find(lineNum) != program.end()) {
            // Save return address
            returnStack.push(currentLine);
            nextLine = lineNum;
        } else {
            throw std::runtime_error("Line number not found: " + std::to_string(lineNum));
        }
    }
    
    // Execute RETURN statement
    void executeReturn() {
        if (returnStack.empty()) {
            throw std::runtime_error("RETURN without GOSUB");
        }
        
        nextLine = returnStack.top();
        returnStack.pop();
    }

    // Find the next line number in the program
    int findNextLine(int currentLineNum) {
        auto it = program.upper_bound(currentLineNum);
        if (it != program.end()) {
            return it->first;
        }
        return -1; // No more lines
    }

public:
    BasicInterpreter() : currentLine(0), running(false), nextLine(-1) {}
    
    // Load a BASIC program from file
    void loadProgram(const std::string& filename) {
        std::ifstream file(filename);
        if (!file.is_open()) {
            throw std::runtime_error("Could not open file: " + filename);
        }
        
        program.clear();
        variables.clear();
        labels.clear();
        
        std::string line;
        while (std::getline(file, line)) {
            // Skip empty lines
            if (line.empty()) continue;
            
            // Parse line number
            std::istringstream iss(line);
            int lineNum;
            if (!(iss >> lineNum)) {
                throw std::runtime_error("Invalid line number: " + line);
            }
            
            // Get the rest of the line
            std::string code;
            std::getline(iss, code);
            
            // Store in program
            program[lineNum] = code;
        }
    }
    
    // Run the loaded program
    void run() {
        if (program.empty()) {
            std::cout << "No program loaded" << std::endl;
            return;
        }
        
        // Reset state
        variables.clear();
        forLoops.clear();
        returnStack = std::stack<int>();
        running = true;
        
        // Start from the first line
        auto it = program.begin();
        currentLine = it->first;
        
        try {
            while (running) {
                // Execute current line
                nextLine = findNextLine(currentLine);
                executeStatement(program[currentLine]);
                
                // Move to next line
                if (nextLine != -1) {
                    currentLine = nextLine;
                } else {
                    running = false;
                }
            }
        } catch (const std::exception& e) {
            std::cerr << "Error at line " << currentLine << ": " << e.what() << std::endl;
        }
    }
};

int main(int argc, char* argv[]) {
    if (argc < 2) {
        std::cout << "Usage: " << argv[0] << " <filename.bas>" << std::endl;
        return 1;
    }
    
    BasicInterpreter interpreter;
    
    try {
        interpreter.loadProgram(argv[1]);
        interpreter.run();
    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }
    
    return 0;
}