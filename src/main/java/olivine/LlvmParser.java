package olivine;

import java.math.BigInteger;
import java.util.*;

public final class LlvmParser {
  private static final int EOF = 128;
  private static final int LOCAL_ID = 129;
  private static final int GLOBAL_ID = 130;
  private static final int COMDAT_ID = 131;
  private static final int LABEL = 132;
  private static final int WORD = 133;
  private static final int INT = 134;
  private static final int STRING = 135;
  private static final int DOTS = 136;
  private static final int FLOAT = 137;
  private static final int HEX_FLOAT = 138;

  private final String file;
  private final byte[] text;
  private int textIdx;
  private int token;
  private String tokenString;
  private boolean newline;
  private final Map<String, Type> types = new HashMap<>();
  private final Map<String, Global> globals = new HashMap<>();
  private final Map<String, Term> locals = new HashMap<>();
  private final Map<String, Block> blocks = new HashMap<>();
  private final Map<Block, List<Term>> phis = new LinkedHashMap<>();

  public static String datalayout;
  public static String triple;

  private ParseException error(String msg) {
    return new ParseException(file, line(), msg);
  }

  private ParseException error(String source, String msg) {
    return new ParseException(file, line(), source, msg);
  }

  private boolean eat(int k) {
    if (token == k) {
      lex();
      return true;
    }
    return false;
  }

  private int line() {
    var n = 1;
    for (var i = 0; i < textIdx; i++) if (text[i] == '\n') n++;
    return n;
  }

  private String expect(int k) {
    if (token == k) return lex1();
    throw error(k < 128 ? "expected '%c'".formatted(k) : "syntax error");
  }

  private boolean eat(String s) {
    if (token == WORD && tokenString.equals(s)) {
      lex();
      return true;
    }
    return false;
  }

  private void expect(String s) {
    if (!eat(s)) throw error("expected '%s'".formatted(s));
  }

  private String lex1() {
    var s = tokenString;
    lex();
    return s;
  }

  private String idem(String s) {
    if (s == null || s.equals(tokenString)) return tokenString;
    throw error("does not match previous declaration");
  }

  private Type primaryType() {
    switch (token) {
      case WORD -> {
        return switch (expect(WORD)) {
          case "void" -> Type.VOID;
          case "ptr" -> Type.PTR;
          case "half" -> Type.HALF;
          case "bfloat" -> Type.BFLOAT;
          case "float" -> Type.FLOAT;
          case "double" -> Type.DOUBLE;
          case "fp128" -> Type.FP128;
          case "x86_fp80" -> Type.X86_FP80;
          case "ppc_fp128" -> Type.PPC_FP128;
          case "i1" -> Type.I1;
          case "i8" -> Type.I8;
          case "i16" -> Type.I16;
          case "i32" -> Type.I32;
          case "i64" -> Type.I64;
          case "i128" -> Type.I128;
          default -> throw error("unknown type");
        };
      }
      case '[' -> {
        lex();
        var n = Integer.parseInt(expect(INT));
        expect("x");
        var x = type();
        expect(']');
        return x.array(n);
      }
      case '<' -> {
        lex();
        var n = Integer.parseInt(expect(INT));
        expect("x");
        var x = type();
        expect('>');
        return x.vector(n);
      }
      case '{' -> {
        lex();
        var fields = new ArrayList<Type>();
        do fields.add(type());
        while (eat(','));
        expect('}');
        return Type.struct(fields);
      }
      case LOCAL_ID -> {
        var type = types.get(tokenString);
        if (type == null) type = new UnresolvedType(tokenString);
        lex();
        return type;
      }
    }
    throw error("expected type");
  }

  private Type type() {
    var type = primaryType();
    switch (token) {
      case WORD -> {
        if (eat("align")) expect(INT);
      }
      case '*' -> {
        //noinspection StatementWithEmptyBody
        do
          ;
        while (eat('*'));
        return Type.PTR;
      }
      case '(' -> {
        lex();
        var params = new ArrayList<Type>();
        var varargs = false;
        if (token != ')')
          do {
            if (eat(DOTS)) {
              varargs = true;
              continue;
            }
            params.add(type());
          } while (eat(','));
        expect(')');
        return Type.function(type, params, varargs);
      }
    }
    return type;
  }

