package olivine;

import java.nio.file.Path;

public final class Etc {
  private Etc() {}

  public static int hexDigit(int n) {
    assert n >= 0;
    if (n < 10) return '0' + n;
    assert n < 16;
    return 'a' - 10 + n;
  }

  public static int parseHexDigit(int c) {
    if (isDigit(c)) return c - '0';
    if ('a' <= c && c <= 'f') return c - 'a' + 10;
    if ('A' <= c && c <= 'F') return c - 'A' + 10;
    throw new IllegalArgumentException(Integer.toString(c));
  }

  public static boolean isSign(int c) {
    return c == '-' || c == '+';
  }

  public static boolean isPrint(int c) {
    return ' ' <= c && c < 127;
  }

  public static boolean isDigit(int c) {
    return '0' <= c && c <= '9';
  }

  public static boolean isUpper(int c) {
    return 'A' <= c && c <= 'Z';
  }

  public static boolean isAlpha(int c) {
    return isLower(c) || isUpper(c);
  }

  public static boolean isAlnum(int c) {
    return isAlpha(c) || isDigit(c);
  }

  public static boolean isLower(int c) {
    return 'a' <= c && c <= 'z';
  }

  public static String extension(String file) {
    var i = file.lastIndexOf('.');
    if (i < 0) return "";
    return file.substring(i + 1);
  }

  public static String withoutDirectory(String file) {
    return Path.of(file).getFileName().toString();
  }

  public static String withoutExtension(String file) {
    var i = file.lastIndexOf('.');
    if (i < 0) return file;
    return file.substring(0, i);
  }

  public static String baseName(String file) {
    return withoutExtension(withoutDirectory(file));
  }
}
