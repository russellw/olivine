import java.math.BigInteger;

final class DivEuclidean extends Binary {
  DivEuclidean(Object arg0, Object arg1) {
    super(arg0, arg1);
  }

  Object apply(BigInteger a, BigInteger b) {
    return Etc.divEuclidean(a, b);
  }

  Object apply(BigRational a, BigRational b) {
    return a.divEuclidean(b);
  }
}