  private void linkageType() {
    if (token == WORD)
      switch (tokenString) {
        case "private",
                "internal",
                "available_externally",
                "linkonce",
                "weak",
                "common",
                "appending",
                "extern_weak",
                "linkonce_odr",
                "weak_odr",
                "external" ->
            lex();
      }
  }

  private void dso() {
    if (token == WORD)
      switch (tokenString) {
        case "dso_local", "dso_preemptable" -> lex();
      }
  }

  private void paramAttr() {
    eat("noundef");
  }

  private Block block() {
    var block = blocks.get(tokenString);
    if (block == null) {
      block = new Block();
      blocks.put(tokenString, block);
    }
    lex();
    return block;
  }

  private void noWrap() {
    eat("nsw");
  }

  private void fastMathFlags() {
    while (token == WORD)
      switch (tokenString) {
        case "nnan", "ninf", "nsz", "arcp", "contract", "afn", "reassoc", "fast" -> lex();
        default -> {
          return;
        }
      }
  }

  private Term call() {
    var f = typeExpr();
    var args = new ArrayList<Term>();
    expect('(');
    if (token != ')')
      do {
        var type = type();
        paramAttr();
        args.add(expr(type));
      } while (eat(','));
    expect(')');
    return f.call(args);
  }

  private Block label() {
    expect("label");
    return block();
  }

  private Variable variable(String name, Type type) {
    var a = (Variable) locals.get(name);
    if (a == null) {
      a = new Variable(type);
      locals.put(name, a);
    }
    return a;
  }

  private Term getelementptr(Type type, Term ptr, List<Term> idxs) {
    // The first index of getelementptr is for the case when the pointer is to an array
    ptr = ptr.elementPtr(type, idxs.getFirst());
    for (var i = 1; i < idxs.size(); i++) {
      var idx = idxs.get(i);
      switch (type.kind()) {
        case ARRAY -> {
          type = type.get(0);
          ptr = ptr.elementPtr(type, idx);
        }
        case STRUCT -> {
          var idx1 = idx.intValueExact();
          ptr = ptr.fieldPtr(type, idx1);
          type = type.get(idx1);
        }
        default -> throw error("expected compound type");
      }
    }
    return ptr;
  }

  private Term expr(Type type) {
    return switch (token) {
      case WORD -> {
        // TODO: more accurate position report
        var s = lex1();
        yield switch (s) {
          case "getelementptr" -> {
            expect('(');
            type = type();
            expect(',');
            expect("ptr");
            var ptrVal = expr(Type.PTR);
            var idxs = new ArrayList<Term>();
            while (eat(',')) idxs.add(typeExpr());
            var r = getelementptr(type, ptrVal, idxs);
            expect(')');
            yield r;
          }
          case "null" -> Term.NULL;
          case "true" -> Term.TRUE;
          case "false" -> Term.FALSE;
          case "zeroinitializer" -> Term.zeroinitializer(type);
          default -> throw error(s, "expected expression");
        };
      }
      case INT -> Term.intConstant(type, new BigInteger(lex1()));
      case FLOAT, HEX_FLOAT -> Term.floatConstant(type, lex1());
      case GLOBAL_ID -> {
        var a = globals.get(lex1());
        if (a == null) throw error("name not found");
        if (a instanceof GlobalVariable) yield a.addr();
        yield a;
      }
      case LOCAL_ID -> variable(lex1(), type);
      case STRING -> {
        var v = new Term[tokenString.length()];
        for (var i = 0; i < v.length; i++) v[i] = Term.intConstant(Type.I8, tokenString.charAt(i));
        lex();
        yield Term.array(Type.I8, v);
      }
      default -> throw error("expected expression");
    };
  }

  private Term typeExpr() {
    return expr(type());
  }

