import java.math.BigInteger;

final class Round extends Unary {
  Round(Object arg) {
    super(arg);
  }

  Object apply(BigInteger a) {
    return a;
  }

  Object apply(BigRational a) {
    return a.round();
  }
}
