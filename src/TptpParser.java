import java.io.*;
import java.math.BigInteger;
import java.nio.file.Path;
import java.util.*;

public final class TptpParser {
  // Tokens
  private static final int DEFINED_WORD = -2;
  private static final int DISTINCT_OBJECT = -3;
  private static final int EQV = -4;
  private static final int IMPLIES = -5;
  private static final int IMPLIESR = -6;
  private static final int INTEGER = -7;
  private static final int NAND = -8;
  private static final int NOT_EQUALS = -9;
  private static final int NOR = -10;
  private static final int RATIONAL = -11;
  private static final int REAL = -12;
  private static final int VAR = -13;
  private static final int WORD = -14;
  private static final int XOR = -15;

  // Problem state
  private final CNF cnf;
  private final Map<String, OpaqueType> types;
  private final Map<String, DistinctObject> distinctObjects;
  private final Map<String, Fn> globals;

  // File state
  private final String file;
  private final InputStream stream;
  private final Set<String> select;
  private int c;
  private int line = 1;
  private int tok;
  private String tokString;
  private final Map<String, Variable> free = new HashMap<>();

  private static boolean isIdPart(int c) {
    return Etc.isAlnum(c) || c == '_';
  }

  private ParseError err(String s) {
    return new ParseError(file, line, s);
  }

  // Tokenizer
  private void readc(StringBuilder sb) throws IOException {
    sb.append((char) c);
    c = stream.read();
  }

  private void lexQuote() throws IOException {
    var quote = c;
    var sb = new StringBuilder();
    c = stream.read();
    while (c != quote) {
      if (c < ' ') throw err("unclosed quote");
      if (c == '\\') c = stream.read();
      readc(sb);
    }
    c = stream.read();
    tokString = sb.toString();
  }

  private void lex() throws IOException {
    for (; ; ) {
      tok = c;
      switch (c) {
        case '\n' -> {
          line++;
          c = stream.read();
          continue;
        }
        case ' ', '\f', '\r', '\t' -> {
          c = stream.read();
          continue;
        }
        case '!' -> {
          c = stream.read();
          if (c == '=') {
            c = stream.read();
            tok = NOT_EQUALS;
          }
        }
        case '"' -> {
          lexQuote();
          tok = DISTINCT_OBJECT;
        }
        case '$' -> {
          c = stream.read();
          var sb = new StringBuilder();
          while (isIdPart(c)) readc(sb);
          tok = DEFINED_WORD;
          tokString = sb.toString();
        }
        case '%' -> {
          do c = stream.read();
          while (c != '\n' && c >= 0);
          continue;
        }
        case '+', '-', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' -> {
          var sb = new StringBuilder();
          do readc(sb);
          while (Etc.isDigit(c));
          switch (c) {
            case '.' -> {
              do readc(sb);
              while (Etc.isDigit(c));
            }
            case '/' -> {
              do readc(sb);
              while (Etc.isDigit(c));
              tok = RATIONAL;
              tokString = sb.toString();
              return;
            }
            case 'E', 'e' -> {}
            default -> {
              tok = INTEGER;
              tokString = sb.toString();
              return;
            }
          }
          if (c == 'e' || c == 'E') readc(sb);
          if (c == '+' || c == '-') readc(sb);
          while (Etc.isDigit(c)) readc(sb);
          tok = REAL;
          tokString = sb.toString();
        }
        case '/' -> {
          c = stream.read();
          if (c != '*') throw err("expected '*'");
          c = stream.read();
          for (; ; ) {
            switch (c) {
              case -1 -> throw err("unclosed block comment");
              case '*' -> c = stream.read();
              default -> {
                c = stream.read();
                continue;
              }
            }
            if (c == '/') break;
          }
          c = stream.read();
          continue;
        }
        case '<' -> {
          c = stream.read();
          switch (c) {
            case '=' -> {
              c = stream.read();
              if (c == '>') {
                c = stream.read();
                tok = EQV;
                break;
              }
              tok = IMPLIESR;
            }
            case '~' -> {
              c = stream.read();
              if (c == '>') {
                c = stream.read();
                tok = XOR;
                break;
              }
              throw err("expected '>'");
            }
          }
        }
        case '=' -> {
          c = stream.read();
          if (c == '>') {
            c = stream.read();
            tok = IMPLIES;
          }
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
            'Z' -> {
          var sb = new StringBuilder();
          do readc(sb);
          while (isIdPart(c));
          tok = VAR;
          tokString = sb.toString();
        }
        case '\'' -> {
          lexQuote();
          if (tokString.length() == 0) throw err("empty word");
          tok = WORD;
        }
        case 'a',
            'b',
            'c',
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
            'z' -> {
          var sb = new StringBuilder();
          do readc(sb);
          while (isIdPart(c));
          tok = WORD;
          tokString = sb.toString();
        }
        case '~' -> {
          c = stream.read();
          switch (c) {
            case '&' -> {
              c = stream.read();
              tok = NAND;
            }
            case '|' -> {
              c = stream.read();
              tok = NOR;
            }
          }
        }
        default -> c = stream.read();
      }
      return;
    }
  }