  private void instruction(Block block) {
    if (token == LOCAL_ID) {
      var name = lex1();
      expect('=');
      Term value;
      switch (expect(WORD)) {
        case "select" -> {
          fastMathFlags();
          var cond = typeExpr();
          expect(",");
          var ifTrue = typeExpr();
          expect(",");
          value = cond.select(ifTrue, typeExpr());
        }
        case "fcmp" -> {
          fastMathFlags();
          value =
              switch (expect(WORD)) {
                case "oeq" -> {
                  var type = type();
                  var a = expr(type);
                  expect(',');
                  yield a.feq(expr(type));
                }
                case "une" -> {
                  var type = type();
                  var a = expr(type);
                  expect(',');
                  yield a.fne(expr(type));
                }
                case "olt" -> {
                  var type = type();
                  var a = expr(type);
                  expect(',');
                  yield a.flt(expr(type));
                }
                case "ole" -> {
                  var type = type();
                  var a = expr(type);
                  expect(',');
                  yield a.fle(expr(type));
                }
                case "ogt" -> {
                  var type = type();
                  var b = expr(type);
                  expect(',');
                  yield expr(type).flt(b);
                }
                case "oge" -> {
                  var type = type();
                  var b = expr(type);
                  expect(',');
                  yield expr(type).fle(b);
                }
                default -> throw error("unknown condition");
              };
        }
        case "icmp" ->
            value =
                switch (expect(WORD)) {
                  case "eq" -> {
                    var type = type();
                    var a = expr(type);
                    expect(',');
                    yield a.eq(expr(type));
                  }
                  case "ne" -> {
                    var type = type();
                    var a = expr(type);
                    expect(',');
                    yield a.ne(expr(type));
                  }
                  case "ult" -> {
                    var type = type();
                    var a = expr(type);
                    expect(',');
                    yield a.ult(expr(type));
                  }
                  case "ule" -> {
                    var type = type();
                    var a = expr(type);
                    expect(',');
                    yield a.ule(expr(type));
                  }
                  case "slt" -> {
                    var type = type();
                    var a = expr(type);
                    expect(',');
                    yield a.slt(expr(type));
                  }
                  case "sle" -> {
                    var type = type();
                    var a = expr(type);
                    expect(',');
                    yield a.sle(expr(type));
                  }
                  case "ugt" -> {
                    var type = type();
                    var b = expr(type);
                    expect(',');
                    yield expr(type).ult(b);
                  }
                  case "uge" -> {
                    var type = type();
                    var b = expr(type);
                    expect(',');
                    yield expr(type).ule(b);
                  }
                  case "sgt" -> {
                    var type = type();
                    var b = expr(type);
                    expect(',');
                    yield expr(type).slt(b);
                  }
                  case "sge" -> {
                    var type = type();
                    var b = expr(type);
                    expect(',');
                    yield expr(type).sle(b);
                  }
                  default -> throw error("unknown condition");
                };
        case "phi" -> {
          fastMathFlags();
          var type = type();
          var variable = variable(name, type);
          do {
            expect('[');
            var val = expr(type);
            expect(',');
            var from = block();
            expect(']');
            var assign = phis.computeIfAbsent(from, _ -> new ArrayList<>());
            assign.add(variable);
            assign.add(val);
          } while (eat(','));
          return;
        }
        case "fneg" -> {
          fastMathFlags();
          value = typeExpr().fneg();
        }
        case "fadd" -> {
          fastMathFlags();
          var type = type();
          var a = expr(type);
          expect(',');
          value = a.fadd(expr(type));
        }
        case "fsub" -> {
          fastMathFlags();
          var type = type();
          var a = expr(type);
          expect(',');
          value = a.fsub(expr(type));
        }
        case "fmul" -> {
          fastMathFlags();
          var type = type();
          var a = expr(type);
          expect(',');
          value = a.fmul(expr(type));
        }
        case "fdiv" -> {
          fastMathFlags();
          var type = type();
          var a = expr(type);
          expect(',');
          value = a.fdiv(expr(type));
        }
        case "frem" -> {
          fastMathFlags();
          var type = type();
          var a = expr(type);
          expect(',');
          value = a.frem(expr(type));
        }
        case "add" -> {
          noWrap();
          var type = type();
          var a = expr(type);
          expect(',');
          value = a.add(expr(type));
        }
        case "sub" -> {
          noWrap();
          var type = type();
          var a = expr(type);
          expect(',');
          value = a.sub(expr(type));
        }
        case "mul" -> {
          noWrap();
          var type = type();
          var a = expr(type);
          expect(',');
          value = a.mul(expr(type));
        }
        case "udiv" -> {
          eat("exact");
          var type = type();
          var a = expr(type);
          expect(',');
          value = a.udiv(expr(type));
        }
        case "sdiv" -> {
          eat("exact");
          var type = type();
          var a = expr(type);
          expect(',');
          value = a.sdiv(expr(type));
        }
        case "urem" -> {
          var type = type();
          var a = expr(type);
          expect(',');
          value = a.urem(expr(type));
        }
        case "srem" -> {
          var type = type();
          var a = expr(type);
          expect(',');
          value = a.srem(expr(type));
        }
        case "or" -> {
          var type = type();
          var a = expr(type);
          expect(',');
          value = a.or(expr(type));
        }
        case "and" -> {
          var type = type();
          var a = expr(type);
          expect(',');
          value = a.and(expr(type));
        }
        case "xor" -> {
          var type = type();
          var a = expr(type);
          expect(',');
          value = a.xor(expr(type));
        }
        case "shl" -> {
          var type = type();
          var a = expr(type);
          expect(',');
          value = a.shl(expr(type));
        }
        case "ashr" -> {
          var type = type();
          var a = expr(type);
          expect(',');
          value = a.ashr(expr(type));
        }
        case "lshr" -> {
          var type = type();
          var a = expr(type);
          expect(',');
          value = a.lshr(expr(type));
        }
        case "getelementptr" -> {
          eat("inbounds");
          var type = type();
          expect(',');
          expect("ptr");
          var ptrVal = expr(Type.PTR);
          var idxs = new ArrayList<Term>();
          while (eat(',')) idxs.add(typeExpr());
          value = getelementptr(type, ptrVal, idxs);
        }
        case "call" -> value = call();
        case "alloca" -> {
          var type = type();
          var numElements = Term.ONE;
          if (eat(',') && !eat("align")) numElements = typeExpr();
          value = Term.alloca(type, numElements);
        }
        case "load" -> {
          var type = type();
          expect(',');
          expect("ptr");
          value = expr(type).load(type);
        }
        case "bitcast",
            "trunc",
            "fptrunc",
            "fpext",
            "zext",
            "fptoui",
            "uitofp",
            "ptrtoint",
            "inttoptr" -> {
          var a = typeExpr();
          expect("to");
          value = a.cast(type());
        }
        case "sext", "fptosi", "sitofp" -> {
          var a = typeExpr();
          expect("to");
          value = a.scast(type());
        }
        default -> throw error("unknown instruction");
      }
      block.add(new Assign(variable(name, value.type()), value));
      return;
    }
    switch (expect(WORD)) {
      case "call" -> block.add(new AssignVoid(call()));
      case "store" -> {
        var value = typeExpr();
        expect(',');
        var pointer = typeExpr();
        block.add(new Store(value, pointer));
      }
      case "unreachable" -> block.add(new Unreachable());
      case "ret" -> {
        if (eat("void")) {
          block.add(new RetVoid());
          return;
        }
        block.add(new Ret(typeExpr()));
      }
      case "switch" -> {
        var value = typeExpr();
        expect(',');
        var defaultDest = label();
        var switch1 = new Switch(value, defaultDest);
        expect('[');
        do {
          var val = typeExpr();
          expect(',');
          var dest = label();
          switch1.cases.add(new Case(val, dest));
        } while (!eat(']'));
        block.add(switch1);
      }
      case "br" -> {
        switch (expect(WORD)) {
          case "label" -> block.add(new BrUnconditional(block()));
          case "i1" -> {
            var cond = expr(Type.I1);
            expect(',');
            var ifTrue = label();
            expect(',');
            var ifFalse = label();
            block.add(new Br(cond, ifTrue, ifFalse));
          }
          default -> throw error("unknown branch type");
        }
      }
      default -> throw error("unknown instruction");
    }
  }

