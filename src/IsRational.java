import java.math.BigInteger;

final class IsRational extends Unary {
  IsRational(Object arg) {
    super(arg);
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
