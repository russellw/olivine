#include "all.h"

bool isSpace(int c) {
	return c <= ' ' && c;
}

bool isDigit(int c) {
	return '0' <= c && c <= '9';
}

bool isLower(int c) {
	return 'a' <= c && c <= 'z';
}

bool isUpper(int c) {
	return 'A' <= c && c <= 'Z';
}

bool isAlpha(int c) {
	return isLower(c) || isUpper(c);
}

bool isAlnum(int c) {
	return isAlpha(c) || isDigit(c);
}

bool isXDigit(int c) {
	return isDigit(c) || ('a' <= c && c <= 'f') || ('A' <= c && c <= 'F');
}

bool isIdPart(int c) {
	switch (c) {
	case '$':
	case '-':
	case '.':
	case '_':
		return true;
	}
	return isAlnum(c);
}

bool containsAt(string haystack, size_t position, string needle) {
	// Position beyond string length is invalid
	if (position > haystack.length()) {
		return false;
	}

	// For empty needle, any valid position (including end of string) is a match
	if (needle.empty()) {
		return true;
	}

	// Check if there's enough room for needle
	if (position + needle.length() > haystack.length()) {
		return false;
	}

	return haystack.substr(position, needle.length()) == needle;
}

bool endsWith(string s, int c) {
	return s.size() && s.back() == c;
}

unsigned parseHex(string s, size_t& pos, int maxLen) {
	// Check if we're already at the end of the string
	if (pos >= s.length()) {
		throw runtime_error("No hexadecimal digits found: end of string");
	}

	unsigned result = 0;
	int digitsProcessed = 0;
	bool foundDigit = false;

	while (pos < s.length() && digitsProcessed < maxLen) {
		char c = s[pos];

		// Convert the character to its numeric value
		unsigned digit;
		if (c >= '0' && c <= '9') {
			digit = c - '0';
		} else if (c >= 'a' && c <= 'f') {
			digit = c - 'a' + 10;
		} else if (c >= 'A' && c <= 'F') {
			digit = c - 'A' + 10;
		} else {
			// Not a hex digit, stop parsing
			break;
		}

		// Update the result and tracking variables
		result = (result << 4) | digit;
		foundDigit = true;
		digitsProcessed++;
		pos++;
	}

	// Check if we found at least one digit
	if (!foundDigit) {
		throw runtime_error("No hexadecimal digits found");
	}

	return result;
}

string removeSigil(string s) {
	ASSERT(s.size());
	switch (s[0]) {
	case '$':
	case '%':
	case '@':
		return s.substr(1);
	case 'c':
		if (1 < s.size() && s[1] == '"') {
			return s.substr(1);
		}
		break;
	}
	return s;
}

string unwrap(string s) {
	s = removeSigil(s);
	ASSERT(s.size());

	// Unquoted index number or identifier
	if (s[0] != '"') {
		for (auto c : s) {
			ASSERT(isIdPart(c));
		}
		return s;
	}

	// Quoted identifier or string
	size_t pos = 1;
	string r;
	while (s[pos] != '"') {
		ASSERT(pos < s.size());
		int c = s[pos++];
		if (c == '\\') {
			ASSERT(pos < s.size());
			switch (s[pos]) {
			case '\\':
				pos++;
				break;
			default:
				if (isXDigit(s[pos])) {
					c = parseHex(s, pos, 2);
				}
				break;
			}
		}
		r += c;
	}
	ASSERT(pos == s.size() - 1);
	return r;
}

Ref parseRef(string s) {
	s = removeSigil(s);
	ASSERT(s.size());

	// Index number
	if (isDigit(s[0])) {
		for (auto c : s) {
			ASSERT(isDigit(c));
		}
		return Ref(stoull(s));
	}

	// Identifier or string
	return Ref(unwrap(s));
}

// Quote a string, particularly a token, for echoing to the user
// Newline is translated to something readable
static string quote(string s) {
	if (s == "\n") {
		return "newline";
	}
	return '\'' + s + '\'';
}

struct Tok {
	size_t line;
	string s;

	Tok(size_t line, string s): line(line), s(s) {
	}

	bool operator==(string t) const {
		return s == t;
	}

	bool operator!=(string t) const {
		return s != t;
	}
};

class Tokenizer {
	string file;
	string text;
	size_t pos = 0;
	size_t line = 1;
	string tok;
	queue<Tok>& toks;

	runtime_error error(string msg) const {
		return runtime_error(file + ':' + to_string(line) + ": " + msg);
	}

