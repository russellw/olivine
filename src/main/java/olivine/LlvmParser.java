package olivine;

import java.math.BigInteger;
import java.util.*;

public final class LlvmParser {
  private static final int COMDAT = 128;
  private static final int DOTS = 129;
  private static final int EOF = 130;
  private static final int FLOAT = 131;
  private static final int GLOBAL = 132;
  private static final int HEX_FLOAT = 133;
  private static final int INT = 134;
  private static final int LABEL = 135;
  private static final int LOCAL = 136;
  private static final int STRING = 137;
  private static final int WORD = 138;

  public static String datalayout;
  public static String triple;

  private final Map<String, Block> blocks = new HashMap<>();
  private final String file;
  private final Map<String, Global> globals = new HashMap<>();
  private final Map<String, Term> locals = new HashMap<>();
  private final Map<Block, List<Term>> phis = new LinkedHashMap<>();
  private final byte[] text;
  private int textIdx;
  private int token;
  private String tokenString;
  private final Map<String, Type> types = new HashMap<>();

  private LlvmParser(String file, byte[] text, Module module) {
    this.file = file;
    this.text = text;

    // First pass, define types along with miscellaneous items that don't depend on other
    // definitions
    reset();
    while (token != EOF) {
      switch (token) {
        case COMDAT -> {
          lex();
          expect('=');
          expect("comdat");
          expect("any");
        }
        case LOCAL -> {
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
      }
      eol();
    }
    types.replaceAll((_, value) -> value.resolve(types));

    // Second pass, declare symbols
    reset();
    while (token != EOF) {
      switch (token) {
        case GLOBAL -> {
          var name = lex1();
          expect('=');
          linkage();
          preemptionSpecifier();
          unnamedAddr();
          if (token == WORD)
            switch (tokenString) {
              case "constant", "global" -> lex();
            }
          var variable = new GlobalVariable(name, type());
          declare(name, variable);
          module.variables.add(variable);
        }
        case WORD -> {
          switch (lex1()) {
            case "declare", "define" -> {
              linkage();
              preemptionSpecifier();
              paramAttrs();
              var rtype = type();
              var name = expect(GLOBAL);
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
                  paramAttrs();
                  eat(LOCAL);
                } while (eat(','));
              expect(')');
              var function = new Function(name, rtype, params, varargs);
              declare(name, function);
              module.functions.add(function);
            }
          }
        }
      }
      eol();
    }

    // Third pass, fill in global values and function bodies
    reset();
    while (token != EOF) {
      // TODO: refactor?
      switch (token) {
        case GLOBAL -> {
          var variable = (GlobalVariable) globals.get(lex1());
          expect('=');
          linkage();
          preemptionSpecifier();
          unnamedAddr();
          if (token == WORD)
            switch (tokenString) {
              case "constant", "global" -> lex();
            }
          variable.value = typeExpr();
        }
        case WORD -> {
          // Function definition
          if (tokenString.equals("define")) {
            blocks.clear();
            locals.clear();
            phis.clear();

            // Name
            do lex();
            while (token != GLOBAL);
            var function = (Function) globals.get(lex1());

            // Already parsed parameters for the function declaration
            // but do so again to get the local variable names of the parameters
            expect('(');
            var i = 0;
            if (token != ')')
              do {
                if (eat(DOTS)) continue;
                type();
                paramAttrs();
                locals.put(expect(LOCAL), function.params.get(i++));
              } while (eat(','));
            eol();

            // Entry block
            var entryName = token == LABEL ? lex1() : Integer.toString(function.params.size());
            var block = new Block();
            blocks.put(entryName, block);
            function.entry = block;

            // Body
            while (token != '}') {
              if (token == LABEL) {
                block = block();
                continue;
              }
              instruction(block);
              eol();
            }

            // Check everything referenced was defined
            // TODO: also check locals
            for (var entry : blocks.entrySet())
              if (entry.getValue().size() == 0) throw error('%' + entry.getKey(), "not defined");

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
          }
        }
      }
      eol();
    }
  }

  private Block block() {
    assert token == LABEL || token == LOCAL;
    var block = blocks.get(tokenString);
    if (block == null) {
      block = new Block();
      blocks.put(tokenString, block);
    }
    lex();
    return block;
  }

