import java.math.BigInteger;

final class IsInteger extends Unary {
  IsInteger(Object arg) {
    super(arg);
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
