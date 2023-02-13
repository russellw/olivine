import java.math.BigInteger;

final class Round extends Term {
  Round(Object a) {
    super(a);
  }

  Object apply(BigInteger a) {
    return a;
  }

  Object apply(BigRational a) {
    return a.round();
  }
}
