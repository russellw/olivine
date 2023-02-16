import java.io.IOException;

public final class ParseError extends IOException {
  ParseError(String file, int line, String s) {
    super(String.format("%s:%d: %s", file, line, s));
  }
}
