package olivine;

import java.io.ByteArrayOutputStream;

public final class LlvmComposer {
  private final ByteArrayOutputStream stream = new ByteArrayOutputStream();

  public static boolean isId(String s) {
    if (s.isEmpty()) return false;
    if (Etc.isDigit(s.charAt(0))) return false;
    for (var i = 0; i < s.length(); i++) if (!LlvmParser.isIdPart(s.charAt(i))) return false;
    return true;
  }
}