  private LlvmParser(String file, byte[] text, Module module) {
    this.file = file;
    this.text = text;

    // First pass, define types along with miscellaneous items that don't depend on other
    // definitions
    reset();
    while (token != EOF) {
      switch (token) {
        case LOCAL_ID -> {
          var name = lex1();
          expect('=');
          if (eat("type")) types.put(name, type());
        }
        case WORD -> {
          if (lex1().equals("target")) {
            var t = expect(WORD);
            expect('=');
            if (token != STRING) throw error("expected string");
            switch (t) {
              case "datalayout" -> datalayout = idem(datalayout);
              case "triple" -> triple = idem(triple);
              default -> throw error(t, "unknown target attribute");
            }
          }
        }
        case COMDAT_ID -> {
          module.comdats.add(lex1());
          expect('=');
          expect("comdat");
          expect("any");
        }
        default -> lex();
      }
      eol();
    }

    // Second pass, declare symbols
    reset();
    while (token != EOF) {
      switch (token) {
        case WORD -> {
          switch (lex1()) {
            case "define", "declare" -> {
              linkageType();
              dso();
              var rtype = type();
              var name = expect(GLOBAL_ID);
              expect('(');
              var params = new ArrayList<Variable>();
              var varargs = false;
              if (token != ')')
                do {
                  if (eat(DOTS)) {
                    varargs = true;
                    continue;
                  }
                  params.add(new Variable(type()));
                  paramAttr();
                  eat(LOCAL_ID);
                } while (eat(','));
              expect(')');
              var function = new Function(name, rtype, params, varargs);
              declare(name, function);
              module.functions.add(function);
            }
          }
        }
        case GLOBAL_ID -> {
          var name = lex1();
          expect('=');
          linkageType();
          dso();
          eat("unnamed_addr");
          if (token == WORD)
            switch (tokenString) {
              case "constant", "global" -> lex();
            }
          var a = new GlobalVariable(name, type());
          declare(name, a);
          module.variables.add(a);
        }
        default -> lex();
      }
      eol();
    }

    // Third pass, fill in global values and function bodies
    reset();
    while (token != EOF) {
      // TODO: refactor?
      switch (token) {
        case WORD -> {
          // Function definition
          if (lex1().equals("define")) {
            linkageType();
            dso();

            // Return type
            type();

            // Name
            var function = (Function) globals.get(expect(GLOBAL_ID));

            // Parameters
            expect('(');
            var i = 0;
            locals.clear();
            if (token != ')')
              do {
                if (eat(DOTS)) continue;
                type();
                paramAttr();
                locals.put(expect(LOCAL_ID), function.params.get(i++));
              } while (eat(','));
            while (!eat('{')) {
              if (token == EOF) throw error("unexpected end of file");
              lex();
            }

            // Entry block
            var block = new Block();
            function.entry = block;
            if (token == LABEL) blocks.put(lex1(), block);

            // Body
            while (!eat('}')) {
              if (token == LABEL) {
                block = block();
                continue;
              }
              instruction(block);
              eol();
            }

            // Phis
            for (var entry : phis.entrySet()) {
              var from = entry.getKey();

              // Terminator instruction needs to follow the phi assignments from this block
              // so get it out of the way for now
              // If the terminator is a conditional branch
              // then the phi assignments for blocks not jumped to on a particular occasion
              // will be redundant but harmless
              var terminator = from.pop();

              // Assignments
              var assign = entry.getValue();
              for (var j = 0; j < assign.size(); j += 2) {
                var variable = (Variable) assign.get(j);
                var val = assign.get(j + 1);
                from.add(new Assign(variable, val));
              }

              // Put the terminator back, after the phi assignments
              from.add(terminator);
            }
            phis.clear();
          }
        }
        case GLOBAL_ID -> {
          var variable = (GlobalVariable) globals.get(lex1());
          expect('=');
          linkageType();
          dso();
          eat("unnamed_addr");
          if (token == WORD)
            switch (tokenString) {
              case "constant", "global" -> lex();
            }
          variable.value = typeExpr();
        }
        default -> lex();
      }
      eol();
    }
  }

