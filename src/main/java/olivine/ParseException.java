package olivine;

public final class ParseException extends RuntimeException {
  ParseException(String file, int line, String cause, String msg) {
    super("%s:%d: %s: %s".formatted(file, line, cause, msg));
  }

  ParseException(String file, int line, String msg) {
    super("%s:%d: %s".formatted(file, line, msg));
  }
}
