import java.math.BigInteger;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

public final class Etc {
  private static long startTime;

  static Object[] remove(Object[] v, int i) {
    var r = new Object[v.length - 1];
    System.arraycopy(v, 0, r, 0, i);
    System.arraycopy(v, i + 1, r, i, r.length - i);
    return r;
  }

  static <T> List<List<T>> cartesianProduct(List<List<T>> vs) {
    var js = new int[vs.size()];
    var rs = new ArrayList<List<T>>();
    cartesianProduct(vs, 0, js, rs);
    return rs;
  }

  private static <T> void cartesianProduct(List<List<T>> vs, int i, int[] js, List<List<T>> rs) {
    if (i == js.length) {
      var r = new ArrayList<T>();
      for (i = 0; i < js.length; i++) r.add(vs.get(i).get(js[i]));
      rs.add(r);
      return;
    }
    for (js[i] = 0; js[i] < vs.get(i).size(); js[i]++) cartesianProduct(vs, i + 1, js, rs);
  }

  static String ext(String file) {
    var i = file.lastIndexOf('.');
    if (i < 0) return "";
    return file.substring(i + 1);
  }

  static void startTimer() {
    startTime = System.currentTimeMillis();
  }

  @SuppressWarnings("DuplicateBranchesInSwitch")
  static boolean constant(Object a) {
    return switch (a) {
      case Term ignored -> false;
      case Fn ignored -> false;
      case Variable ignored -> false;
      default -> true;
    };
  }

  static void endTimer() {
    System.out.printf("%10.3f\n", (System.currentTimeMillis() - startTime) * 0.001);
  }

  @SuppressWarnings("unused")
  static void dbg(Object a) {
    System.out.printf("%s: %s\n", Thread.currentThread().getStackTrace()[2], a);
  }

  static BigInteger divEuclidean(BigInteger a, BigInteger b) {
    var q = a.divide(b);
    if (a.signum() < 0 && !q.multiply(b).equals(a)) q = q.subtract(BigInteger.valueOf(b.signum()));
    return q;
  }

  static BigInteger divFloor(BigInteger a, BigInteger b) {
    var qr = a.divideAndRemainder(b);
    var q = qr[0];
    if (a.signum() < 0 != b.signum() < 0 && qr[1].signum() != 0) q = q.subtract(BigInteger.ONE);
    return q;
  }

  static BigInteger remEuclidean(BigInteger a, BigInteger b) {
    // The BigInteger 'mod' function cannot be used, as it rejects negative inputs
    var r = a.remainder(b);
    if (r.signum() < 0) r = r.add(b.abs());
    return r;
  }

  static BigInteger remFloor(BigInteger a, BigInteger b) {
    return a.subtract(divFloor(a, b).multiply(b));
  }

  static Object get(Map<Object, Object> map, Object key) {
    if (constant(key)) return key;
    var val = map.get(key);
    assert val != null;
    return val;
  }

  static boolean isDigit(int c) {
    return '0' <= c && c <= '9';
  }

  public static boolean isUpper(int c) {
    return 'A' <= c && c <= 'Z';
  }

  static boolean isAlpha(int c) {
    return isLower(c) || isUpper(c);
  }

  static boolean isAlnum(int c) {
    return isAlpha(c) || isDigit(c);
  }

  static boolean isLower(int c) {
    return 'a' <= c && c <= 'z';
  }

  static String tptp() {
    var s = System.getenv("TPTP");
    if (s == null) throw new IllegalStateException("TPTP environment variable not set");
    return s;
  }
}
