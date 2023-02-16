import java.math.BigInteger;
import java.util.HashMap;

public class RoundTest {
  static void test(Object a, Object r) {
    var b = new Round(a);
    assert b.eval(new HashMap<>()).equals(r);
  }

  public static void main(String[] args) {
    test(BigInteger.ONE, BigInteger.ONE);
    test(BigRational.of("0/10"), BigRational.of("0"));
    test(BigRational.of("1/10"), BigRational.of("0"));
    test(BigRational.of("4/10"), BigRational.of("0"));
    test(BigRational.of("6/10"), BigRational.of("1"));
    test(BigRational.of("9/10"), BigRational.of("1"));
    test(BigRational.of("10/10"), BigRational.of("1"));
  }
}
