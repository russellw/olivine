package olivine;

public final class ParseException extends RuntimeException {
  ParseException(String file, int line, String source, String msg) {
    super("%s:%d: %s: %s".formatted(file, line, source, msg));
  }

  ParseException(String file, int line, String msg) {
    super("%s:%d: %s".formatted(file, line, msg));
  }
}
