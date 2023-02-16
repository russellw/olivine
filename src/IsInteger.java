import java.math.BigInteger;

public final class IsInteger extends Term {
  IsInteger(Object a) {
    super(a);
  }

  Object apply(BigRational a) {
    return a.den.equals(BigInteger.ONE);
  }

  Object apply(BigInteger a) {
    return true;
  }

  Type type() {
    return BooleanType.instance;
  }
}
