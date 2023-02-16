import java.math.BigInteger;

public final class RemFloor extends Term {
  RemFloor(Object a, Object b) {
    super(a, b);
  }

  Object apply(BigInteger a, BigInteger b) {
    return Etc.remFloor(a, b);
  }

  Object apply(BigRational a, BigRational b) {
    return a.remFloor(b);
  }
}
