struct Target {
	string datalayout;
	string triple;
};

class Parser {
	const string& file;
	string input;
	size_t pos = 0;
	string token;
	Target& target;

	// End of file is indicated by a token that cannot correspond to any actual token
	// but is still nonempty, so parsing code can safely check the first character of current token
	const string eof = " ";

	// SORT FUNCTIONS

	// Count newlines before current position to get line number
	size_t currentLine() const {
		size_t line = 1;
		for (size_t i = 0; i < pos; i++) {
			if (input[i] == '\n') {
				line++;
			}
		}
		return line;
	}

	bool dsoPreemptable() {
		if (token == "dso_local") {
			lex();
			return false;
		}
		if (token == "dso_preemptable") {
			lex();
			return true;
		}

		// If a preemption specifier isn’t given explicitly, then a symbol is assumed to be dso_preemptable.
		return true;
	}

	// This function takes:
	// The name of the input file, stored
	// The current line number, calculated from the count of newline characters before pos
	// The error message, supplied as a parameter
	// and returns an exception with a composite error message suitable for printing
	runtime_error error(const string& msg) const {
		// Build error message with format "file:line: error message"
		string errorMsg = file + ":" + to_string(currentLine()) + ": " + msg;

		// Return exception with the formatted message
		return runtime_error(errorMsg);
	}

	void expect(const string& s) {
		if (token == s) {
			lex();
			return;
		}
		throw error("expected '" + s + '\'');
	}

	Term expr(Type type) {
		// SORT BLOCKS
		if (token == "false") {
			if (type != boolType()) {
				throw error("type mismatch");
			}
			lex();
			return falseConst;
		}
		if (token == "null") {
			if (type != ptrType()) {
				throw error("type mismatch");
			}
			lex();
			return nullConst;
		}
		if (token == "true") {
			if (type != boolType()) {
				throw error("type mismatch");
			}
			lex();
			return trueConst;
		}
		if (token[0] == '%') {
			return parseVar(type);
		}
		// END
		if (isDigit(token[0])) {
			auto a = intConst(type, cpp_int(token));
			lex();
			return a;
		}
		throw error('\'' + token + "': expected expression");
	}

	void fastMathFlags() {
		while (token == "fast" || token == "nnan" || token == "ninf" || token == "nsz") {
			lex();
		}
	}

	void id() {
		if (input[pos] == '"') {
			quote();
			return;
		}
		if (!isIdPart(input[pos])) {
			throw error("expected identifier");
		}
		while (isIdPart(input[pos])) {
			token += input[pos++];
		}
	}

	void lex() {
		while (pos < input.size()) {
			if (containsAt(input, pos, "...")) {
				token = input.substr(pos, 3);
				pos += 3;
				return;
			}
			switch (input[pos]) {
			case ' ':
			case '\f':
			case '\r':
			case '\t':
				pos++;
				continue;
			case '"':
				token.clear();
				quote();
				maybeColon();
				return;
			case '%':
			case '@':
				token = input.substr(pos++, 1);
				id();
				return;
			case ';':
				while (input[pos] != '\n') {
					pos++;
				}
				continue;
			case 'c':
				if (input[pos + 1] == '"') {
					token = input.substr(pos++, 1);
					quote();
					return;
				}
				break;
			}
			if (isIdPart(input[pos])) {
				token.clear();
				id();
				maybeColon();
				return;
			}
			token = input.substr(pos++, 1);
			return;
		}
		token = eof;
	}

	void maybeColon() {
		if (input[pos] == ':') {
			token += input[pos++];
		}
	}

	bool maybeComma() {
		if (token == ",") {
			lex();
			return true;
		}
		return false;
	}

	void newline() {
		if (token == "\n") {
			lex();
			return;
		}
		throw error("expected newline");
	}

	void nextLine() {
		while (token != "\n") {
			if (token == eof) {
				stackTrace();
				throw error("unexpected end of file");
			}
			lex();
		}
		lex();
	}

	void noWrap() {
		if (token == "nuw") {
			lex();
		}
		if (token == "nsw") {
			lex();
		}
	}

