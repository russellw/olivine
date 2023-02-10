import java.math.BigInteger;

final class RemFloor extends Binary {
  RemFloor(Object arg0, Object arg1) {
    super(arg0, arg1);
  }

  Object apply(BigInteger a, BigInteger b) {
    return Etc.remFloor(a, b);
  }

  Object apply(BigRational a, BigRational b) {
    return a.remFloor(b);
  }
}
