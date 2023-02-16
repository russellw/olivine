import java.math.BigInteger;

public final class IsRational extends Term {
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