	void paramAttrs() {
		while (isLower(token[0])) {
			lex();
		}
	}

	void parse() {
		if (token == "target") {
			parseTarget();
			return;
		}
		if (token == "declare" || token == "define") {
			globals.push_back(parseFunction());
			return;
		}
	}

	Term parseFunction() {
		if (!(token == "declare" || token == "define")) {
			throw error("expected 'declare' or 'define'");
		}
		auto define = token == "define";
		lex();

		dsoPreemptable();

		// Return type
		auto returnType = parseType();

		// Name
		if (token[0] != '@') {
			throw error("expected global name");
		}
		auto name = token;
		lex();

		// Parameters
		auto params = parseParams();
		auto paramTypes = map(params, [](Term a) { return a.type(); });
		auto ref = parseGlobal(functionType(returnType, paramTypes), name);

		// Only declare
		if (!define) {
			return function(returnType, ref, params, {});
		}

		// Trailing tokens
		while (token != "{") {
			if (token == "\n" || token == eof) {
				throw error("expected '{'");
			}
			lex();
		}

		// Opening brace
		expect("{");
		newline();

		// Instructions
		auto instructions = parseInstructions();

		// Closing brace
		expect("}");

		return function(returnType, ref, params, instructions);
	}

	Term parseGlobal(Type type, const string& token) const {
		if (token[0] != '@') {
			throw error("expected global name");
		}
		Term a;
		if (isDigit(token[1])) {
			a = globalRef(type, stoi(token.substr(1)));
		} else {
			a = globalRef(type, unwrap(token));
		}
		return a;
	}

	Term parseInstruction() {
		// SORT BLOCKS
		if (token == "br") {
			lex();
			if (token == "label") {
				lex();
				return go(parseVar(ptrType()));
			}
			auto cond = typeExpr();
			expect(",");
			expect("label");
			auto ifTrue = parseVar(ptrType());
			expect(",");
			expect("label");
			auto ifFalse = parseVar(ptrType());
			return br(cond, ifTrue, ifFalse);
		}
		if (token == "ret") {
			lex();
			if (token == "void") {
				return Term(RetVoid);
			}
			return Term(Ret, voidType(), typeExpr());
		}
		if (token == "unreachable") {
			lex();
			return Term(Unreachable);
		}
		if (token[0] == '%') {
			auto lvalName = token.substr(1);
			lex();
			expect("=");
			auto rval = parseRval();
			auto lval = parseVar(rval.type(), lvalName);
			return Term(Assign, voidType(), lval, rval);
		}
		// END
		throw error('\'' + token + "': expected instruction");
	}

	vector<Term> parseInstructions() {
		unordered_map<Term, size_t> labels;
		vector<Term> instructions;
		while (token != "}") {
			// Blank line
			if (token == "\n") {
				lex();
				continue;
			}

			// Label
			if (token.back() == ':') {
				auto label = parseVar(ptrType(), token.substr(0, token.size() - 1));
				if (labels.count(label)) {
					throw error("duplicate label");
				}
				labels[label] = instructions.size();
				nextLine();
				continue;
			}

			// Instruction
			instructions.push_back(parseInstruction());
			nextLine();
		}
		resolveLabels(labels, instructions);
		return instructions;
	}

	int parseInt() {
		if (!all_of(token.begin(), token.end(), isDigit)) {
			throw error("expected integer");
		}
		auto n = stoi(token);
		lex();
		return n;
	}

	Term parseParam() {
		auto type = parseType();
		paramAttrs();
		return parseVar(type);
	}

	vector<Term> parseParams() {
		expect("(");
		vector<Term> v;
		if (token != ")") {
			do {
				v.push_back(parseParam());
			} while (maybeComma());
		}
		expect(")");
		return v;
	}

