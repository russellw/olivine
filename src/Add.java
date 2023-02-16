import java.math.BigInteger;

public final class Add extends Term {
  Add(Object a, Object b) {
    super(a, b);
  }

  Object apply(int a, int b) {
    return a + b;
  }

  Object apply(BigInteger a, BigInteger b) {
    return a.add(b);
  }

  Object apply(BigRational a, BigRational b) {
    return a.add(b);
  }
}
