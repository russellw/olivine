package olivine;

import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

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

  private LlvmParser(String file, byte[] text, Module module) {
    this.file = file;
    this.text = text;

    reset();
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
