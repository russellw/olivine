import java.math.BigInteger;

final class DivEuclidean extends Binary {
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
