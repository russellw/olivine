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
  private int ti;
  private int tok;
  private String tokString;
  private boolean newline;
  private final Map<String, Type> types = new HashMap<>();
  private final Map<String, Global> globals = new HashMap<>();
  private final Map<String, Term> locals = new HashMap<>();
  private final Map<String, Block> blocks = new HashMap<>();
  private final Map<Block, List<Term>> phis = new LinkedHashMap<>();

  public static String datalayout;
  public static String triple;

  private IllegalArgumentException err(String msg) {
    return new IllegalArgumentException("%s:%d: %s".formatted(file, line(), msg));
  }

  private IllegalArgumentException err(String s, String msg) {
    return new IllegalArgumentException("%s:%d: %s: %s".formatted(file, line(), s, msg));
  }

  private boolean eat(int k) {
    if (tok == k) {
      lex();
      return true;
    }
    return false;
  }

  private int line() {
    var n = 1;
    for (var i = 0; i < ti; i++) if (text[i] == '\n') n++;
    return n;
  }

  private String expect(int k) {
    if (tok == k) return lex1();
    throw err(k < 128 ? "expected '%c'".formatted(k) : "syntax error");
  }

  private boolean eat(String s) {
    if (tok == WORD && tokString.equals(s)) {
      lex();
      return true;
    }
    return false;
  }

  private void expect(String s) {
    if (!eat(s)) throw err("expected '%s'".formatted(s));
  }

  private String lex1() {
    var s = tokString;
    lex();
    return s;
  }

  private String idem(String s) {
    if (s == null || s.equals(tokString)) return tokString;
    throw err("does not match previous declaration");
  }

  private Type primaryType() {
    switch (tok) {
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
          default -> throw err("unknown type");
        };
      }
      case '[' -> {
        lex();
        var n = Integer.parseInt(expect(INT));
        expect("x");
        var x = type();
        expect(']');
        return Type.array(n, x);
      }
      case '<' -> {
        lex();
        var n = Integer.parseInt(expect(INT));
        expect("x");
        var x = type();
        expect('>');
        return Type.vector(n, x);
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
        var type = types.get(tokString);
        if (type == null) type = new UnresolvedType(tokString);
        lex();
        return type;
      }
    }
    throw err("expected type");
  }

  private Type type() {
    var type = primaryType();
    switch (tok) {
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
        if (tok != ')')
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
    if (tok == WORD)
      switch (tokString) {
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
    if (tok == WORD)
      switch (tokString) {
        case "dso_local", "dso_preemptable" -> lex();
      }
  }

  private void paramAttr() {
    eat("noundef");
  }

  private Block block() {
    var block = blocks.get(tokString);
    if (block == null) {
      block = new Block();
      blocks.put(tokString, block);
    }
    lex();
    return block;
  }

  private void noWrap() {
    eat("nsw");
  }

  private void fastMathFlags() {
    while (tok == WORD)
      switch (tokString) {
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
    if (tok != ')')
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

  private Term getElementPtr(Type type, Term ptr, List<Term> idxs) {
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
        default -> throw err("expected compound type");
      }
    }
    return ptr;
  }

  private Term expr(Type type) {
    return switch (tok) {
      case WORD ->
          switch (lex1()) {
            case "null" -> Term.NULL;
            case "true" -> Term.TRUE;
            case "false" -> Term.FALSE;
            default -> throw err("expected expression");
          };
      case INT -> Term.intConstant(type, new BigInteger(lex1()));
      case FLOAT, HEX_FLOAT -> Term.floatConstant(type, lex1());
      case GLOBAL_ID -> {
        var a = globals.get(lex1());
        if (a == null) throw err("name not found");
        if (a instanceof GlobalVariable) yield a.addr();
        yield a;
      }
      case LOCAL_ID -> variable(lex1(), type);
      case STRING -> {
        var v = new Term[tokString.length()];
        for (var i = 0; i < v.length; i++) v[i] = Term.intConstant(Type.I8, tokString.charAt(i));
        lex();
        yield Term.array(Type.I8, v);
      }
      default -> throw err("expected expression");
    };
  }

  private Term typeExpr() {
    return expr(type());
  }

  private void instruction(Block block) {
    if (tok == LOCAL_ID) {
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
          var ifFalse = typeExpr();
          value = cond.select(ifTrue, ifFalse);
        }
        case "fcmp" -> {
          fastMathFlags();
          value =
              switch (expect(WORD)) {
                case "oeq" -> {
                  var type = type();
                  var a = expr(type);
                  expect(',');
                  var b = expr(type);
                  yield a.feq(b);
                }
                case "une" -> {
                  var type = type();
                  var a = expr(type);
                  expect(',');
                  var b = expr(type);
                  yield a.fne(b);
                }
                case "olt" -> {
                  var type = type();
                  var a = expr(type);
                  expect(',');
                  var b = expr(type);
                  yield a.flt(b);
                }
                case "ole" -> {
                  var type = type();
                  var a = expr(type);
                  expect(',');
                  var b = expr(type);
                  yield a.fle(b);
                }
                case "ogt" -> {
                  var type = type();
                  var b = expr(type);
                  expect(',');
                  var a = expr(type);
                  yield a.flt(b);
                }
                case "oge" -> {
                  var type = type();
                  var b = expr(type);
                  expect(',');
                  var a = expr(type);
                  yield a.fle(b);
                }
                default -> throw err("unknown condition");
              };
        }
        case "icmp" ->
            value =
                switch (expect(WORD)) {
                  case "eq" -> {
                    var type = type();
                    var a = expr(type);
                    expect(',');
                    var b = expr(type);
                    yield a.eq(b);
                  }
                  case "ne" -> {
                    var type = type();
                    var a = expr(type);
                    expect(',');
                    var b = expr(type);
                    yield a.ne(b);
                  }
                  case "ult" -> {
                    var type = type();
                    var a = expr(type);
                    expect(',');
                    var b = expr(type);
                    yield a.ult(b);
                  }
                  case "ule" -> {
                    var type = type();
                    var a = expr(type);
                    expect(',');
                    var b = expr(type);
                    yield a.ule(b);
                  }
                  case "slt" -> {
                    var type = type();
                    var a = expr(type);
                    expect(',');
                    var b = expr(type);
                    yield a.slt(b);
                  }
                  case "sle" -> {
                    var type = type();
                    var a = expr(type);
                    expect(',');
                    var b = expr(type);
                    yield a.sle(b);
                  }
                  case "ugt" -> {
                    var type = type();
                    var b = expr(type);
                    expect(',');
                    var a = expr(type);
                    yield a.ult(b);
                  }
                  case "uge" -> {
                    var type = type();
                    var b = expr(type);
                    expect(',');
                    var a = expr(type);
                    yield a.ule(b);
                  }
                  case "sgt" -> {
                    var type = type();
                    var b = expr(type);
                    expect(',');
                    var a = expr(type);
                    yield a.slt(b);
                  }
                  case "sge" -> {
                    var type = type();
                    var b = expr(type);
                    expect(',');
                    var a = expr(type);
                    yield a.sle(b);
                  }
                  default -> throw err("unknown condition");
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
          var b = expr(type);
          value = a.fadd(b);
        }
        case "fsub" -> {
          fastMathFlags();
          var type = type();
          var a = expr(type);
          expect(',');
          var b = expr(type);
          value = a.fsub(b);
        }
        case "fmul" -> {
          fastMathFlags();
          var type = type();
          var a = expr(type);
          expect(',');
          var b = expr(type);
          value = a.fmul(b);
        }
        case "fdiv" -> {
          fastMathFlags();
          var type = type();
          var a = expr(type);
          expect(',');
          var b = expr(type);
          value = a.fdiv(b);
        }
        case "frem" -> {
          fastMathFlags();
          var type = type();
          var a = expr(type);
          expect(',');
          var b = expr(type);
          value = a.frem(b);
        }
        case "add" -> {
          noWrap();
          var type = type();
          var a = expr(type);
          expect(',');
          var b = expr(type);
          value = a.add(b);
        }
        case "sub" -> {
          noWrap();
          var type = type();
          var a = expr(type);
          expect(',');
          var b = expr(type);
          value = a.sub(b);
        }
        case "mul" -> {
          noWrap();
          var type = type();
          var a = expr(type);
          expect(',');
          var b = expr(type);
          value = a.mul(b);
        }
        case "udiv" -> {
          eat("exact");
          var type = type();
          var a = expr(type);
          expect(',');
          var b = expr(type);
          value = a.udiv(b);
        }
        case "sdiv" -> {
          eat("exact");
          var type = type();
          var a = expr(type);
          expect(',');
          var b = expr(type);
          value = a.sdiv(b);
        }
        case "urem" -> {
          var type = type();
          var a = expr(type);
          expect(',');
          var b = expr(type);
          value = a.urem(b);
        }
        case "srem" -> {
          var type = type();
          var a = expr(type);
          expect(',');
          var b = expr(type);
          value = a.srem(b);
        }
        case "or" -> {
          var type = type();
          var a = expr(type);
          expect(',');
          var b = expr(type);
          value = a.or(b);
        }
        case "and" -> {
          var type = type();
          var a = expr(type);
          expect(',');
          var b = expr(type);
          value = a.and(b);
        }
        case "xor" -> {
          var type = type();
          var a = expr(type);
          expect(',');
          var b = expr(type);
          value = a.xor(b);
        }
        case "shl" -> {
          var type = type();
          var a = expr(type);
          expect(',');
          var b = expr(type);
          value = a.shl(b);
        }
        case "ashr" -> {
          var type = type();
          var a = expr(type);
          expect(',');
          var b = expr(type);
          value = a.ashr(b);
        }
        case "lshr" -> {
          var type = type();
          var a = expr(type);
          expect(',');
          // TODO: inline variable
          var b = expr(type);
          value = a.lshr(b);
        }
        case "getelementptr" -> {
          eat("inbounds");
          var type = type();
          expect(',');
          expect("ptr");
          var ptrVal = expr(Type.PTR);
          var idxs = new ArrayList<Term>();
          while (eat(',')) idxs.add(typeExpr());
          value = getElementPtr(type, ptrVal, idxs);
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
          value = typeExpr();
          expect("to");
          value = value.cast(type());
        }
        case "sext", "fptosi", "sitofp" -> {
          value = typeExpr();
          expect("to");
          value = value.scast(type());
        }
        default -> throw err("unknown instruction");
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
          default -> throw err("unknown branch type");
        }
      }
      default -> throw err("unknown instruction");
    }
  }

  private LlvmParser(String file, byte[] text, Module module) {
    this.file = file;
    this.text = text;

    // First pass, define types along with miscellaneous items that don't depend on other
    // definitions
    reset();
    while (tok != EOF) {
      switch (tok) {
        case LOCAL_ID -> {
          var name = lex1();
          expect('=');
          if (eat("type")) types.put(name, type());
        }
        case WORD -> {
          if (lex1().equals("target")) {
            var t = expect(WORD);
            expect('=');
            if (tok != STRING) throw err("expected string");
            switch (t) {
              case "datalayout" -> datalayout = idem(datalayout);
              case "triple" -> triple = idem(triple);
              default -> throw err(t, "unknown target attribute");
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
    while (tok != EOF) {
      switch (tok) {
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
              if (tok != ')')
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
              var fn = new Function(name, rtype, params, varargs);
              declare(name, fn);
              module.functions.add(fn);
            }
          }
        }
        case GLOBAL_ID -> {
          var name = lex1();
          expect('=');
          linkageType();
          dso();
          eat("unnamed_addr");
          if (tok == WORD)
            switch (tokString) {
              case "constant", "global" -> lex();
            }
          var a = new GlobalVariable(name, type());
          declare(name, a);
          module.vars.add(a);
        }
        default -> lex();
      }
      eol();
    }

    // Third pass, fill in global values and function bodies
    reset();
    while (tok != EOF) {
      // TODO: refactor?
      switch (tok) {
        case WORD -> {
          // Function definition
          if (lex1().equals("define")) {
            linkageType();
            dso();

            // Return type
            type();

            // Name
            var fn = (Function) globals.get(expect(GLOBAL_ID));

            // Parameters
            expect('(');
            var i = 0;
            locals.clear();
            if (tok != ')')
              do {
                if (eat(DOTS)) continue;
                type();
                paramAttr();
                locals.put(expect(LOCAL_ID), fn.params.get(i++));
              } while (eat(','));
            while (!eat('{')) {
              if (tok == EOF) throw err("unexpected end of file");
              lex();
            }

            // Entry block
            var block = new Block();
            fn.entry = block;
            blocks.put(expect(LABEL), block);

            // Body
            while (!eat('}')) {
              if (tok == LABEL) {
                block = block();
                continue;
              }
              instruction(block);
              eol();
            }

            // Phis
            for (var kv : phis.entrySet()) {
              var from = kv.getKey();

              // Terminator instruction needs to follow the phi assignments from this block
              // so get it out of the way for now
              // If the terminator is a conditional branch
              // then the phi assignments for blocks not jumped to on a particular occasion
              // will be redundant but harmless
              var terminator = from.pop();

              // Assignments
              var assign = kv.getValue();
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
          if (tok == WORD)
            switch (tokString) {
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
    if (globals.put(name, a) != null) throw err(name, "duplicate name");
  }

  private void reset() {
    ti = 0;
    lex();
  }

  private void lexQuote() {
    assert text[ti] == '"';
    ti++;
    var sb = new StringBuilder();
    while (text[ti] != '"') {
      int c = text[ti++];
      if (c == '\\') {
        c = Etc.parseHexDigit(text[ti]) << 4 + Etc.parseHexDigit(text[ti + 1]);
        ti += 2;
      }
      sb.append((char) c);
    }
    ti++;
    tokString = sb.toString();
  }

  public static boolean isIdPart(int c) {
    if (Etc.isAlnum(c)) return true;
    return switch (c) {
      case '-', '_', '.', '$' -> true;
      default -> false;
    };
  }

  private void lexId() {
    ti++;
    if (text[ti] == '"') {
      lexQuote();
      return;
    }
    var sb = new StringBuilder();
    do sb.append((char) text[ti++]);
    while (isIdPart(text[ti]));
    tokString = sb.toString();
  }

  private void lexWord() {
    var sb = new StringBuilder();
    do sb.append((char) text[ti++]);
    while (Etc.isAlnum(text[ti]) || text[ti] == '_' || text[ti] == '.');
    tok = WORD;
    if (text[ti] == ':') {
      ti++;
      tok = LABEL;
    }
    tokString = sb.toString();
  }

  private void lex() {
    newline = false;
    for (; ; ) {
      if (ti == text.length) {
        tok = EOF;
        return;
      }
      switch (text[ti]) {
        case ' ', '\r', '\t', '\f' -> {
          ti++;
          continue;
        }
        case '\n' -> {
          ti++;
          newline = true;
          continue;
        }
        case ';' -> {
          do ti++;
          while (text[ti] != '\n');
          continue;
        }
        case '%' -> {
          tok = LOCAL_ID;
          lexId();
        }
        case '@' -> {
          tok = GLOBAL_ID;
          lexId();
        }
        case '$' -> {
          tok = COMDAT_ID;
          lexId();
        }
        case '"' -> {
          tok = STRING;
          lexQuote();
        }
        case 'c' -> {
          if (text[ti + 1] == '"') {
            ti++;
            tok = STRING;
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
          sb.append((char) text[ti++]);
          tok = INT;
          if (text[ti] == 'x') tok = HEX_FLOAT;
          while (Etc.isAlnum(text[ti]) || text[ti] == '.' || Etc.isSign(text[ti])) {
            int c = text[ti++];
            if (!Etc.isDigit(c) && tok == INT) tok = FLOAT;
            sb.append((char) c);
          }
          tokString = sb.toString();
        }
        case '.' -> {
          if (text[ti + 1] == '.' && text[ti + 2] == '.') {
            ti += 3;
            tok = DOTS;
            break;
          }
          ti++;
        }
        default -> tok = text[ti++];
      }
      break;
    }
  }

  private void eol() {
    if (newline) return;
    while (text[ti] != '\n') ti++;
    lex();
  }

  public static Module parse(String file, byte[] text) {
    var module = new Module();
    new LlvmParser(file, text, module);
    return module;
  }
}
