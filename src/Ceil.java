import java.math.BigInteger;

public final class Ceil extends Term {
  Ceil(Object a) {
    super(a);
  }

  Object apply(BigInteger a) {
    return a;
  }

  Object apply(BigRational a) {
    return a.ceil();
  }
}