  // parser
  private boolean eat(int k) throws IOException {
    if (tok == k) {
      lex();
      return true;
    }
    return false;
  }

  private void expect(int k) throws IOException {
    if (!eat(k)) throw err(String.format("expected '%c'", k));
  }

  private String word() throws IOException {
    if (tok != WORD) throw err("expected word");
    var s = tokString;
    lex();
    return s;
  }

  // types
  private Type atomicType() throws IOException {
    var s = tokString;
    switch (tok) {
      case '!', '[' -> throw new Inappropriate();
      case DEFINED_WORD -> {
        lex();
        return switch (s) {
          case "o" -> BooleanType.instance;
          case "i" -> IndividualType.instance;
          case "int" -> IntegerType.instance;
          case "rat" -> RationalType.instance;
          case "real" -> RealType.instance;
          case "tType" -> throw new Inappropriate();
          default -> throw err(String.format("'$%s': unknown type", s));
        };
      }
      case WORD -> {
        lex();
        var type = types.get(s);
        if (type == null) {
          type = new OpaqueType(s);
          types.put(s, type);
        }
        return type;
      }
    }
    throw err("expected type");
  }

  private Type topLevelType() throws IOException {
    if (eat('(')) {
      do if (atomicType() == BooleanType.instance) throw new Inappropriate();
      while (eat('*'));
      expect(')');
      expect('>');
      return atomicType();
    }
    var type = atomicType();
    if (eat('>')) {
      if (type == BooleanType.instance) throw new Inappropriate();
      return atomicType();
    }
    return type;
  }

  // terms
  private Fn fn(String name) {
    var a = globals.get(name);
    if (a == null) {
      a = new Fn(null, name);
      globals.put(name, a);
    }
    return a;
  }

  private Object arg0(Map<String, Variable> bound) throws IOException {
    expect('(');
    var a = atomicTerm(bound);
    expect(',');
    return a;
  }

  private Object argN(Map<String, Variable> bound) throws IOException {
    var a = atomicTerm(bound);
    expect(')');
    return a;
  }

  private Object arg(Map<String, Variable> bound) throws IOException {
    expect('(');
    return argN(bound);
  }

  private Object[] args(Map<String, Variable> bound) throws IOException {
    expect('(');
    var v = new ArrayList<>();
    do v.add(atomicTerm(bound));
    while (eat(','));
    expect(')');
    return v.toArray();
  }

