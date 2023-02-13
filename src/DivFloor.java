import java.math.BigInteger;

final class DivFloor extends Binary {
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
