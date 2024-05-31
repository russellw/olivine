package olivine;

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
        return Type.fn(type, params, varargs);
      }
    }
    return type;
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