  private Object atomicTerm(Map<String, Variable> bound) throws IOException {
    var k = tok;
    var s = tokString;
    lex();
    return switch (k) {
      case '!', '?', '[', '(' -> throw new Inappropriate();
      case DEFINED_WORD -> switch (s) {
        case "ceiling" -> new Ceil(arg(bound));
        case "difference" -> {
          var a = arg0(bound);
          yield new Sub(a, argN(bound));
        }
        case "distinct" -> {
          var v = args(bound);
          for (var a : v) IndividualType.instance.setDefault(a);
          var inequalities = new ArrayList<>();
          for (var i = 0; i < v.length; i++)
            for (var j = 0; j < v.length; j++)
              if (i != j) inequalities.add(new Not(new Eq(v[i], v[j])));
          yield new And(inequalities.toArray());
        }
        case "false" -> false;
        case "floor" -> new Floor(arg(bound));
        case "greater" -> {
          var a = arg0(bound);
          yield new Lt(argN(bound), a);
        }
        case "greatereq" -> {
          var a = arg0(bound);
          yield new Le(argN(bound), a);
        }
        case "is_int" -> new IsInteger(arg(bound));
        case "is_rat" -> new IsRational(arg(bound));
        case "less" -> {
          var a = arg0(bound);
          yield new Lt(a, argN(bound));
        }
        case "lesseq" -> {
          var a = arg0(bound);
          yield new Le(a, argN(bound));
        }
        case "product" -> {
          var a = arg0(bound);
          yield new Mul(a, argN(bound));
        }
        case "quotient" -> {
          var a = arg0(bound);
          yield new Div(a, argN(bound));
        }
        case "quotient_e" -> {
          var a = arg0(bound);
          yield new DivEuclidean(a, argN(bound));
        }
        case "quotient_f" -> {
          var a = arg0(bound);
          yield new DivFloor(a, argN(bound));
        }
        case "quotient_t" -> {
          var a = arg0(bound);
          yield new DivTruncate(a, argN(bound));
        }
        case "remainder_e" -> {
          var a = arg0(bound);
          yield new RemEuclidean(a, argN(bound));
        }
        case "remainder_f" -> {
          var a = arg0(bound);
          yield new RemFloor(a, argN(bound));
        }
        case "remainder_t" -> {
          var a = arg0(bound);
          yield new RemTruncate(a, argN(bound));
        }
        case "round" -> new Round(arg(bound));
        case "sum" -> {
          var a = arg0(bound);
          yield new Add(a, argN(bound));
        }
        case "to_int" -> new Cast(IntegerType.instance, arg(bound));
        case "to_rat" -> new Cast(RationalType.instance, arg(bound));
        case "to_real" -> new Cast(RealType.instance, arg(bound));
        case "true" -> true;
        case "truncate" -> new Truncate(arg(bound));
        case "uminus" -> new Neg(arg(bound));
        case "ite" -> throw new Inappropriate();
        default -> throw err(String.format("'$%s': unknown word", s));
      };
      case DISTINCT_OBJECT -> {
        var a = distinctObjects.get(s);
        if (a == null) {
          a = new DistinctObject(s);
          distinctObjects.put(s, a);
        }
        yield a;
      }
      case INTEGER -> new BigInteger(s);
      case RATIONAL -> BigRational.of(s);
      case REAL -> new Real(BigRational.ofDecimal(s));
      case VAR -> {
        if (bound == null) {
          var a = free.get(s);
          if (a == null) {
            a = new Variable(IndividualType.instance);
            free.put(s, a);
          }
          yield a;
        }
        var a = bound.get(s);
        if (a == null) throw err(String.format("'%s': unknown variable", s));
        yield a;
      }
      case WORD -> {
        var f = fn(s);
        if (eat('(')) {
          var v = new ArrayList<>();
          do {
            var a = atomicTerm(bound);
            IndividualType.instance.setDefault(a);
            v.add(a);
          } while (eat(','));
          expect(')');
          yield new Call(f, v.toArray());
        }
        yield f;
      }
      default -> throw err("expected term");
    };
  }

  private Eq infixEquals(Map<String, Variable> bound, Object a) throws IOException {
    IndividualType.instance.setDefault(a);
    lex();
    var b = atomicTerm(bound);
    IndividualType.instance.setDefault(b);
    return new Eq(a, b);
  }

  private Object infixUnary(Map<String, Variable> bound) throws IOException {
    var a = atomicTerm(bound);
    return switch (tok) {
      case '=' -> infixEquals(bound, a);
      case NOT_EQUALS -> new Not(infixEquals(bound, a));
      default -> a;
    };
  }

  private Variable[] quant(Map<String, Variable> bound) throws IOException {
    if (bound == null) throw err("quantifier in cnf");
    lex();
    expect('[');
    var v = new ArrayList<Variable>();
    do {
      if (tok != VAR) throw err("expected variable");
      var name = tokString;
      lex();
      Type type = IndividualType.instance;
      if (eat(':')) {
        type = atomicType();
        if (type == BooleanType.instance) throw new Inappropriate();
      }
      var x = new Variable(type);
      v.add(x);
      bound.put(name, x);
    } while (eat(','));
    expect(']');
    expect(':');
    return v.toArray(new Variable[0]);
  }

  private Object unary(Map<String, Variable> bound) throws IOException {
    switch (tok) {
      case '(' -> {
        lex();
        var a = logicFormula(bound);
        expect(')');
        return a;
      }
      case '~' -> {
        lex();
        return new Not(unary(bound));
      }
      case '!' -> {
        bound = new HashMap<>(bound);
        return new All(quant(bound), unary(bound));
      }
      case '?' -> {
        bound = new HashMap<>(bound);
        return new Exists(quant(bound), unary(bound));
      }
    }
    var a = infixUnary(bound);
    BooleanType.instance.setRequired(a);
    return a;
  }

  private Object[] logicFormula1(Map<String, Variable> bound, Object a) throws IOException {
    var k = tok;
    var v = new ArrayList<>();
    v.add(a);
    while (eat(k)) v.add(unary(bound));
    return v.toArray();
  }