  private void declare(String name, Global a) {
    if (globals.put(name, a) != null) throw error(name, "duplicate name");
  }

  private void reset() {
    textIdx = 0;
    lex();
  }

  private void lexQuote() {
    assert text[textIdx] == '"';
    textIdx++;
    var sb = new StringBuilder();
    while (text[textIdx] != '"') {
      int c = text[textIdx++];
      if (c == '\\') {
        c = Etc.parseHexDigit(text[textIdx]) << 4 + Etc.parseHexDigit(text[textIdx + 1]);
        textIdx += 2;
      }
      sb.append((char) c);
    }
    textIdx++;
    tokenString = sb.toString();
  }

  public static boolean isIdPart(int c) {
    if (Etc.isAlnum(c)) return true;
    return switch (c) {
      case '-', '_', '.', '$' -> true;
      default -> false;
    };
  }

  private void lexId() {
    textIdx++;
    if (text[textIdx] == '"') {
      lexQuote();
      return;
    }
    var sb = new StringBuilder();
    do sb.append((char) text[textIdx++]);
    while (isIdPart(text[textIdx]));
    tokenString = sb.toString();
  }

  private void lexWord() {
    var sb = new StringBuilder();
    do sb.append((char) text[textIdx++]);
    while (Etc.isAlnum(text[textIdx]) || text[textIdx] == '_' || text[textIdx] == '.');
    token = WORD;
    if (text[textIdx] == ':') {
      textIdx++;
      token = LABEL;
    }
    tokenString = sb.toString();
  }