	Term parseRval() {
		// SORT BLOCKS
		if (token == "add") {
			lex();
			noWrap();
			auto type = parseType();
			auto a = expr(type);
			expect(",");
			auto b = expr(type);
			return Term(Add, type, a, b);
		}
		if (token == "and") {
			lex();
			auto type = parseType();
			auto a = expr(type);
			expect(",");
			auto b = expr(type);
			return Term(And, type, a, b);
		}
		if (token == "ashr") {
			lex();
			if (token == "exact") {
				lex();
			}
			auto type = parseType();
			auto a = expr(type);
			expect(",");
			auto b = expr(type);
			return Term(AShr, type, a, b);
		}
		if (token == "fadd") {
			lex();
			fastMathFlags();
			auto type = parseType();
			auto a = expr(type);
			expect(",");
			auto b = expr(type);
			return Term(FAdd, type, a, b);
		}
		if (token == "fcmp") {
			lex();
			fastMathFlags();
			// SORT BLOCKS
			if (token == "oeq") {
				lex();
				auto type = parseType();
				auto a = expr(type);
				expect(",");
				auto b = expr(type);
				return Term(FEq, boolType(), a, b);
			}
			if (token == "ole") {
				lex();
				auto type = parseType();
				auto a = expr(type);
				expect(",");
				auto b = expr(type);
				return Term(FLe, boolType(), a, b);
			}
			if (token == "olt") {
				lex();
				auto type = parseType();
				auto a = expr(type);
				expect(",");
				auto b = expr(type);
				return Term(FLt, boolType(), a, b);
			}
			if (token == "oge") {
				lex();
				auto type = parseType();
				auto a = expr(type);
				expect(",");
				auto b = expr(type);
				return Term(FLe, boolType(), b, a);
			}
			if (token == "ogt") {
				lex();
				auto type = parseType();
				auto a = expr(type);
				expect(",");
				auto b = expr(type);
				return Term(FLt, boolType(), b, a);
			}
			if (token == "uge") {
				lex();
				auto type = parseType();
				auto a = expr(type);
				expect(",");
				auto b = expr(type);
				return Term(Not, boolType(), Term(FLt, boolType(), a, b));
			}
			if (token == "ugt") {
				lex();
				auto type = parseType();
				auto a = expr(type);
				expect(",");
				auto b = expr(type);
				return Term(Not, boolType(), Term(FLe, boolType(), a, b));
			}
			if (token == "ule") {
				lex();
				auto type = parseType();
				auto a = expr(type);
				expect(",");
				auto b = expr(type);
				return Term(Not, boolType(), Term(FLt, boolType(), b, a));
			}
			if (token == "ult") {
				lex();
				auto type = parseType();
				auto a = expr(type);
				expect(",");
				auto b = expr(type);
				return Term(Not, boolType(), Term(FLe, boolType(), b, a));
			}
			if (token == "une") {
				lex();
				auto type = parseType();
				auto a = expr(type);
				expect(",");
				auto b = expr(type);
				return Term(Not, boolType(), Term(FEq, boolType(), b, a));
			}
			// END
			throw error('\'' + token + "': expected condition");
		}
		if (token == "fdiv") {
			lex();
			fastMathFlags();
			auto type = parseType();
			auto a = expr(type);
			expect(",");
			auto b = expr(type);
			return Term(FDiv, type, a, b);
		}
		if (token == "fmul") {
			lex();
			fastMathFlags();
			auto type = parseType();
			auto a = expr(type);
			expect(",");
			auto b = expr(type);
			return Term(FMul, type, a, b);
		}
		if (token == "fneg") {
			lex();
			fastMathFlags();
			auto type = parseType();
			auto a = expr(type);
			return Term(FNeg, type, a);
		}
		if (token == "frem") {
			lex();
			fastMathFlags();
			auto type = parseType();
			auto a = expr(type);
			expect(",");
			auto b = expr(type);
			return Term(FRem, type, a, b);
		}
		if (token == "fsub") {
			lex();
			fastMathFlags();
			auto type = parseType();
			auto a = expr(type);
			expect(",");
			auto b = expr(type);
			return Term(FSub, type, a, b);
		}
		if (token == "icmp") {
			lex();
			// SORT BLOCKS
			if (token == "eq") {
				lex();
				auto type = parseType();
				auto a = expr(type);
				expect(",");
				auto b = expr(type);
				return Term(Eq, boolType(), a, b);
			}
			if (token == "ne") {
				lex();
				auto type = parseType();
				auto a = expr(type);
				expect(",");
				auto b = expr(type);
				return Term(Not, boolType(), Term(Eq, boolType(), b, a));
			}
			if (token == "sle") {
				lex();
				auto type = parseType();
				auto a = expr(type);
				expect(",");
				auto b = expr(type);
				return Term(SLe, boolType(), a, b);
			}
			if (token == "slt") {
				lex();
				auto type = parseType();
				auto a = expr(type);
				expect(",");
				auto b = expr(type);
				return Term(SLt, boolType(), a, b);
			}
			if (token == "sge") {
				lex();
				auto type = parseType();
				auto a = expr(type);
				expect(",");
				auto b = expr(type);
				return Term(SLe, boolType(), b, a);
			}
			if (token == "sgt") {
				lex();
				auto type = parseType();
				auto a = expr(type);
				expect(",");
				auto b = expr(type);
				return Term(SLt, boolType(), b, a);
			}
			if (token == "ule") {
				lex();
				auto type = parseType();
				auto a = expr(type);
				expect(",");
				auto b = expr(type);
				return Term(ULe, boolType(), a, b);
			}
			if (token == "ult") {
				lex();
				auto type = parseType();
				auto a = expr(type);
				expect(",");
				auto b = expr(type);
				return Term(ULt, boolType(), a, b);
			}
			if (token == "uge") {
				lex();
				auto type = parseType();
				auto a = expr(type);
				expect(",");
				auto b = expr(type);
				return Term(ULe, boolType(), b, a);
			}
			if (token == "ugt") {
				lex();
				auto type = parseType();
				auto a = expr(type);
				expect(",");
				auto b = expr(type);
				return Term(ULt, boolType(), b, a);
			}
			// END
			throw error('\'' + token + "': expected condition");
		}
		if (token == "lshr") {
			lex();
			if (token == "exact") {
				lex();
			}
			auto type = parseType();
			auto a = expr(type);
			expect(",");
			auto b = expr(type);
			return Term(LShr, type, a, b);
		}
		if (token == "mul") {
			lex();
			noWrap();
			auto type = parseType();
			auto a = expr(type);
			expect(",");
			auto b = expr(type);
			return Term(Mul, type, a, b);
		}
		if (token == "or") {
			lex();
			auto type = parseType();
			auto a = expr(type);
			expect(",");
			auto b = expr(type);
			return Term(Or, type, a, b);
		}
		if (token == "sdiv") {
			lex();
			if (token == "exact") {
				lex();
			}
			auto type = parseType();
			auto a = expr(type);
			expect(",");
			auto b = expr(type);
			return Term(SDiv, type, a, b);
		}
		if (token == "shl") {
			lex();
			noWrap();
			auto type = parseType();
			auto a = expr(type);
			expect(",");
			auto b = expr(type);
			return Term(Shl, type, a, b);
		}
		if (token == "srem") {
			lex();
			auto type = parseType();
			auto a = expr(type);
			expect(",");
			auto b = expr(type);
			return Term(SRem, type, a, b);
		}
		if (token == "sub") {
			lex();
			noWrap();
			auto type = parseType();
			auto a = expr(type);
			expect(",");
			auto b = expr(type);
			return Term(Sub, type, a, b);
		}
		if (token == "udiv") {
			lex();
			if (token == "exact") {
				lex();
			}
			auto type = parseType();
			auto a = expr(type);
			expect(",");
			auto b = expr(type);
			return Term(UDiv, type, a, b);
		}
		if (token == "urem") {
			lex();
			auto type = parseType();
			auto a = expr(type);
			expect(",");
			auto b = expr(type);
			return Term(URem, type, a, b);
		}
		if (token == "xor") {
			lex();
			auto type = parseType();
			auto a = expr(type);
			expect(",");
			auto b = expr(type);
			return Term(Xor, type, a, b);
		}
		// END
		throw error('\'' + token + "': expected rval");
	}

