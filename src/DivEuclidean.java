import java.math.BigInteger;

public final class DivEuclidean extends Term {
  DivEuclidean(Object a, Object b) {
    super(a, b);
  }

  Object apply(BigInteger a, BigInteger b) {
    return Etc.divEuclidean(a, b);
  }

  Object apply(BigRational a, BigRational b) {
    return a.divEuclidean(b);
  }
}
