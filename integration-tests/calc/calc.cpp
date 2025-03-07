#include <iostream>
#include <string>
#include <sstream>
#include <stack>
#include <cctype>
#include <cmath>
#include <boost/multiprecision/cpp_dec_float.hpp>

// Define decimal type with 50 digits of precision
using decimal = boost::multiprecision::cpp_dec_float_50;

class Calculator {
private:
    std::stack<decimal> values;
    std::string current_input;
    bool last_was_operation;

    // Helper function to check if a character is an operator
    bool is_operator(char c) {
        return c == '+' || c == '-' || c == '*' || c == '/' || c == '^';
    }

    // Execute binary operation
    void execute_binary_operation(char op) {
        if (values.size() < 2) {
            std::cout << "Error: Not enough values for operation" << std::endl;
            return;
        }

        decimal b = values.top(); values.pop();
        decimal a = values.top(); values.pop();
        decimal result;

        switch (op) {
            case '+': result = a + b; break;
            case '-': result = a - b; break;
            case '*': result = a * b; break;
            case '/':
                if (b == 0) {
                    std::cout << "Error: Division by zero" << std::endl;
                    values.push(a); // Push a back
                    values.push(b); // Push b back
                    return;
                }
                result = a / b;
                break;
            case '^':
                try {
                    // pow function for cpp_dec_float may throw for certain inputs
                    result = pow(a, b);
                } catch (const std::exception& e) {
                    std::cout << "Error: " << e.what() << std::endl;
                    values.push(a); // Push a back
                    values.push(b); // Push b back
                    return;
                }
                break;
            default:
                std::cout << "Error: Unknown operator" << std::endl;
                values.push(a); // Push a back
                values.push(b); // Push b back
                return;
        }

        values.push(result);
        std::cout << "= " << result << std::endl;
        last_was_operation = true;
    }

    // Parse and process input
    void process_input(const std::string& input) {
        if (input.empty()) return;

        // Check for commands
        if (input == "q" || input == "quit" || input == "exit") {
            std::cout << "Exiting calculator..." << std::endl;
            exit(0);
        } else if (input == "c" || input == "clear") {
            // Clear the stack
            while (!values.empty()) values.pop();
            std::cout << "Stack cleared" << std::endl;
            return;
        } else if (input == "h" || input == "help") {
            show_help();
            return;
        }

        // Handle single operator case
        if (input.length() == 1 && is_operator(input[0])) {
            execute_binary_operation(input[0]);
            return;
        }

        // Try to parse as number
        try {
            std::stringstream ss(input);
            decimal value;
            ss >> value;
            
            if (ss.fail() || !ss.eof()) {
                std::cout << "Error: Invalid input '" << input << "'" << std::endl;
                return;
            }
            
            values.push(value);
            std::cout << "Pushed: " << value << std::endl;
            last_was_operation = false;
        } catch (const std::exception& e) {
            std::cout << "Error parsing number: " << e.what() << std::endl;
        }
    }

public:
    Calculator() : last_was_operation(false) {}

    void run() {
        show_help();
        
        std::string input;
        while (true) {
            std::cout << "> ";
            std::getline(std::cin, input);
            process_input(input);
        }
    }

    void show_help() {
        std::cout << "RPN Calculator with Arbitrary Precision\n";
        std::cout << "--------------------------------------\n";
        std::cout << "Enter numbers to push them onto the stack\n";
        std::cout << "Enter operators (+, -, *, /, ^) to perform operations\n";
        std::cout << "Commands:\n";
        std::cout << "  h, help  - Show this help message\n";
        std::cout << "  c, clear - Clear the stack\n";
        std::cout << "  q, quit  - Exit the calculator\n";
        std::cout << "--------------------------------------\n";
    }
};

int main() {
    try {
        Calculator calc;
        calc.run();
    } catch (const std::exception& e) {
        std::cerr << "Fatal error: " << e.what() << std::endl;
        return 1;
    }

    return 0;
}