import java.math.BigInteger;

final class DivFloor extends Binary {
  DivFloor(Object arg0, Object arg1) {
    super(arg0, arg1);
  }

  Object apply(BigInteger a, BigInteger b) {
    return Etc.divFloor(a, b);
  }

  Object apply(BigRational a, BigRational b) {
    return a.divFloor(b);
  }
}