	void parseTarget() {
		expect("target");
		if (token == "datalayout") {
			lex();
			expect("=");
			if (token[0] != '"') {
				throw error("expected string");
			}
			setConsistent(target.datalayout, unwrap(token), "datalayout");
			return;
		}
		if (token == "triple") {
			lex();
			expect("=");
			if (token[0] != '"') {
				throw error("expected string");
			}
			setConsistent(target.triple, unwrap(token), "triple");
			return;
		}
	}

	Type parseType() {
		auto type = primaryType();
		return type;
	}

	Term parseVar(Type type) {
		if (token[0] != '%') {
			throw error("expected variable name");
		}
		auto a = parseVar(type, token.substr(1));
		lex();
		return a;
	}

	// The code to parse a partly digested local variable token
	// is factored out into a separate function
	// so it can also be used for labels
	static Term parseVar(Type type, const string& s) {
		if (isDigit(s[1])) {
			return var(type, stoi(s));
		}
		return var(type, unwrap(s));
	}

	Type primaryType() {
		if (token == "void") {
			lex();
			return voidType();
		}
		if (token == "float") {
			lex();
			return floatType();
		}
		if (token == "double") {
			lex();
			return doubleType();
		}
		if (token == "ptr") {
			lex();
			return ptrType();
		}
		if (token == "<") {
			lex();
			auto len = parseInt();
			expect("x");
			auto element = parseType();
			expect(">");
			return vecType(len, element);
		}
		if (token == "[") {
			lex();
			auto len = parseInt();
			expect("x");
			auto element = parseType();
			expect("]");
			return arrayType(len, element);
		}
		if (token[0] == 'i') {
			auto len = stoi(token.substr(1));
			lex();
			return intType(len);
		}
		throw error("expected type");
	}