  private Term call() {
    var f = typeExpr();
    var args = new ArrayList<Term>();
    expect('(');
    if (token != ')')
      do {
        var type = type();
        paramAttrs();
        args.add(expr(type));
      } while (eat(','));
    expect(')');
    return f.call(args);
  }

  public String cause() {
    return switch (token) {
      case '\n' -> "newline";
      case INT, WORD -> tokenString;
      default -> {
        if (Etc.isPrint(token)) yield "'%c'".formatted(token);
        yield null;
      }
    };
  }

  private void declare(String name, Global global) {
    loop:
    for (; ; ) {
      switch (token) {
        case '\n', '{' -> {
          break loop;
        }
        case WORD -> {
          if (tokenString.equals("comdat")) global.comdat = true;
        }
      }
      lex();
    }
    if (globals.put(name, global) != null) throw error(name, "duplicate name");
  }

  private boolean eat(String s) {
    if (token == WORD && tokenString.equals(s)) {
      lex();
      return true;
    }
    return false;
  }

  private boolean eat(int k) {
    if (token == k) {
      lex();
      return true;
    }
    return false;
  }

  private void eol() {
    assert token != EOF;
    while (!eat('\n')) lex();
  }

  private ParseException error(String cause, String msg) {
    if (cause == null) return new ParseException(file, line(), msg);
    return new ParseException(file, line(), cause, msg);
  }

  private ParseException error(String msg) {
    return new ParseException(file, line(), msg);
  }

  private String expect(int k) {
    if (token == k) return lex1();
    var msg = k < 128 ? "expected '%c'".formatted(k) : "syntax error";
    throw error(cause(), msg);
  }

  private void expect(String s) {
    if (!eat(s)) throw error("expected '%s'".formatted(s));
  }

  private Term expr(Type type) {
    return switch (token) {
      case '{' -> {
        lex();
        var fields = new ArrayList<Term>();
        do fields.add(expr(type()));
        while (eat(','));
        expect('}');
        yield Term.struct(type, fields);
      }
      case FLOAT, HEX_FLOAT -> Term.floatConstant(type, lex1());
      case GLOBAL -> {
        var a = globals.get(lex1());
        if (a == null) throw error("name not found");
        if (a instanceof GlobalVariable) yield a.addr();
        yield a;
      }
      case INT -> Term.intConstant(type, new BigInteger(lex1()));
      case LOCAL -> variable(lex1(), type);
      case STRING -> {
        var bytes = new Term[tokenString.length()];
        for (var i = 0; i < bytes.length; i++)
          bytes[i] = Term.intConstant(Type.I8, tokenString.charAt(i));
        lex();
        yield Term.array(Type.I8, bytes);
      }
      case WORD -> {
        var s = lex1();
        yield switch (s) {
          case "false" -> Term.FALSE;
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
          case "undef" -> Term.undef(type);
          case "zeroinitializer" -> Term.zeroinitializer(type);
          default -> throw error(s, "expected expression");
        };
      }
      default -> throw error("expected expression");
    };
  }

  private void fastMathFlags() {
    while (token == WORD)
      switch (tokenString) {
        case "afn", "arcp", "contract", "fast", "ninf", "nnan", "nsz", "reassoc" -> lex();
        default -> {
          return;
        }
      }
  }

