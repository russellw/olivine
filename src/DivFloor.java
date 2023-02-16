import java.math.BigInteger;

public final class DivFloor extends Term {
  DivFloor(Object a, Object b) {
    super(a, b);
  }

  Object apply(BigInteger a, BigInteger b) {
    return Etc.divFloor(a, b);
  }

  Object apply(BigRational a, BigRational b) {
    return a.divFloor(b);
  }
}