  private void lex() {
    newline = false;
    for (; ; ) {
      if (textIdx == text.length) {
        token = EOF;
        return;
      }
      switch (text[textIdx]) {
        case ' ', '\r', '\t', '\f' -> {
          textIdx++;
          continue;
        }
        case '\n' -> {
          textIdx++;
          newline = true;
          continue;
        }
        case ';' -> {
          do textIdx++;
          while (text[textIdx] != '\n');
          continue;
        }
        case '%' -> {
          token = LOCAL_ID;
          lexId();
        }
        case '@' -> {
          token = GLOBAL_ID;
          lexId();
        }
        case '$' -> {
          token = COMDAT_ID;
          lexId();
        }
        case '"' -> {
          token = STRING;
          lexQuote();
        }
        case 'c' -> {
          if (text[textIdx + 1] == '"') {
            textIdx++;
            token = STRING;
            lexQuote();
            break;
          }
          lexWord();
        }
        case 'A',
                'B',
                'C',
                'D',
                'E',
                'F',
                'G',
                'H',
                'I',
                'J',
                'K',
                'L',
                'M',
                'N',
                'O',
                'P',
                'Q',
                'R',
                'S',
                'T',
                'U',
                'V',
                'W',
                'X',
                'Y',
                'Z',
                'a',
                'b',
                'd',
                'e',
                'f',
                'g',
                'h',
                'i',
                'j',
                'k',
                'l',
                'm',
                'n',
                'o',
                'p',
                'q',
                'r',
                's',
                't',
                'u',
                'v',
                'w',
                'x',
                'y',
                'z',
                '_' ->
            lexWord();
        case '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '-' -> {
          var sb = new StringBuilder();
          sb.append((char) text[textIdx++]);
          token = INT;
          if (text[textIdx] == 'x') token = HEX_FLOAT;
          while (Etc.isAlnum(text[textIdx]) || text[textIdx] == '.' || Etc.isSign(text[textIdx])) {
            int c = text[textIdx++];
            if (!Etc.isDigit(c) && token == INT) token = FLOAT;
            sb.append((char) c);
          }
          tokenString = sb.toString();
        }
        case '.' -> {
          if (text[textIdx + 1] == '.' && text[textIdx + 2] == '.') {
            textIdx += 3;
            token = DOTS;
            break;
          }
          textIdx++;
        }
        default -> token = text[textIdx++];
      }
      break;
    }
  }

  private void eol() {
    if (newline) return;
    while (text[textIdx] != '\n') textIdx++;
    lex();
  }

  public static Module parse(String file, byte[] text) {
    var module = new Module();
    new LlvmParser(file, text, module);
    return module;
  }
}
