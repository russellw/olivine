struct Target {
	string datalayout;
	string triple;
};

class Parser {
	const string& file;
	string text;
	size_t pos = 0;
	string token;
	Target& target;

	// End of file is indicated by a token that cannot correspond to any actual token
	// but is still nonempty, so parsing code can safely check the first character of current token
	const string eof = " ";

	// SORT FUNCTIONS

	Term arg1() {
		auto ty = type();
		argAttrs();
		return expr(ty);
	}

	void argAttrs() {
		if (token == "noundef") {
			lex();
		}
	}

	vector<Term> args1() {
		expect("(");
		vector<Term> v;
		if (token != ")") {
			do {
				v.push_back(arg1());
			} while (maybeComma());
		}
		expect(")");
		return v;
	}

	Func declare() {
		expect("declare");
		dsoPreemptable();

		// Return type
		auto rty = type();

		// Name
		auto ref = globalRef1();

		// Parameters
		auto params = params1();
		auto paramTypes = map(params, [](Term a) { return a.ty(); });

		return Func(rty, ref, params);
	}

	Func define() {
		expect("define");
		dsoPreemptable();

		// Return type
		auto rty = type();

		// Name
		auto ref = globalRef1();

		// Parameters
		auto params = params1();
		auto paramTypes = map(params, [](Term a) { return a.ty(); });

		// Trailing tokens
		while (token != "{") {
			if (token == "\n" || token == eof) {
				throw error("expected '{'");
			}
			lex();
		}

		// Body
		expect("{");
		newline();
		vector<Inst> body;
		while (token != "}") {
			if (token != "\n") {
				body.push_back(inst1());
			}
			nextLine();
		}
		expect("}");

		return Func(rty, ref, params, body);
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
		string errorMsg = file + ":" + to_string(currentLine(text, pos)) + ": " + msg;

		// Return exception with the formatted message
		return runtime_error(errorMsg);
	}

	void expect(const string& s) {
		if (token == s) {
			lex();
			return;
		}
		throw error(quote(token) + ": expected " + quote(s));
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
		if (token == "zeroinitializer") {
			lex();
			return zeroVal(ty);
		}
		// END
		switch (token[0]) {
		case '%':
			return var1(ty);
		case '@':
			return globalRef(ty, globalRef1());
		}
		if (isDigit(token[0])) {
			if (isInt(ty)) {
				auto a = intConst(ty, cpp_int(token));
				lex();
				return a;
			}
			if (isFloat(ty)) {
				auto a = floatConst(ty, token);
				lex();
				return a;
			}
			throw error(quote(token) + ": unexpected number");
		}
		throw error(quote(token) + ": expected expression");
	}

	void fastMathFlags() {
		while (token == "fast" || token == "nnan" || token == "ninf" || token == "nsz") {
			lex();
		}
	}

	Ref globalRef1() {
		if (token[0] != '@') {
			throw error(quote(token) + ": expected global name");
		}
		return ref1();
	}

	void id() {
		if (text[pos] == '"') {
			lexQuote();
			return;
		}
		if (!isIdPart(text[pos])) {
			throw error("expected identifier");
		}
		while (isIdPart(text[pos])) {
			token += text[pos++];
		}
	}

	Inst inst1() {
		if (token.back() == ':') {
			return block(parseRef(token.substr(0, token.size() - 1)));
		}

		// SORT BLOCKS
		if (token == "br") {
			lex();
			if (token == "label") {
				lex();
				return jmp(label1());
			}
			auto cond = typeExpr();
			expect(",");
			auto yes = label1();
			expect(",");
			auto no = label1();
			return br(cond, yes, no);
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
			auto p = ptrExpr();
			return Inst(Store, a, p);
		}
		if (token == "switch") {
			lex();
			vector<Term> v;

			// Value
			v.push_back(typeExpr());
			expect(",");

			// Default
			v.push_back(label1());

			// Cases
			expect("[");
			newline();
			while (token != "]") {
				v.push_back(typeExpr());
				expect(",");
				v.push_back(label1());
				newline();
			}
			expect("]");

			return Inst(Switch, v);
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
			if (token == "phi") {
				lex();
				fastMathFlags();
				vector<Term> v;

				// lval
				auto ty = type();
				v.push_back(var(ty, lval));

				// Values
				do {
					expect("[");
					v.push_back(expr(ty));
					expect(",");
					v.push_back(label1());
					expect("]");
				} while (maybeComma());

				return Inst(Phi, v);
			}
			auto rval = rval1();
			return assign(var(rval.ty(), lval), rval);
		}
		// END

		throw error(quote(token) + ": expected inst");
	}

	size_t int1() {
		if (!all_of(token.begin(), token.end(), isDigit)) {
			throw error("expected integer");
		}
		auto n = stoull(token);
		lex();
		return n;
	}

	Term label1() {
		expect("label");
		return label(ref1());
	}

