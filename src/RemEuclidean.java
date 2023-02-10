import java.math.BigInteger;

final class RemEuclidean extends Binary {
  RemEuclidean(Object arg0, Object arg1) {
    super(arg0, arg1);
  }

  Object apply(BigInteger a, BigInteger b) {
    return Etc.remEuclidean(a, b);
  }

  Object apply(BigRational a, BigRational b) {
    return a.remEuclidean(b);
  }
}
