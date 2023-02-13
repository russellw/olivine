import java.math.BigInteger;

final class IsRational extends Term {
  IsRational(Object a) {
    super(a);
  }

  Object apply(BigRational a) {
    return true;
  }

  Object apply(BigInteger a) {
    return true;
  }

  Type type() {
    return BooleanType.instance;
  }
}