	void quote1() {
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

	void id() {
		if (text[pos] == '"') {
			quote1();
			return;
		}
		if (!isIdPart(text[pos])) {
			throw error("expected identifier");
		}
		while (isIdPart(text[pos])) {
			tok += text[pos++];
		}
	}

	void maybeColon() {
		if (text[pos] == ':') {
			tok += text[pos++];
		}
	}

	void push() {
		toks.push(Tok(line, tok));
	}

public:
	Tokenizer(string file, string text0, queue<Tok>& toks): file(file), text(text0), toks(toks) {
		if (!endsWith(text, '\n')) {
			text += '\n';
		}
		while (pos < text.size()) {
			if (containsAt(text, pos, "...")) {
				tok = text.substr(pos, 3);
				pos += 3;
				push();
				continue;
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
				quote1();
				maybeColon();
				push();
				continue;
			case '$':
			case '%':
			case '@':
				tok = text.substr(pos++, 1);
				id();
				push();
				continue;
			case ';':
				while (text[pos] != '\n') {
					pos++;
				}
				continue;
			case '\n':
				tok = text.substr(pos++, 1);
				push();
				line++;
				continue;
			case 'c':
				if (text[pos + 1] == '"') {
					tok = text.substr(pos++, 1);
					quote1();
					push();
					continue;
				}
				break;
			}
			if (isIdPart(text[pos])) {
				tok.clear();
				id();
				maybeColon();
				push();
				continue;
			}
			tok = text.substr(pos++, 1);
			push();
		}
	}
};

// End is indicated by a token that cannot correspond to any actual token
// but is still nonempty, so parsing code can safely check the first character of current token
const string sentinel = " ";

class Parser {
	string file;
	queue<Tok> toks = Tok(0, sentinel);

	// SORT FUNCTIONS

	Term arg1() {
		auto ty = type();
		argAttrs();
		return expr(ty);
	}

	void argAttrs() {
		if (*toks == "noundef") {
			toks.pop();
		}
	}