	void quote() {
		ASSERT(input[pos] == '"');
		for (auto i = pos + 1; i < input.size(); i++) {
			if (input[i] == '"') {
				i++;
				token += input.substr(pos, i - pos);
				pos = i;
				return;
			}
		}
		throw error("unclosed quote");
	}

	// After parsing, branch targets are unresolved labels, represented as variables
	// These need to be replaced with integer offsets
	static void resolveLabels(const unordered_map<Term, size_t>& labels, vector<Term>& instructions) {
		// For each instruction in the function
		for (size_t i = 0; i < instructions.size(); i++) {
			Term& inst = instructions[i];

			// Handle different branch instructions
			switch (inst.tag()) {
			case Tag::Goto: {
				// For unconditional branches, replace the label with its offset
				Term target = inst[0];
				if (target.tag() == Tag::Var) {
					auto it = labels.find(target);
					if (it == labels.end()) {
						throw runtime_error("undefined label");
					}
					// Replace the instruction with a new goto using the resolved offset
					instructions[i] = go(it->second);
				}
				break;
			}
			case Tag::If: {
				// For conditional branches, we need to resolve both true and false targets
				Term condition = inst[0];
				Term trueTarget = inst[1][0];
				Term falseTarget = inst[2][0];

				// Only process if the targets are variables (labels)
				if (trueTarget.tag() == Tag::Var || falseTarget.tag() == Tag::Var) {
					// Resolve true branch
					size_t trueOffset =
						trueTarget.tag() == Tag::Var ? labels.at(trueTarget) : trueTarget.intVal().convert_to<size_t>();

					// Resolve false branch
					size_t falseOffset =
						falseTarget.tag() == Tag::Var ? labels.at(falseTarget) : falseTarget.intVal().convert_to<size_t>();

					// Replace the instruction with a new branch using resolved offsets
					instructions[i] = br(condition, trueOffset, falseOffset);
				}
				break;
			}
			default:
				// Other instructions don't contain label references
				break;
			}
		}
	}

	void setConsistent(string& var, const string& val, const char* name) {
		ASSERT(val.size());
		if (var.size() && var != val) {
			throw error(string("inconsistent ") + name);
		}
		var = val;
	}

	Term typeExpr() {
		return expr(parseType());
	}

public:
	vector<Term> globals;

	Parser(const string& file, const string& input, Target& target): file(file), input(input), target(target) {
		if (!endsWith(input, '\n')) {
			this->input += '\n';
		}
		lex();
		while (token != eof) {
			parse();
			nextLine();
		}
	}
};