	void lex() {
		while (pos < text.size()) {
			if (containsAt(text, pos, "...")) {
				token = text.substr(pos, 3);
				pos += 3;
				return;
			}
			switch (text[pos]) {
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
				token = text.substr(pos++, 1);
				id();
				return;
			case ';':
				while (text[pos] != '\n') {
					pos++;
				}
				continue;
			case 'c':
				if (text[pos + 1] == '"') {
					token = text.substr(pos++, 1);
					lexQuote();
					return;
				}
				break;
			}
			if (isIdPart(text[pos])) {
				token.clear();
				id();
				maybeColon();
				return;
			}
			token = text.substr(pos++, 1);
			return;
		}
		token = eof;
	}

	void lexQuote() {
		ASSERT(text[pos] == '"');
		for (auto i = pos + 1; i < text.size(); i++) {
			if (text[i] == '"') {
				i++;
				token += text.substr(pos, i - pos);
				pos = i;
				return;
			}
		}
		throw error("unclosed quote");
	}

	void maybeColon() {
		if (text[pos] == ':') {
			token += text[pos++];
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

	Term param1() {
		auto ty = type();
		paramAttrs();
		return var1(ty);
	}

	void paramAttrs() {
		while (isLower(token[0])) {
			lex();
		}
	}

	vector<Term> params1() {
		expect("(");
		vector<Term> v;
		if (token != ")") {
			do {
				v.push_back(param1());
			} while (maybeComma());
		}
		expect(")");
		return v;
	}

	void parse() {
		if (token == "target") {
			target1();
			return;
		}
		if (token == "declare") {
			module->declares.push_back(declare());
			return;
		}
		if (token == "define") {
			module->defines.push_back(define());
			return;
		}
	}

	Term parseCall() {
		expect("call");
		auto rty = type();
		auto ref = globalRef1();
		auto args = args1();
		auto params = map(args, [](Term a) { return a.ty(); });
		auto fty = funcTy(rty, params);
		auto f = globalRef(fty, ref);
		return call(rty, f, args);
	}

	Type primaryType() {
		// SORT BLOCKS
		if (token == "<") {
			lex();
			auto len = int1();
			expect("x");
			auto element = type();
			expect(">");
			return vecTy(len, element);
		}
		if (token == "[") {
			lex();
			auto len = int1();
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

	Term ptrExpr() {
		expect("ptr");
		return expr(ptrTy());
	}

	Ref ref1() {
		auto r = parseRef(token);
		lex();
		return r;
	}

	Term rval1() {
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
			if (token == "oeq") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(FEq, a, b);
			}
			if (token == "ogt") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(FLt, b, a);
			}
			if (token == "oge") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(FLe, b, a);
			}
			if (token == "olt") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(FLt, a, b);
			}
			if (token == "ole") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(FLe, a, b);
			}
			if (token == "ugt") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return not1(cmp(FLe, a, b));
			}
			if (token == "uge") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return not1(cmp(FLt, a, b));
			}
			if (token == "ult") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return not1(cmp(FLe, b, a));
			}
			if (token == "ule") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return not1(cmp(FLt, b, a));
			}
			if (token == "une") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return not1(cmp(FEq, b, a));
			}
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
		if (token == "getelementptr") {
			lex();
			if (token == "inbounds") {
				lex();
			}
			auto ty = type();
			expect(",");
			auto p = ptrExpr();
			expect(",");
			vector<Term> idxs;
			do {
				idxs.push_back(typeExpr());
			} while (maybeComma());
			return getElementPtr(ty, p, idxs);
		}
		if (token == "icmp") {
			lex();
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
			if (token == "ugt") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(ULt, b, a);
			}
			if (token == "uge") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(ULe, b, a);
			}
			if (token == "ult") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(ULt, a, b);
			}
			if (token == "ule") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(ULe, a, b);
			}
			if (token == "sgt") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(SLt, b, a);
			}
			if (token == "sge") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(SLe, b, a);
			}
			if (token == "slt") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(SLt, a, b);
			}
			if (token == "sle") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(SLe, a, b);
			}
			throw error(quote(token) + ": expected condition");
		}
		if (token == "load") {
			lex();
			auto ty = type();
			expect(",");
			auto a = ptrExpr();
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

	void setConsistent(string& var, const string& val, const char* name) {
		ASSERT(val.size());
		if (var.size() && var != val) {
			throw error(string("inconsistent ") + name);
		}
		var = val;
	}

	void target1() {
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

	Type type() {
		auto ty = primaryType();
		return ty;
	}

	Term typeExpr() {
		return expr(type());
	}

	Term var1(Type ty) {
		if (token[0] != '%') {
			throw error("expected variable name");
		}
		return var(ty, ref1());
	}

public:
	Module* module = new Module;

	Parser(const string& file, const string& text, Target& target): file(file), text(text), target(target) {
		if (!endsWith(text, '\n')) {
			this->text += '\n';
		}
		lex();
		while (token != eof) {
			parse();
			nextLine();
		}
	}
};
