import java.math.BigInteger;

final class Floor extends Term {
  Floor(Object a) {
    super(a);
  }

  Object apply(BigInteger a) {
    return a;
  }

  Object apply(BigRational a) {
    return a.floor();
  }
}