	vector<Term> args1() {
		expect("(");
		vector<Term> v;
		if (*toks != ")") {
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
		while (*toks != "{") {
			if (*toks == "\n" || *toks == sentinel) {
				throw error("expected '{'");
			}
			toks.pop();
		}

		// Body
		expect("{");
		newline();
		vector<Inst> body;
		while (*toks != "}") {
			if (*toks != "\n") {
				body.push_back(inst1());
			}
			nextLine();
		}
		expect("}");

		return Fn(rty, ref, params, body);
	}

	runtime_error error(string msg) {
		// File
		auto s = file + ':';

		// Line
		auto tok = *toks;
		if (tok.line) {
			s += to_string(tok.line);
		} else {
			s += "EOF";
		}
		s += ": ";

		// Current token
		s += quote(tok.s) + ": ";

		// Specific message
		s += msg;

		// Return exception object instead of throwing it
		// so the compiler can recognize control flow at the call site
		return runtime_error(s);
	}

	void expect(string s) {
		if (*toks == s) {
			toks.pop();
			return;
		}
		throw error("expected " + quote(s));
	}

	Term expr(Type ty) {
		// SORT BLOCKS
		if (*toks == "false") {
			if (ty != boolTy()) {
				throw error("type mismatch");
			}
			toks.pop();
			return falseConst;
		}
		if (*toks == "null") {
			if (ty != ptrTy()) {
				throw error("type mismatch");
			}
			toks.pop();
			return nullPtrConst;
		}
		if (*toks == "true") {
			if (ty != boolTy()) {
				throw error("type mismatch");
			}
			toks.pop();
			return trueConst;
		}
		if (*toks == "zeroinitializer") {
			toks.pop();
			return zeroVal(ty);
		}
		// END
		auto tok = toks->s;
		switch (tok[0]) {
		case '%':
			return var1(ty);
		case '@':
			return globalRef(ty, globalRef1());
		case 'c':
			if (tok.size() > 1 && tok[1] == '"') {
				auto s = unwrap(tok);
				toks.pop();
				return arrayBytes((unsigned char*)s.data(), s.size());
			}
			break;
		}
		if (isDigit(tok[0]) || (tok[0] == '-' && tok.size() > 1 && isDigit(tok[1]))) {
			if (isInt(ty)) {
				auto a = intConst(ty, cpp_int(tok));
				toks.pop();
				return a;
			}
			if (isFloat(ty)) {
				auto a = floatConst(ty, tok);
				toks.pop();
				return a;
			}
			throw error("unexpected number");
		}
		throw error("expected expression");
	}

	void fastMathFlags() {
		while (*toks == "fast" || *toks == "nnan" || *toks == "ninf" || *toks == "nsz") {
			toks.pop();
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

		if (*toks == "unnamed_addr" | *toks == "local_unnamed_addr") {
			toks.pop();
		}

		if (*toks == "global") {
			toks.pop();
		} else if (*toks == "constant") {
			toks.pop();
		} else {
			throw error("expected 'global' or 'constant'");
		}

		auto ty = type();
		auto val = expr(ty);
		return Global(ty, ref, val);
	}

	Ref globalRef1() {
		if (toks->s[0] != '@') {
			throw error("expected global name");
		}
		return ref1();
	}

	Inst inst1() {
		if (toks->s.back() == ':') {
			auto tok = toks->s;
			return block(parseRef(tok.substr(0, tok.size() - 1)));
		}

		// SORT BLOCKS
		if (*toks == "br") {
			toks.pop();
			if (*toks == "label") {
				return jmp(label1());
			}
			auto cond = typeExpr();
			expect(",");
			auto yes = label1();
			expect(",");
			auto no = label1();
			return br(cond, yes, no);
		}
		if (*toks == "call") {
			return Inst(Drop, call1());
		}
		if (*toks == "ret") {
			toks.pop();
			if (*toks == "void") {
				return ret();
			}
			return ret(typeExpr());
		}
		if (*toks == "store") {
			toks.pop();
			auto a = typeExpr();
			expect(",");
			auto p = ptrExpr();
			return store(a, p);
		}
		if (*toks == "switch") {
			toks.pop();
			vector<Term> v;

			// Value
			v.push_back(typeExpr());
			expect(",");

			// Default
			v.push_back(label1());

			// Cases
			expect("[");
			newline();
			while (*toks != "]") {
				v.push_back(typeExpr());
				expect(",");
				v.push_back(label1());
				newline();
			}
			expect("]");

			return Inst(Switch, v);
		}
		if (*toks == "unreachable") {
			return unreachable();
		}
		if (toks->s[0] == '%') {
			auto lval = parseRef(toks->s);
			toks.pop();
			expect("=");
			if (*toks == "alloca") {
				toks.pop();
				auto ty = type();
				auto n = intConst(1);
				while (*toks == ",") {
					toks.pop();
					if (*toks == "align") {
						toks.pop();
						int1();
						continue;
					}
					if (*toks == "addrspace") {
						throw error("multiple address spaces not supported");
					}
					n = typeExpr();
				}
				return alloca(var(ptrTy(), lval), ty, n);
			}
			if (*toks == "phi") {
				toks.pop();
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

		throw error("expected inst");
	}

	size_t int1() {
		auto tok = toks->s;
		if (!std::all_of(tok.begin(), tok.end(), isDigit)) {
			throw error("expected integer");
		}
		auto n = stoull(tok);
		toks.pop();
		return n;
	}

	Term label1() {
		expect("label");
		return label(ref1());
	}

	void linkage() {
		if (*toks == "private") {
			toks.pop();
			return;
		}
		if (*toks == "internal") {
			toks.pop();
			return;
		}
		if (*toks == "available_externally") {
			toks.pop();
			return;
		}
		if (*toks == "linkonce") {
			toks.pop();
			return;
		}
		if (*toks == "weak") {
			toks.pop();
			return;
		}
		if (*toks == "common") {
			toks.pop();
			return;
		}
		if (*toks == "appending") {
			toks.pop();
			return;
		}
		if (*toks == "extern_weak") {
			toks.pop();
			return;
		}
		if (*toks == "linkonce_odr" || *toks == "weak_odr") {
			toks.pop();
			return;
		}
		if (*toks == "external") {
			toks.pop();
			return;
		}
	}

	bool maybeComma() {
		if (*toks == ",") {
			toks.pop();
			return true;
		}
		return false;
	}

	void newline() {
		if (*toks == "\n") {
			toks.pop();
			return;
		}
		throw error("expected newline");
	}

	void nextLine() {
		while (*toks != "\n") {
			if (*toks == sentinel) {
				stackTrace();
				throw error("unexpected end of file");
			}
			toks.pop();
		}
		toks.pop();
	}

	void noWrap() {
		if (*toks == "nuw") {
			toks.pop();
		}
		if (*toks == "nsw") {
			toks.pop();
		}
	}

	Term param1() {
		if (*toks == "...") {
			toks.pop();
			return Term(Array);
		}

		// <type> [parameter Attrs] [name]
		auto ty = type();
		paramAttrs();
		if (toks->s[0] == '%') {
			return var1(ty);
		}
		return none(ty);
	}

	void paramAttrs() {
		// https://llvm.org/docs/LangRef.html#paramattrs
		while (isLower(toks->s[0])) {
			toks.pop();
		}
	}

	vector<Term> params1() {
		expect("(");
		vector<Term> v;
		if (*toks != ")") {
			do {
				v.push_back(param1());
			} while (maybeComma());
		}
		expect(")");
		return v;
	}

	void parse1() {
		if (*toks == "target") {
			target1();
			return;
		}
		if (*toks == "declare") {
			module->decls.push_back(declare());
			return;
		}
		if (*toks == "define") {
			module->defs.push_back(define());
			return;
		}
		if (toks->s[0] == '$') {
			auto ref = unwrap(toks->s);
			toks.pop();
			expect("=");
			expect("comdat");
			expect("any");
			module->comdats.push_back(ref);
			return;
		}
		if (toks->s[0] == '@') {
			module->globals.push_back(global());
			return;
		}
	}

	void preemption() {
		if (*toks == "dso_local") {
			toks.pop();
			return;
		}
		if (*toks == "dso_preemptable") {
			toks.pop();
			return;
		}
		// If a preemption specifier isn’t given explicitly, then a symbol is assumed to be dso_preemptable.
	}

	Type primaryType() {
		// SORT BLOCKS
		if (*toks == "<") {
			toks.pop();
			auto len = int1();
			expect("x");
			auto element = type();
			expect(">");
			return vecTy(len, element);
		}
		if (*toks == "[") {
			toks.pop();
			auto len = int1();
			expect("x");
			auto element = type();
			expect("]");
			return arrayTy(len, element);
		}
		if (*toks == "double") {
			toks.pop();
			return doubleTy();
		}
		if (*toks == "float") {
			toks.pop();
			return floatTy();
		}
		if (*toks == "ptr") {
			toks.pop();
			return ptrTy();
		}
		if (*toks == "void") {
			toks.pop();
			return voidTy();
		}
		if (toks->s[0] == 'i') {
			auto len = stoull(toks->s.substr(1));
			toks.pop();
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
		auto r = parseRef(toks->s);
		toks.pop();
		return r;
	}

	Term rval1() {
		// SORT BLOCKS
		if (*toks == "add") {
			toks.pop();
			noWrap();
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(Add, ty, a, b);
		}
		if (*toks == "and") {
			toks.pop();
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(And, ty, a, b);
		}
		if (*toks == "ashr") {
			toks.pop();
			if (*toks == "exact") {
				toks.pop();
			}
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(AShr, ty, a, b);
		}
		if (*toks == "call") {
			return call1();
		}
		if (*toks == "fadd") {
			toks.pop();
			fastMathFlags();
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(FAdd, ty, a, b);
		}
		if (*toks == "fcmp") {
			toks.pop();
			fastMathFlags();
			if (*toks == "oeq") {
				toks.pop();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(FEq, a, b);
			}
			if (*toks == "ogt") {
				toks.pop();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(FLt, b, a);
			}
			if (*toks == "oge") {
				toks.pop();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(FLe, b, a);
			}
			if (*toks == "olt") {
				toks.pop();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(FLt, a, b);
			}
			if (*toks == "ole") {
				toks.pop();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(FLe, a, b);
			}
			if (*toks == "ugt") {
				toks.pop();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return not1(cmp(FLe, a, b));
			}
			if (*toks == "uge") {
				toks.pop();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return not1(cmp(FLt, a, b));
			}
			if (*toks == "ult") {
				toks.pop();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return not1(cmp(FLe, b, a));
			}
			if (*toks == "ule") {
				toks.pop();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return not1(cmp(FLt, b, a));
			}
			if (*toks == "une") {
				toks.pop();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return not1(cmp(FEq, b, a));
			}
			throw error("expected condition");
		}
		if (*toks == "fdiv") {
			toks.pop();
			fastMathFlags();
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(FDiv, ty, a, b);
		}
		if (*toks == "fmul") {
			toks.pop();
			fastMathFlags();
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(FMul, ty, a, b);
		}
		if (*toks == "fneg") {
			toks.pop();
			fastMathFlags();
			auto ty = type();
			auto a = expr(ty);
			return Term(FNeg, ty, a);
		}
		if (*toks == "frem") {
			toks.pop();
			fastMathFlags();
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(FRem, ty, a, b);
		}
		if (*toks == "fsub") {
			toks.pop();
			fastMathFlags();
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(FSub, ty, a, b);
		}
		if (*toks == "getelementptr") {
			toks.pop();
			if (*toks == "inbounds") {
				toks.pop();
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
		if (*toks == "icmp") {
			toks.pop();
			if (*toks == "eq") {
				toks.pop();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(Eq, a, b);
			}
			if (*toks == "ne") {
				toks.pop();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return not1(cmp(Eq, b, a));
			}
			if (*toks == "ugt") {
				toks.pop();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(ULt, b, a);
			}
			if (*toks == "uge") {
				toks.pop();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(ULe, b, a);
			}
			if (*toks == "ult") {
				toks.pop();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(ULt, a, b);
			}
			if (*toks == "ule") {
				toks.pop();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(ULe, a, b);
			}
			if (*toks == "sgt") {
				toks.pop();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(SLt, b, a);
			}
			if (*toks == "sge") {
				toks.pop();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(SLe, b, a);
			}
			if (*toks == "slt") {
				toks.pop();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(SLt, a, b);
			}
			if (*toks == "sle") {
				toks.pop();
				auto ty = type();
				auto a = expr(ty);
				expect(",");
				auto b = expr(ty);
				return cmp(SLe, a, b);
			}
			throw error("expected condition");
		}
		if (*toks == "load") {
			toks.pop();
			auto ty = type();
			expect(",");
			auto a = ptrExpr();
			return Term(Load, ty, a);
		}
		if (*toks == "lshr") {
			toks.pop();
			if (*toks == "exact") {
				toks.pop();
			}
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(LShr, ty, a, b);
		}
		if (*toks == "mul") {
			toks.pop();
			noWrap();
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(Mul, ty, a, b);
		}
		if (*toks == "or") {
			toks.pop();
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(Or, ty, a, b);
		}
		if (*toks == "sdiv") {
			toks.pop();
			if (*toks == "exact") {
				toks.pop();
			}
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(SDiv, ty, a, b);
		}
		if (*toks == "sext" || *toks == "fptosi" || *toks == "sitofp") {
			toks.pop();
			auto a = typeExpr();
			expect("to");
			auto ty = type();
			return Term(SCast, ty, a);
		}
		if (*toks == "shl") {
			toks.pop();
			noWrap();
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(Shl, ty, a, b);
		}
		if (*toks == "srem") {
			toks.pop();
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(SRem, ty, a, b);
		}
		if (*toks == "sub") {
			toks.pop();
			noWrap();
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(Sub, ty, a, b);
		}
		if (*toks == "trunc" || *toks == "zext" || *toks == "fptrunc" || *toks == "fpext" || *toks == "fptoui" ||
			*toks == "uitofp" || *toks == "ptrtoint" || *toks == "inttoptr" || *toks == "bitcast") {
			toks.pop();
			auto a = typeExpr();
			expect("to");
			auto ty = type();
			return Term(Cast, ty, a);
		}
		if (*toks == "udiv") {
			toks.pop();
			if (*toks == "exact") {
				toks.pop();
			}
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(UDiv, ty, a, b);
		}
		if (*toks == "urem") {
			toks.pop();
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(URem, ty, a, b);
		}
		if (*toks == "xor") {
			toks.pop();
			auto ty = type();
			auto a = expr(ty);
			expect(",");
			auto b = expr(ty);
			return Term(Xor, ty, a, b);
		}
		// END

		throw error("expected rval");
	}

	void target1() {
		expect("target");
		if (*toks == "datalayout") {
			toks.pop();
			expect("=");
			auto tok = toks->s;
			if (tok[0] != '"') {
				throw error("expected string");
			}
			module->datalayout = unwrap(tok);
			return;
		}
		if (*toks == "triple") {
			toks.pop();
			expect("=");
			auto tok = toks->s;
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
		if (toks->s[0] != '%') {
			throw error("expected variable name");
		}
		return var(ty, ref1());
	}

public:
	Module* module = new Module;

	Parser(string file, string text): file(file) {
		Tokenizer tokenizer(file, text, toks);
		while (*toks != sentinel) {
			parse1();
			nextLine();
		}
	}
};

Module* parse(string text) {
	Parser parser("nameless.ll", text);
	return parser.module;
}

Module* parse(string file, string text) {
	Parser parser(file, text);
	return parser.module;
}
