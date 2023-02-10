import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

public final class DimacsParser {
  // Problem state
  private final Map<String, Fn> variables = new HashMap<>();

  // File state
  private final String file;
  private final InputStream stream;
  private int c;
  private int line = 1;
  private int tok;
  private String tokString;

  private ParseError err(String s) {
    return new ParseError(file, line, s);
  }

  // Tokenizer
  private void readc() throws IOException {
    c = stream.read();
  }

  private void readc(StringBuilder sb) throws IOException {
    sb.append((char) c);
    readc();
  }

  private void lex() throws IOException {
    for (; ; ) {
      tok = c;
      switch (c) {
        case 'c' -> {
          do readc();
          while (c != '\n' && c >= 0);
          continue;
        }
        case '\n' -> {
          line++;
          readc();
          continue;
        }
        case ' ', '\f', '\r', '\t' -> {
          readc();
          continue;
        }
        case '1', '2', '3', '4', '5', '6', '7', '8', '9' -> {
          var sb = new StringBuilder();
          do readc(sb);
          while (Etc.isDigit(c));
          tok = '9';
          tokString = sb.toString();
        }
        default -> readc();
      }
      return;
    }
  }

  // parser
  private Fn variable() throws IOException {
    // variables in propositional logic are (nullary) functions in first-order logic
    var a = variables.get(tokString);
    if (a == null) {
      a = new Fn(BooleanType.instance, tokString);
      variables.put(tokString, a);
    }
    lex();
    return a;
  }

  // top level
  private DimacsParser(String file, InputStream stream, CNF cnf) throws IOException {
    this.file = file;
    this.stream = stream;
    c = stream.read();
    lex();

    // problem statistics
    if (tok == 'p') {
      while (0 <= c && c <= ' ') c = stream.read();

      // cnf
      if (c != 'c') throw err("expected 'cnf'");
      c = stream.read();
      if (c != 'n') throw err("expected 'cnf'");
      c = stream.read();
      if (c != 'f') throw err("expected 'cnf'");
      c = stream.read();
      lex();

      // count of variables
      if (tok != '9') throw err("expected integer");
      lex();

      // count of clauses
      if (tok != '9') throw err("expected integer");
      lex();
    }

    // clauses
    var literals = new ArrayList<>();
    for (; ; )
      switch (tok) {
        case -1 -> {
          if (!literals.isEmpty()) cnf.add(new Or(literals.toArray()));
          return;
        }
        case '-' -> {
          lex();
          if (tok != '9') throw err("expected variable");
          literals.add(new Not(variable()));
        }
        case '9' -> literals.add(variable());
        case '0' -> {
          lex();
          cnf.add(new Or(literals.toArray()));
          literals.clear();
        }
        default -> throw err("syntax error");
      }
  }

  static void parse(String file, InputStream stream, CNF cnf) throws IOException {
    new DimacsParser(file, stream, cnf);
  }
}
