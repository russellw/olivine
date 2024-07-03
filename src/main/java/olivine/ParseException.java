package olivine;

public final class ParseException extends RuntimeException {
  public ParseException(String file, int line, String cause, String msg) {
    super("%s:%d: '%s': %s".formatted(file, line, cause, msg));
  }

  public ParseException(String file, int line, String msg) {
    super("%s:%d: %s".formatted(file, line, msg));
  }
}
