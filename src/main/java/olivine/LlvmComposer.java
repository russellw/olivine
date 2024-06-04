package olivine;

import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;

public final class LlvmComposer {
  private final ByteArrayOutputStream stream = new ByteArrayOutputStream();
  private final Map<Object, Integer> locals = new HashMap<>();

  public static String scast(Term a) {
    var from = a.get(0).type();
    var to = a.type();

    // From int
    if (from.isInt()) {
      if (to.isFloat()) return "sitofp";
      return "sext";
    }

    // From float
    return "fptosi";
  }

  public static String cast(Term a) {
    var from = a.get(0).type();
    var to = a.type();

    // Same type
    // TODO: when is this actually used?
    if (from.equals(to)) return "bitcast";

    // Pointer <-> int
    if (from == Type.PTR) {
      if (!to.isInt()) throw new IllegalArgumentException(to.toString());
      return "ptrtoint";
    }
    if (to == Type.PTR) {
      if (!from.isInt()) throw new IllegalArgumentException(from.toString());
      return "inttoptr";
    }

    // Both numbers, so size matters
    var fromBits = from.bits();
    var toBits = to.bits();

    // From int
    if (from.isInt()) {
      if (to.isFloat()) return "uitofp";

      // To int
      if (fromBits < toBits) return "zext";
      assert fromBits > toBits;
      return "trunc";
    }

    // From float
    if (!from.isFloat()) throw new IllegalArgumentException(from.toString());
    if (to.isInt()) return "fptoui";

    // To float
    // TODO: what happens when float types are the same size?
    if (fromBits < toBits) return "fpext";
    assert fromBits > toBits;
    return "fptrunc";
  }

  private void nameLocal(Object o) {
    assert !locals.containsKey(o);
    locals.put(o, locals.size());
  }

  private void print(int c) {
    stream.write(c);
  }

  private void print(Type type) {
    print(type.toString());
  }

  private void print(String s) {
    stream.writeBytes(s.getBytes(StandardCharsets.UTF_8));
  }

  private void id(String s) {
    if (isId(s)) {
      print(s);
      return;
    }
    print('"');
    for (var i = 0; i < s.length(); i++) {
      int c = s.charAt(i);
      if (Etc.isPrint(c) && c != '"' && c != '\\') {
        print(c);
        continue;
      }
      print('\\');
      print(Etc.hexDigit(c >> 4));
      print(Etc.hexDigit(c & 0xf));
    }
    print('"');
  }

  public static boolean isId(String s) {
    if (s.isEmpty()) return false;
    if (Etc.isDigit(s.charAt(0))) return false;
    for (var i = 0; i < s.length(); i++) if (!LlvmParser.isIdPart(s.charAt(i))) return false;
    return true;
  }

  private LlvmComposer(Module module) {}

  public static byte[] compose(Module module) {
    return new LlvmComposer(module).stream.toByteArray();
  }
}
