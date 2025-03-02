string readFile(const string& filename);

// The signedness of plain char is implementation-defined, typically signed
// and the ctype.h functions have undefined behavior on signed input
// so, unless we want to count on never forgetting to cast to unsigned at every call site,
// we need to provide our own
bool isSpace(int c);
bool isDigit(int c);
bool isLower(int c);
bool isUpper(int c);
bool isAlpha(int c);
bool isAlnum(int c);
bool isXDigit(int c);

// Is the input character a valid part of an LLVM identifier?
// This includes more punctuation than most programming languages
bool isIdPart(int c);

bool containsAt(const string& haystack, size_t position, const string& needle);
bool endsWith(const string& s, int c);

// Parse hexadecimal digits starting at a given position, updating pos accordingly
// Hexadecimal digits are classified by the function isXDigit
// Stops when it reaches the end of the string, or a character that is not a hexadecimal digit, or it has parsed maxLen digits
// At least one hexadecimal digit must be present, or an exception is thrown
unsigned parseHex(const string& s, size_t& pos, int maxLen = 8);

// Remove the leading sigil from an LLVM identifier or string, if there is one
string removeSigil(const string& s);

// Unwrap an LLVM identifier or string
// Remove the leading sigil if any
// If there are quotes, remove them, and evaluate escape sequences
// Check for validity, and throw runtime_error if the string is not valid
// The LLVM language manual doesn't say exactly what escape sequences are valid
// Testing what the LLVM parser actually accepts, it seems to be just \ or two hex digits
// Otherwise, the first \ is just treated as an ordinary character
string unwrap(string s);

// Parse an LLVM identifier or string to a reference containing index number or string as appropriate
// after removing the leading sigil if there is one
// Correctly distinguishes between %9 and %"9"
Ref parseRef(string s);

// Quote a string, particularly a token, for echoing to the user
// Newline is translated to something readable
string quote(const string& s);

// Count newlines before current position to get line number
size_t currentLine(const string& input, size_t pos);

