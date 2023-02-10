import java.math.BigInteger;

final class Floor extends Unary {
  Floor(Object arg) {
    super(arg);
  }

  Object apply(BigInteger a) {
    return a;
  }

  Object apply(BigRational a) {
    return a.floor();
  }
}
