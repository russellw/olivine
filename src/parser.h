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

	void argAttrs() {
		if (token == "noundef") {
			lex();
		}
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
		string errorMsg = file + ":" + to_string(currentLine(input, pos)) + ": " + msg;

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

	Term expr(Type ty) {
		// SORT BLOCKS
		if (token == "false") {
			if (ty != boolTy()) {
				throw error("type mismatch");
			}
			lex();
			return falseConst;
		}
		if (token == "null") {
			if (ty != ptrTy()) {
				throw error("type mismatch");
			}
			lex();
			return nullConst;
		}
		if (token == "true") {
			if (ty != boolTy()) {
				throw error("type mismatch");
			}
			lex();
			return trueConst;
		}
		if (token[0] == '%') {
			return parseVar(ty);
		}
		// END
		if (isDigit(token[0])) {
			auto a = intConst(ty, cpp_int(token));
			lex();
			return a;
		}
		throw error(quote(token) + ": expected expression");
	}

	void fastMathFlags() {
		while (token == "fast" || token == "nnan" || token == "ninf" || token == "nsz") {
			lex();
		}
	}

	void id() {
		if (input[pos] == '"') {
			lexQuote();
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
				lexQuote();
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
					lexQuote();
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

	void lexQuote() {
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
			module->funcs.push_back(parseFunc());
			return;
		}
	}

	Term parseArg() {
		auto ty = type();
		argAttrs();
		return expr(ty);
	}

	vector<Term> parseArgs() {
		expect("(");
		vector<Term> v;
		if (token != ")") {
			do {
				v.push_back(parseArg());
			} while (maybeComma());
		}
		expect(")");
		return v;
	}

	Term parseCall() {
		expect("call");
		auto rty = type();
		auto ref = parseGlobalRef();
		auto args = parseArgs();
		auto params = map(args, [](Term a) { return a.ty(); });
		auto fty = funcTy(rty, params);
		auto f = globalRef(fty, ref);
		return call(rty, f, args);
	}

	Func parseFunc() {
		if (!(token == "declare" || token == "define")) {
			throw error("expected 'declare' or 'define'");
		}
		auto define = token == "define";
		lex();

		dsoPreemptable();

		// Return type
		auto rty = type();

		// Name
		if (token[0] != '@') {
			throw error("expected global name");
		}
		auto ref = parseRef1();

		// Parameters
		auto params = parseParams();
		auto paramTypes = map(params, [](Term a) { return a.ty(); });

		// Only declare
		if (!define) {
			return Func(rty, ref, params);
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
		auto insts = parseInsts();

		// Closing brace
		expect("}");

		return Func(rty, ref, params, insts);
	}

	Ref parseGlobalRef() {
		if (token[0] != '@') {
			throw error(quote(token) + ": expected global name");
		}
		return parseRef1();
	}

	Inst parseInst() {
		if (token.back() == ':') {
			return block(parseRef(token.substr(0, token.size() - 1)));
		}

		// SORT BLOCKS
		if (token == "br") {
			lex();
			if (token == "label") {
				lex();
				return jmp(parseRef1());
			}
			auto cond = typeExpr();
			expect(",");
			expect("label");
			auto ifTrue = parseRef1();
			expect(",");
			expect("label");
			auto ifFalse = parseRef1();
			return br(cond, ifTrue, ifFalse);
		}
		if (token == "call") {
			return Inst(Drop, parseCall());
		}
		if (token == "ret") {
			lex();
			if (token == "void") {
				return ret();
			}
			return ret(typeExpr());
		}
		if (token == "store") {
			lex();
			auto a = typeExpr();
			expect(",");
			expect("ptr");
			auto p = expr(ptrTy());
			return Inst(Store, a, p);
		}
		if (token == "unreachable") {
			return unreachable();
		}
		if (token[0] == '%') {
			auto lval = parseRef(token);
			lex();
			expect("=");
			if (token == "alloca") {
				lex();
				auto ty = type();
				expect(",");
				auto n = typeExpr();
				return alloca(var(ptrTy(), lval), ty, n);
			}
			auto rval = parseRVal();
			return assign(var(rval.ty(), lval), rval);
		}
		// END

		throw error(quote(token) + ": expected inst");
	}

	vector<Inst> parseInsts() {
		vector<Inst> insts;
		while (token != "}") {
			if (token != "\n") {
				insts.push_back(parseInst());
			}
			nextLine();
		}
		return insts;
	}

	int parseInt() {
		if (!all_of(token.begin(), token.end(), isDigit)) {
			throw error("expected integer");
		}
		auto n = stoull(token);
		lex();
		return n;
	}

	Term parseParam() {
		auto ty = type();
		paramAttrs();
		return parseVar(ty);
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

	Term parseRVal() {
		// SORT BLOCKS
		if (token == "add") {
			lex();
			noWrap();
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(Add, ty, a, b);
		}
		if (token == "and") {
			lex();
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(And, ty, a, b);
		}
		if (token == "ashr") {
			lex();
			if (token == "exact") {
				lex();
			}
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(AShr, ty, a, b);
		}
		if (token == "call") {
			return parseCall();
		}
		if (token == "fadd") {
			lex();
			fastMathFlags();
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(FAdd, ty, a, b);
		}
		if (token == "fcmp") {
			lex();
			fastMathFlags();
			// SORT BLOCKS
			if (token == "oeq") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(FEq, a, b);
			}
			if (token == "ole") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(FLe, a, b);
			}
			if (token == "olt") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(FLt, a, b);
			}
			if (token == "oge") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(FLe, b, a);
			}
			if (token == "ogt") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(FLt, b, a);
			}
			if (token == "uge") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return not1(cmp(FLt, a, b));
			}
			if (token == "ugt") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return not1(cmp(FLe, a, b));
			}
			if (token == "ule") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return not1(cmp(FLt, b, a));
			}
			if (token == "ult") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return not1(cmp(FLe, b, a));
			}
			if (token == "une") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return not1(cmp(FEq, b, a));
			}
			// END
			throw error(quote(token) + ": expected condition");
		}
		if (token == "fdiv") {
			lex();
			fastMathFlags();
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(FDiv, ty, a, b);
		}
		if (token == "fmul") {
			lex();
			fastMathFlags();
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(FMul, ty, a, b);
		}
		if (token == "fneg") {
			lex();
			fastMathFlags();
			auto ty = type();
			auto a = expr(ty);
			return Term(FNeg, ty, a);
		}
		if (token == "frem") {
			lex();
			fastMathFlags();
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(FRem, ty, a, b);
		}
		if (token == "fsub") {
			lex();
			fastMathFlags();
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(FSub, ty, a, b);
		}
		if (token == "icmp") {
			lex();
			// SORT BLOCKS
			if (token == "eq") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(Eq, a, b);
			}
			if (token == "ne") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return not1(cmp(Eq, b, a));
			}
			if (token == "sle") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(SLe, a, b);
			}
			if (token == "slt") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(SLt, a, b);
			}
			if (token == "sge") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(SLe, b, a);
			}
			if (token == "sgt") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(SLt, b, a);
			}
			if (token == "ule") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(ULe, a, b);
			}
			if (token == "ult") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(ULt, a, b);
			}
			if (token == "uge") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(ULe, b, a);
			}
			if (token == "ugt") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(ULt, b, a);
			}
			// END
			throw error(quote(token) + ": expected condition");
		}
		if (token == "load") {
			lex();
			auto ty = type();
			expect(",");
			expect("ptr");
			auto a = expr(ty);
			return Term(Load, ty, a);
		}
		if (token == "lshr") {
			lex();
			if (token == "exact") {
				lex();
			}
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(LShr, ty, a, b);
		}
		if (token == "mul") {
			lex();
			noWrap();
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(Mul, ty, a, b);
		}
		if (token == "or") {
			lex();
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(Or, ty, a, b);
		}
		if (token == "sdiv") {
			lex();
			if (token == "exact") {
				lex();
			}
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(SDiv, ty, a, b);
		}
		if (token == "sext" || token == "fptosi" || token == "sitofp") {
			lex();
			auto a = typeExpr();
			expect("to");
			auto ty = type();
			return Term(SCast, ty, a);
		}
		if (token == "shl") {
			lex();
			noWrap();
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(Shl, ty, a, b);
		}
		if (token == "srem") {
			lex();
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(SRem, ty, a, b);
		}
		if (token == "sub") {
			lex();
			noWrap();
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(Sub, ty, a, b);
		}
		if (token == "trunc" || token == "zext" || token == "fptrunc" || token == "fpext" || token == "fptoui" ||
			token == "uitofp" || token == "ptrtoint" || token == "inttoptr" || token == "bitcast") {
			lex();
			auto a = typeExpr();
			expect("to");
			auto ty = type();
			return Term(Cast, ty, a);
		}
		if (token == "udiv") {
			lex();
			if (token == "exact") {
				lex();
			}
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(UDiv, ty, a, b);
		}
		if (token == "urem") {
			lex();
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(URem, ty, a, b);
		}
		if (token == "xor") {
			lex();
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(Xor, ty, a, b);
		}
		// END

		throw error(quote(token) + ": expected rval");
	}

	Ref parseRef1() {
		auto r = parseRef(token);
		lex();
		return r;
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

	Term parseVar(Type ty) {
		if (token[0] != '%') {
			throw error("expected variable name");
		}
		return var(ty, parseRef1());
	}

	Type primaryType() {
		// SORT BLOCKS
		if (token == "<") {
			lex();
			auto len = parseInt();
			expect("x");
			auto element = type();
			expect(">");
			return vecTy(len, element);
		}
		if (token == "[") {
			lex();
			auto len = parseInt();
			expect("x");
			auto element = type();
			expect("]");
			return arrayTy(len, element);
		}
		if (token == "double") {
			lex();
			return doubleTy();
		}
		if (token == "float") {
			lex();
			return floatTy();
		}
		if (token == "ptr") {
			lex();
			return ptrTy();
		}
		if (token == "void") {
			lex();
			return voidTy();
		}
		if (token[0] == 'i') {
			auto len = stoull(token.substr(1));
			lex();
			return intTy(len);
		}
		// END

		throw error("expected type");
	}

	void setConsistent(string& var, const string& val, const char* name) {
		ASSERT(val.size());
		if (var.size() && var != val) {
			throw error(string("inconsistent ") + name);
		}
		var = val;
	}

	Type type() {
		auto ty = primaryType();
		return ty;
	}

	Term typeExpr() {
		return expr(type());
	}

public:
	Module* module = new Module;

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