// Parser for LLVM `.ll` format
class Parser {
	const string file;
	string text;
	size_t pos = 0;
	string tok;

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
		if (tok == "noundef") {
			lex();
		}
	}

	vector<Term> args1() {
		expect("(");
		vector<Term> v;
		if (tok != ")") {
			do {
				v.push_back(arg1());
			} while (maybeComma());
		}
		expect(")");
		return v;
	}

	Term call1() {
		expect("call");
		auto rty = type();
		auto ref = globalRef1();
		auto args = args1();
		auto params = map(args, [](Term a) { return a.ty(); });
		auto fty = fnTy(rty, params);
		auto f = globalRef(fty, ref);
		return call(rty, f, args);
	}

	Fn declare() {
		/*
		declare [linkage] [visibility] [DLLStorageClass]
		[cconv] [ret attrs]
		<ResultType> @<FunctionName> ([argument list])
		[(unnamed_addr|local_unnamed_addr)] [align N] [gc]
		[prefix Constant] [prologue Constant]
		*/
		expect("declare");
		linkage();

		// The syntax in the documentation says declarations don't have a preemption specifier
		// but Clang outputs declarations with dso_local
		preemption();

		// Return type
		auto rty = type();

		// Name
		auto ref = globalRef1();

		// Parameters
		auto params = params1();
		auto paramTypes = map(params, [](Term a) { return a.ty(); });

		return Fn(rty, ref, params);
	}

	Fn define() {
		/*
		define [linkage] [PreemptionSpecifier] [visibility] [DLLStorageClass]
		[cconv] [ret attrs]
		<ResultType> @<FunctionName> ([argument list])
		[(unnamed_addr|local_unnamed_addr)] [AddrSpace] [fn Attrs]
		[section "name"] [partition "name"] [comdat [($name)]] [align N]
		[gc] [prefix Constant] [prologue Constant] [personality Constant]
		(!name !N)* { ... }
		*/
		expect("define");
		linkage();
		preemption();

		// Return type
		auto rty = type();

		// Name
		auto ref = globalRef1();

		// Parameters
		auto params = params1();
		auto paramTypes = map(params, [](Term a) { return a.ty(); });

		// Trailing tokens
		while (tok != "{") {
			if (tok == "\n" || tok == eof) {
				throw error("expected '{'");
			}
			lex();
		}

		// Body
		expect("{");
		newline();
		vector<Inst> body;
		while (tok != "}") {
			if (tok != "\n") {
				body.push_back(inst1());
			}
			nextLine();
		}
		expect("}");

		return Fn(rty, ref, params, body);
	}

	// This function takes:
	// The name of the input file, stored
	// The current line number, calculated from the count of newline characters before pos
	// The error message, supplied as a parameter
	// and returns an exception with a composite error message suitable for printing
	runtime_error error(const string& msg) const {
		// Build error message with format "file:line: error message"
		string errorMsg = file + ":" + std::to_string(currentLine(text, pos)) + ": " + msg;

		// Return exception with the formatted message
		return runtime_error(errorMsg);
	}

	void expect(const string& s) {
		if (tok == s) {
			lex();
			return;
		}
		throw error(quote(tok) + ": expected " + quote(s));
	}

	Term expr(Type ty) {
		// SORT BLOCKS
		if (tok == "false") {
			if (ty != boolTy()) {
				throw error("type mismatch");
			}
			lex();
			return falseConst;
		}
		if (tok == "null") {
			if (ty != ptrTy()) {
				throw error("type mismatch");
			}
			lex();
			return nullPtrConst;
		}
		if (tok == "true") {
			if (ty != boolTy()) {
				throw error("type mismatch");
			}
			lex();
			return trueConst;
		}
		if (tok == "zeroinitializer") {
			lex();
			return zeroVal(ty);
		}
		// END
		switch (tok[0]) {
		case '%':
			return var1(ty);
		case '@':
			return globalRef(ty, globalRef1());
		case 'c':
			if (tok.size() > 1 && tok[1] == '"') {
				auto s = unwrap(tok);
				lex();
				return arrayBytes((unsigned char*)s.data(), s.size());
			}
			break;
		}
		if (isDigit(tok[0]) || (tok[0] == '-' && tok.size() > 1 && isDigit(tok[1]))) {
			if (isInt(ty)) {
				auto a = intConst(ty, cpp_int(tok));
				lex();
				return a;
			}
			if (isFloat(ty)) {
				auto a = floatConst(ty, tok);
				lex();
				return a;
			}
			throw error(quote(tok) + ": unexpected number");
		}
		throw error(quote(tok) + ": expected expression");
	}

	void fastMathFlags() {
		while (tok == "fast" || tok == "nnan" || tok == "ninf" || tok == "nsz") {
			lex();
		}
	}

	Global global() {
		// https://llvm.org/docs/LangRef.html#global-variables
		/*
		@<GlobalVarName> =
		[Linkage] [PreemptionSpecifier] [Visibility]
		[DLLStorageClass] [ThreadLocal]
		[(unnamed_addr|local_unnamed_addr)] [AddrSpace]
		[ExternallyInitialized]
		<global | constant> <Type> [<InitializerConstant>]
		[, section "name"] [, partition "name"]
		[, comdat [($name)]] [, align <Alignment>]
		[, code_model "model"]
		[, no_sanitize_address] [, no_sanitize_hwaddress]
		[, sanitize_address_dyninit] [, sanitize_memtag]
		(, !name !N)*
		*/
		auto ref = globalRef1();
		expect("=");
		linkage();
		preemption();

		if (tok == "unnamed_addr" | tok == "local_unnamed_addr") {
			lex();
		}

		if (tok == "global") {
			lex();
		} else if (tok == "constant") {
			lex();
		} else {
			throw error(quote(tok) + ": expected 'global' or 'constant'");
		}

		auto ty = type();
		auto val = expr(ty);
		return Global(ty, ref, val);
	}

	Ref globalRef1() {
		if (tok[0] != '@') {
			throw error(quote(tok) + ": expected global name");
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
			tok += text[pos++];
		}
	}

	Inst inst1() {
		if (tok.back() == ':') {
			return block(parseRef(tok.substr(0, tok.size() - 1)));
		}

		// SORT BLOCKS
		if (tok == "br") {
			lex();
			if (tok == "label") {
				return jmp(label1());
			}
			auto cond = typeExpr();
			expect(",");
			auto yes = label1();
			expect(",");
			auto no = label1();
			return br(cond, yes, no);
		}
		if (tok == "call") {
			return Inst(Drop, call1());
		}
		if (tok == "ret") {
			lex();
			if (tok == "void") {
				return ret();
			}
			return ret(typeExpr());
		}
		if (tok == "store") {
			lex();
			auto a = typeExpr();
			expect(",");
			auto p = ptrExpr();
			return store(a, p);
		}
		if (tok == "switch") {
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
			while (tok != "]") {
				v.push_back(typeExpr());
				expect(",");
				v.push_back(label1());
				newline();
			}
			expect("]");

			return Inst(Switch, v);
		}
		if (tok == "unreachable") {
			return unreachable();
		}
		if (tok[0] == '%') {
			auto lval = parseRef(tok);
			lex();
			expect("=");
			if (tok == "alloca") {
				lex();
				auto ty = type();
				auto n = intConst(1);
				while (tok == ",") {
					lex();
					if (tok == "align") {
						lex();
						int1();
						continue;
					}
					if (tok == "addrspace") {
						throw error("multiple address spaces not supported");
					}
					n = typeExpr();
				}
				return alloca(var(ptrTy(), lval), ty, n);
			}
			if (tok == "phi") {
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
					v.push_back(label(ref1()));
					expect("]");
				} while (maybeComma());

				return Inst(Phi, v);
			}
			auto rval = rval1();
			return assign(var(rval.ty(), lval), rval);
		}
		// END

		throw error(quote(tok) + ": expected inst");
	}

	size_t int1() {
		if (!std::all_of(tok.begin(), tok.end(), isDigit)) {
			throw error("expected integer");
		}
		auto n = stoull(tok);
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
				tok = text.substr(pos, 3);
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
				tok.clear();
				lexQuote();
				maybeColon();
				return;
			case '$':
			case '%':
			case '@':
				tok = text.substr(pos++, 1);
				id();
				return;
			case ';':
				while (text[pos] != '\n') {
					pos++;
				}
				continue;
			case 'c':
				if (text[pos + 1] == '"') {
					tok = text.substr(pos++, 1);
					lexQuote();
					return;
				}
				break;
			}
			if (isIdPart(text[pos])) {
				tok.clear();
				id();
				maybeColon();
				return;
			}
			tok = text.substr(pos++, 1);
			return;
		}
		tok = eof;
	}

	void lexQuote() {
		ASSERT(text[pos] == '"');
		for (auto i = pos + 1; i < text.size(); i++) {
			if (text[i] == '"') {
				i++;
				tok += text.substr(pos, i - pos);
				pos = i;
				return;
			}
		}
		throw error("unclosed quote");
	}

	void linkage() {
		if (tok == "private") {
			lex();
			return;
		}
		if (tok == "internal") {
			lex();
			return;
		}
		if (tok == "available_externally") {
			lex();
			return;
		}
		if (tok == "linkonce") {
			lex();
			return;
		}
		if (tok == "weak") {
			lex();
			return;
		}
		if (tok == "common") {
			lex();
			return;
		}
		if (tok == "appending") {
			lex();
			return;
		}
		if (tok == "extern_weak") {
			lex();
			return;
		}
		if (tok == "linkonce_odr" || tok == "weak_odr") {
			lex();
			return;
		}
		if (tok == "external") {
			lex();
			return;
		}
	}

	void maybeColon() {
		if (text[pos] == ':') {
			tok += text[pos++];
		}
	}

	bool maybeComma() {
		if (tok == ",") {
			lex();
			return true;
		}
		return false;
	}

	void newline() {
		if (tok == "\n") {
			lex();
			return;
		}
		throw error("expected newline");
	}

	void nextLine() {
		while (tok != "\n") {
			if (tok == eof) {
				stackTrace();
				throw error("unexpected end of file");
			}
			lex();
		}
		lex();
	}

	void noWrap() {
		if (tok == "nuw") {
			lex();
		}
		if (tok == "nsw") {
			lex();
		}
	}

	Term param1() {
		if (tok == "...") {
			lex();
			return Term(Array);
		}

		// <type> [parameter Attrs] [name]
		auto ty = type();
		paramAttrs();
		if (tok[0] == '%') {
			return var1(ty);
		}
		return none(ty);
	}

	void paramAttrs() {
		// https://llvm.org/docs/LangRef.html#paramattrs
		while (isLower(tok[0])) {
			lex();
		}
	}

	vector<Term> params1() {
		expect("(");
		vector<Term> v;
		if (tok != ")") {
			do {
				v.push_back(param1());
			} while (maybeComma());
		}
		expect(")");
		return v;
	}

	void parse() {
		if (!endsWith(text, '\n')) {
			text += '\n';
		}
		lex();
		while (tok != eof) {
			parse1();
			nextLine();
		}
	}

	void parse1() {
		if (tok == "target") {
			target1();
			return;
		}
		if (tok == "declare") {
			module->decls.push_back(declare());
			return;
		}
		if (tok == "define") {
			module->defs.push_back(define());
			return;
		}
		if (tok[0] == '$') {
			auto ref = unwrap(tok);
			lex();
			expect("=");
			expect("comdat");
			expect("any");
			module->comdats.push_back(ref);
			return;
		}
		if (tok[0] == '@') {
			module->globals.push_back(global());
			return;
		}
	}

	void preemption() {
		if (tok == "dso_local") {
			lex();
			return;
		}
		if (tok == "dso_preemptable") {
			lex();
			return;
		}
		// If a preemption specifier isn’t given explicitly, then a symbol is assumed to be dso_preemptable.
	}

	Type primaryType() {
		// SORT BLOCKS
		if (tok == "<") {
			lex();
			auto len = int1();
			expect("x");
			auto element = type();
			expect(">");
			return vecTy(len, element);
		}
		if (tok == "[") {
			lex();
			auto len = int1();
			expect("x");
			auto element = type();
			expect("]");
			return arrayTy(len, element);
		}
		if (tok == "double") {
			lex();
			return doubleTy();
		}
		if (tok == "float") {
			lex();
			return floatTy();
		}
		if (tok == "ptr") {
			lex();
			return ptrTy();
		}
		if (tok == "void") {
			lex();
			return voidTy();
		}
		if (tok[0] == 'i') {
			auto len = stoull(tok.substr(1));
			lex();
			return intTy(len);
		}
		// END

		throw error(quote(tok) + ": expected type");
	}

	Term ptrExpr() {
		expect("ptr");
		return expr(ptrTy());
	}

	Ref ref1() {
		auto r = parseRef(tok);
		lex();
		return r;
	}

	Term rval1() {
		// SORT BLOCKS
		if (tok == "add") {
			lex();
			noWrap();
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(Add, ty, a, b);
		}
		if (tok == "and") {
			lex();
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(And, ty, a, b);
		}
		if (tok == "ashr") {
			lex();
			if (tok == "exact") {
				lex();
			}
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(AShr, ty, a, b);
		}
		if (tok == "call") {
			return call1();
		}
		if (tok == "fadd") {
			lex();
			fastMathFlags();
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(FAdd, ty, a, b);
		}
		if (tok == "fcmp") {
			lex();
			fastMathFlags();
			if (tok == "oeq") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(FEq, a, b);
			}
			if (tok == "ogt") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(FLt, b, a);
			}
			if (tok == "oge") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(FLe, b, a);
			}
			if (tok == "olt") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(FLt, a, b);
			}
			if (tok == "ole") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(FLe, a, b);
			}
			if (tok == "ugt") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return not1(cmp(FLe, a, b));
			}
			if (tok == "uge") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return not1(cmp(FLt, a, b));
			}
			if (tok == "ult") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return not1(cmp(FLe, b, a));
			}
			if (tok == "ule") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return not1(cmp(FLt, b, a));
			}
			if (tok == "une") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return not1(cmp(FEq, b, a));
			}
			throw error(quote(tok) + ": expected condition");
		}
		if (tok == "fdiv") {
			lex();
			fastMathFlags();
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(FDiv, ty, a, b);
		}
		if (tok == "fmul") {
			lex();
			fastMathFlags();
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(FMul, ty, a, b);
		}
		if (tok == "fneg") {
			lex();
			fastMathFlags();
			auto ty = type();
			auto a = expr(ty);
			return Term(FNeg, ty, a);
		}
		if (tok == "frem") {
			lex();
			fastMathFlags();
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(FRem, ty, a, b);
		}
		if (tok == "fsub") {
			lex();
			fastMathFlags();
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(FSub, ty, a, b);
		}
		if (tok == "getelementptr") {
			lex();
			if (tok == "inbounds") {
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
		if (tok == "icmp") {
			lex();
			if (tok == "eq") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(Eq, a, b);
			}
			if (tok == "ne") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return not1(cmp(Eq, b, a));
			}
			if (tok == "ugt") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(ULt, b, a);
			}
			if (tok == "uge") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(ULe, b, a);
			}
			if (tok == "ult") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(ULt, a, b);
			}
			if (tok == "ule") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(ULe, a, b);
			}
			if (tok == "sgt") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(SLt, b, a);
			}
			if (tok == "sge") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(SLe, b, a);
			}
			if (tok == "slt") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(SLt, a, b);
			}
			if (tok == "sle") {
				lex();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(SLe, a, b);
			}
			throw error(quote(tok) + ": expected condition");
		}
		if (tok == "load") {
			lex();
			auto ty = type();
			expect(",");
			auto a = ptrExpr();
			return Term(Load, ty, a);
		}
		if (tok == "lshr") {
			lex();
			if (tok == "exact") {
				lex();
			}
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(LShr, ty, a, b);
		}
		if (tok == "mul") {
			lex();
			noWrap();
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(Mul, ty, a, b);
		}
		if (tok == "or") {
			lex();
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(Or, ty, a, b);
		}
		if (tok == "sdiv") {
			lex();
			if (tok == "exact") {
				lex();
			}
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(SDiv, ty, a, b);
		}
		if (tok == "sext" || tok == "fptosi" || tok == "sitofp") {
			lex();
			auto a = typeExpr();
			expect("to");
			auto ty = type();
			return Term(SCast, ty, a);
		}
		if (tok == "shl") {
			lex();
			noWrap();
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(Shl, ty, a, b);
		}
		if (tok == "srem") {
			lex();
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(SRem, ty, a, b);
		}
		if (tok == "sub") {
			lex();
			noWrap();
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(Sub, ty, a, b);
		}
		if (tok == "trunc" || tok == "zext" || tok == "fptrunc" || tok == "fpext" || tok == "fptoui" || tok == "uitofp" ||
			tok == "ptrtoint" || tok == "inttoptr" || tok == "bitcast") {
			lex();
			auto a = typeExpr();
			expect("to");
			auto ty = type();
			return Term(Cast, ty, a);
		}
		if (tok == "udiv") {
			lex();
			if (tok == "exact") {
				lex();
			}
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(UDiv, ty, a, b);
		}
		if (tok == "urem") {
			lex();
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(URem, ty, a, b);
		}
		if (tok == "xor") {
			lex();
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(Xor, ty, a, b);
		}
		// END

		throw error(quote(tok) + ": expected rval");
	}

	void target1() {
		expect("target");
		if (tok == "datalayout") {
			lex();
			expect("=");
			if (tok[0] != '"') {
				throw error("expected string");
			}
			module->datalayout = unwrap(tok);
			return;
		}
		if (tok == "triple") {
			lex();
			expect("=");
			if (tok[0] != '"') {
				throw error("expected string");
			}
			module->triple = unwrap(tok);
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
		if (tok[0] != '%') {
			throw error("expected variable name");
		}
		return var(ty, ref1());
	}

public:
	Module* module = new Module;

	Parser(const string& text): file("nameless.ll"), text(text) {
		parse();
	}

	Parser(const string& file, const string& text): file(file), text(text) {
		parse();
	}
};
