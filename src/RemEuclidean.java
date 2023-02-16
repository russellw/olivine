import java.math.BigInteger;

public final class RemEuclidean extends Term {
  RemEuclidean(Object a, Object b) {
    super(a, b);
  }

  Object apply(BigInteger a, BigInteger b) {
    return Etc.remEuclidean(a, b);
  }

  Object apply(BigRational a, BigRational b) {
    return a.remEuclidean(b);
  }
}
