import java.math.BigInteger;

public final class Round extends Term {
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