  private Term getelementptr(Type type, Term ptr, List<Term> idxs) {
    // The first index of getelementptr is for when the pointer is to an array
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

  private void id() {
    textIdx++;
    if (text[textIdx] == '"') {
      quote();
      return;
    }
    var sb = new StringBuilder();
    do sb.append((char) text[textIdx++]);
    while (isIdPart(text[textIdx]));
    tokenString = sb.toString();
  }

  private String idem(String s) {
    if (s == null || s.equals(tokenString)) return tokenString;
    throw error("does not match previous declaration");
  }

  private void instruction(Block block) {
    switch (token) {
      case '\n' -> {}
      case LOCAL -> {
        var name = lex1();
        expect('=');
        String cause;
        Term value;
        switch (cause = expect(WORD)) {
          case "add" -> {
            noWrap();
            var type = type();
            var a = expr(type);
            expect(',');
            value = a.add(expr(type));
          }
          case "alloca" -> {
            var type = type();
            var numElements = Term.ONE;
            if (eat(',') && !eat("align")) numElements = typeExpr();
            value = Term.alloca(type, numElements);
          }
          case "and" -> {
            var type = type();
            var a = expr(type);
            expect(',');
            value = a.and(expr(type));
          }
          case "ashr" -> {
            eat("exact");
            var type = type();
            var a = expr(type);
            expect(',');
            value = a.ashr(expr(type));
          }
          case "bitcast",
              "fpext",
              "fptoui",
              "fptrunc",
              "inttoptr",
              "ptrtoint",
              "trunc",
              "uitofp",
              "zext" -> {
            var a = typeExpr();
            expect("to");
            value = a.cast(type());
          }
          case "call" -> value = call();
          case "fadd" -> {
            fastMathFlags();
            var type = type();
            var a = expr(type);
            expect(',');
            value = a.fadd(expr(type));
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
                  case "oge" -> {
                    var type = type();
                    var b = expr(type);
                    expect(',');
                    yield expr(type).fle(b);
                  }
                  case "ogt" -> {
                    var type = type();
                    var b = expr(type);
                    expect(',');
                    yield expr(type).flt(b);
                  }
                  case "ole" -> {
                    var type = type();
                    var a = expr(type);
                    expect(',');
                    yield a.fle(expr(type));
                  }
                  case "olt" -> {
                    var type = type();
                    var a = expr(type);
                    expect(',');
                    yield a.flt(expr(type));
                  }
                  case "une" -> {
                    var type = type();
                    var a = expr(type);
                    expect(',');
                    yield a.fne(expr(type));
                  }
                  default -> throw error("unknown condition");
                };
          }
          case "fdiv" -> {
            fastMathFlags();
            var type = type();
            var a = expr(type);
            expect(',');
            value = a.fdiv(expr(type));
          }
          case "fmul" -> {
            fastMathFlags();
            var type = type();
            var a = expr(type);
            expect(',');
            value = a.fmul(expr(type));
          }
          case "fneg" -> {
            fastMathFlags();
            value = typeExpr().fneg();
          }
          case "fptosi", "sext", "sitofp" -> {
            var a = typeExpr();
            expect("to");
            value = a.scast(type());
          }
          case "frem" -> {
            fastMathFlags();
            var type = type();
            var a = expr(type);
            expect(',');
            value = a.frem(expr(type));
          }
          case "fsub" -> {
            fastMathFlags();
            var type = type();
            var a = expr(type);
            expect(',');
            value = a.fsub(expr(type));
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
                    case "sge" -> {
                      var type = type();
                      var b = expr(type);
                      expect(',');
                      yield expr(type).sle(b);
                    }
                    case "sgt" -> {
                      var type = type();
                      var b = expr(type);
                      expect(',');
                      yield expr(type).slt(b);
                    }
                    case "sle" -> {
                      var type = type();
                      var a = expr(type);
                      expect(',');
                      yield a.sle(expr(type));
                    }
                    case "slt" -> {
                      var type = type();
                      var a = expr(type);
                      expect(',');
                      yield a.slt(expr(type));
                    }
                    case "uge" -> {
                      var type = type();
                      var b = expr(type);
                      expect(',');
                      yield expr(type).ule(b);
                    }
                    case "ugt" -> {
                      var type = type();
                      var b = expr(type);
                      expect(',');
                      yield expr(type).ult(b);
                    }
                    case "ule" -> {
                      var type = type();
                      var a = expr(type);
                      expect(',');
                      yield a.ule(expr(type));
                    }
                    case "ult" -> {
                      var type = type();
                      var a = expr(type);
                      expect(',');
                      yield a.ult(expr(type));
                    }
                    default -> throw error("unknown condition");
                  };
          case "load" -> {
            var type = type();
            expect(',');
            expect("ptr");
            value = expr(type).load(type);
          }
          case "lshr" -> {
            eat("exact");
            var type = type();
            var a = expr(type);
            expect(',');
            value = a.lshr(expr(type));
          }
          case "mul" -> {
            noWrap();
            var type = type();
            var a = expr(type);
            expect(',');
            value = a.mul(expr(type));
          }
          case "or" -> {
            var type = type();
            var a = expr(type);
            expect(',');
            value = a.or(expr(type));
          }
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
          case "sdiv" -> {
            eat("exact");
            var type = type();
            var a = expr(type);
            expect(',');
            value = a.sdiv(expr(type));
          }
          case "select" -> {
            fastMathFlags();
            var cond = typeExpr();
            expect(',');
            var ifTrue = typeExpr();
            expect(',');
            value = cond.select(ifTrue, typeExpr());
          }
          case "shl" -> {
            var type = type();
            var a = expr(type);
            expect(',');
            value = a.shl(expr(type));
          }
          case "srem" -> {
            var type = type();
            var a = expr(type);
            expect(',');
            value = a.srem(expr(type));
          }
          case "sub" -> {
            noWrap();
            var type = type();
            var a = expr(type);
            expect(',');
            value = a.sub(expr(type));
          }
          case "tail" -> {
            expect("call");
            value = call();
          }
          case "udiv" -> {
            eat("exact");
            var type = type();
            var a = expr(type);
            expect(',');
            value = a.udiv(expr(type));
          }
          case "urem" -> {
            var type = type();
            var a = expr(type);
            expect(',');
            value = a.urem(expr(type));
          }
          case "xor" -> {
            var type = type();
            var a = expr(type);
            expect(',');
            value = a.xor(expr(type));
          }
          default -> throw error(cause, "unknown instruction");
        }
        block.add(new Assign(variable(name, value.type()), value));
      }
      case WORD -> {
        var mnemonic = lex1();
        switch (mnemonic) {
          case "br" -> {
            switch (expect(WORD)) {
              case "i1" -> {
                var cond = expr(Type.I1);
                expect(',');
                var ifTrue = label();
                expect(',');
                var ifFalse = label();
                block.add(new Br(cond, ifTrue, ifFalse));
              }
              case "label" -> block.add(new BrUnconditional(block()));
              default -> throw error("unknown branch type");
            }
          }
          case "call" -> block.add(new VoidCall(call()));
          case "ret" -> {
            if (eat("void")) {
              block.add(new RetVoid());
              return;
            }
            block.add(new Ret(typeExpr()));
          }
          case "store" -> {
            var value = typeExpr();
            expect(',');
            var pointer = typeExpr();
            block.add(new Store(value, pointer));
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
          case "tail" -> {
            expect("call");
            block.add(new VoidCall(call()));
          }
          case "unreachable" -> block.add(new Unreachable());
          default -> throw error(mnemonic, "unknown instruction");
        }
      }
      default -> throw error(cause(), "expected instruction");
    }
  }

  public static boolean isIdPart(int c) {
    if (Etc.isAlnum(c)) return true;
    return switch (c) {
      case '$', '-', '.', '_' -> true;
      default -> false;
    };
  }

  private Block label() {
    expect("label");
    return block();
  }

  private void lex() {
    while (textIdx < text.length) {
      switch (text[textIdx]) {
        case ' ', '\f', '\r', '\t' -> {
          textIdx++;
          continue;
        }
        case '"' -> {
          token = STRING;
          quote();
        }
        case '$' -> {
          token = COMDAT;
          id();
        }
        case '%' -> {
          token = LOCAL;
          id();
        }
        case '-', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' -> {
          var sb = new StringBuilder();
          sb.append((char) text[textIdx++]);
          token = INT;
          if (text[textIdx] == 'x') token = HEX_FLOAT;
          while (Etc.isAlnum(text[textIdx]) || text[textIdx] == '.' || Etc.isSign(text[textIdx])) {
            int c = text[textIdx++];
            if (!Etc.isDigit(c) && token == INT) token = FLOAT;
            sb.append((char) c);
          }
          maybeLabel();
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
        case ';' -> {
          do textIdx++;
          while (text[textIdx] != '\n');
          continue;
        }
        case '@' -> {
          token = GLOBAL;
          id();
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
                '_',
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
                'z' ->
            word();
        case 'c' -> {
          if (text[textIdx + 1] == '"') {
            textIdx++;
            token = STRING;
            quote();
            break;
          }
          word();
        }
        default -> token = text[textIdx++];
      }
      return;
    }
    token = EOF;
  }

  private String lex1() {
    var s = tokenString;
    lex();
    return s;
  }

  private int line() {
    var n = 1;
    for (var i = 0; i < textIdx - 1; i++) if (text[i] == '\n') n++;
    return n;
  }

  private void linkage() {
    if (token == WORD)
      switch (tokenString) {
        case "appending",
                "available_externally",
                "common",
                "extern_weak",
                "external",
                "internal",
                "linkonce",
                "linkonce_odr",
                "private",
                "weak",
                "weak_odr" ->
            lex();
      }
  }

  private void maybeLabel() {
    if (text[textIdx] == ':') {
      textIdx++;
      token = LABEL;
    }
  }

  private void noWrap() {
    eat("nuw");
    eat("nsw");
  }

  private void paramAttrs() {
    while (token == WORD)
      switch (tokenString) {
        case "dereferenceable" -> {
          lex();
          expect('(');
          expect(INT);
          expect(')');
        }
        case "immarg", "nocapture", "nonnull", "noundef", "readnone", "readonly", "returned" ->
            lex();
        default -> {
          return;
        }
      }
  }

  public static Module parse(String file, byte[] text) {
    if (text.length == 0 || text[text.length - 1] != '\n')
      throw new IllegalArgumentException("input does not end in newline");
    var module = new Module();
    new LlvmParser(file, text, module);
    return module;
  }

  private void preemptionSpecifier() {
    if (token == WORD)
      switch (tokenString) {
        case "dso_local", "dso_preemptable" -> lex();
      }
  }

  private Type primaryType() {
    switch (token) {
      case '<' -> {
        lex();
        var n = Integer.parseInt(expect(INT));
        expect("x");
        var x = type();
        expect('>');
        return x.vector(n);
      }
      case '[' -> {
        lex();
        var n = Integer.parseInt(expect(INT));
        expect("x");
        var x = type();
        expect(']');
        return x.array(n);
      }
      case '{' -> {
        lex();
        var fields = new ArrayList<Type>();
        do fields.add(type());
        while (eat(','));
        expect('}');
        return Type.struct(fields);
      }
      case LOCAL -> {
        var type = types.get(tokenString);
        if (type == null) type = new UnresolvedType(tokenString);
        lex();
        return type;
      }
      case WORD -> {
        var s = lex1();
        return switch (s) {
          case "bfloat" -> Type.BFLOAT;
          case "double" -> Type.DOUBLE;
          case "float" -> Type.FLOAT;
          case "fp128" -> Type.FP128;
          case "half" -> Type.HALF;
          case "i1" -> Type.I1;
          case "i128" -> Type.I128;
          case "i16" -> Type.I16;
          case "i32" -> Type.I32;
          case "i64" -> Type.I64;
          case "i8" -> Type.I8;
          case "ppc_fp128" -> Type.PPC_FP128;
          case "ptr" -> Type.PTR;
          case "void" -> Type.VOID;
          case "x86_fp80" -> Type.X86_FP80;
          default -> throw error(s, "unknown type");
        };
      }
    }
    throw error("expected type");
  }

  private void quote() {
    assert text[textIdx] == '"';
    textIdx++;
    var sb = new StringBuilder();
    while (text[textIdx] != '"') {
      int c = text[textIdx++];
      if (c == '\\')
        switch (text[textIdx]) {
          case '0',
              '1',
              '2',
              '3',
              '4',
              '5',
              '6',
              '7',
              '8',
              '9',
              'A',
              'B',
              'C',
              'D',
              'E',
              'F',
              'a',
              'b',
              'c',
              'd',
              'e',
              'f' -> {
            c = (Etc.parseHexDigit(text[textIdx]) << 4) + Etc.parseHexDigit(text[textIdx + 1]);
            textIdx += 2;
          }
          case '\\' -> textIdx++;
          default -> throw error(Integer.toString(c), "unknown escape sequence");
        }
      sb.append((char) c);
    }
    textIdx++;
    tokenString = sb.toString();
  }

  private void reset() {
    textIdx = 0;
    lex();
  }

  private Type type() {
    var type = primaryType();
    switch (token) {
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
      case '*' -> {
        //noinspection StatementWithEmptyBody
        do
          ;
        while (eat('*'));
        return Type.PTR;
      }
      case WORD -> {
        if (eat("align")) expect(INT);
      }
    }
    return type;
  }

  private Term typeExpr() {
    return expr(type());
  }

  private void unnamedAddr() {
    if (token == WORD)
      switch (tokenString) {
        case "local_unnamed_addr", "unnamed_addr" -> lex();
      }
  }

  private Variable variable(String name, Type type) {
    var a = (Variable) locals.get(name);
    if (a == null) {
      a = new Variable(type);
      locals.put(name, a);
    }
    return a;
  }

  private void word() {
    var sb = new StringBuilder();
    do sb.append((char) text[textIdx++]);
    while (isIdPart(text[textIdx]));
    token = WORD;
    maybeLabel();
    tokenString = sb.toString();
  }
}