  private Object logicFormula(Map<String, Variable> bound) throws IOException {
    var a = unary(bound);
    return switch (tok) {
      case '&' -> new And(logicFormula1(bound, a));
      case '|' -> new Or(logicFormula1(bound, a));
      case EQV -> {
        lex();
        yield new Eqv(a, unary(bound));
      }
      case IMPLIES -> {
        lex();
        yield Term.implies(a, unary(bound));
      }
      case IMPLIESR -> {
        lex();
        yield Term.implies(unary(bound), a);
      }
      case NAND -> {
        lex();
        yield new Not(new And(a, unary(bound)));
      }
      case NOR -> {
        lex();
        yield new Not(new Or(a, unary(bound)));
      }
      case XOR -> {
        lex();
        yield new Not(new Eqv(a, unary(bound)));
      }
      default -> a;
    };
  }

  // top level
  private String formulaName() throws IOException {
    switch (tok) {
      case WORD, INTEGER -> {
        var s = tokString;
        lex();
        return s;
      }
      default -> throw err("expected formula name");
    }
  }

  private boolean selecting(String name) {
    if (select == null) return true;
    return select.contains(name);
  }

  private void collect(String name, Object a) {
    if (!selecting(name)) return;
    // TODO do we need additional type checking?
    BooleanType.instance.setRequired(a);
    cnf.add(a);
  }

  private void skip() throws IOException {
    switch (tok) {
      case '(' -> {
        lex();
        while (!eat(')')) skip();
      }
      case -1 -> throw err("unclosed '('");
      default -> lex();
    }
  }

  private TptpParser(
      String file,
      InputStream stream,
      CNF cnf,
      Map<String, OpaqueType> types,
      Map<String, DistinctObject> distinctObjects,
      Map<String, Fn> globals,
      Set<String> select)
      throws IOException {
    this.file = file;
    this.stream = stream;
    this.cnf = cnf;
    this.types = types;
    this.distinctObjects = distinctObjects;
    this.globals = globals;
    this.select = select;
    c = stream.read();
    lex();
    try {
      while (tok != -1) {
        var s = word();
        expect('(');
        var name = formulaName();
        switch (s) {
          case "cnf" -> {
            expect(',');

            word();
            expect(',');

            // we could treat CNF input specially as clauses, but it is equally correct and simpler
            // to just treat it as formulas
            var a = All.quantify(logicFormula(null));
            collect(name, a);
          }
          case "fof", "tff", "tcf" -> {
            expect(',');

            var role = word();
            expect(',');

            if (role.equals("type")) {
              // either naming a type, or typing a global
              var parens = 0;
              while (eat('(')) parens++;

              name = word();
              expect(':');

              if (tok == DEFINED_WORD && tokString.equals("tType")) {
                lex();
                if (tok == '>')
                  // this is some higher-order construct that Olivine doesn't understand
                  throw new Inappropriate();
                // Otherwise, the symbol will be simply used as the name of a type. No particular
                // action is
                // required at this point, so accept this and move on.
              } else
                // The symbol is the name of a global  with the specified type.
                topLevelType().setRequired(fn(name));

              while (parens-- > 0) expect(')');
              break;
            }

            // formula
            var a = logicFormula(Map.of());
            assert Variable.freeVariables(a).isEmpty();
            if (selecting(name)) {
              if (role.equals("conjecture")) a = new Not(a);
              collect(name, a);
            }
          }
          case "thf" -> throw new Inappropriate();
          case "include" -> {
            var file1 = Path.of(Etc.tptp(), name).toString();
            var select1 = select;
            if (eat(',')) {
              if (tok == WORD && tokString.equals("all")) lex();
              else {
                expect('[');
                select1 = new HashSet<>();
                do {
                  var name1 = formulaName();
                  if (selecting(name1)) select1.add(name1);
                } while (eat(','));
                expect(']');
              }
            }
            try (var stream1 = new BufferedInputStream(new FileInputStream(file1))) {
              new TptpParser(file1, stream1, cnf, types, distinctObjects, globals, select1);
            }
          }
          default -> throw err(String.format("'%s': unknown language", s));
        }
        if (tok == ',') do skip(); while (tok != ')');
        expect(')');
        expect('.');
      }
    } catch (TypeError e) {
      throw err(e.getMessage());
    }
  }

  static void parse(String file, InputStream stream, CNF cnf) throws IOException {
    new TptpParser(file, stream, cnf, new HashMap<>(), new HashMap<>(), new HashMap<>(), null);
  }
}
