import java.math.BigInteger;
import java.util.Map;
import java.util.function.UnaryOperator;

final class Cast extends Unary {
  private final Type type;

  Object eval(Map<Object, Object> map) {
    var a0 = Etc.get(map, args[0]);
    if (type.equals(Type.of(a0))) return a0;

    // Different languages have different conventions on the default rounding mode for
    // converting fractions to integers. TPTP
    // defines it as floor, so that is used here. To use a different rounding mode,
    // explicity round the rational number first,
    // and then convert to integer.
    return switch (type) {
      case IntegerType ignored -> switch (a0) {
        case BigRational a -> Etc.divFloor(a.num, a.den);
        case Real a -> Etc.divFloor(a.val().num, a.val().den);
        default -> throw new IllegalArgumentException(toString());
      };
      case RationalType ignored -> switch (a0) {
        case BigInteger a -> new BigRational(a);
        case Real a -> a.val();
        default -> throw new IllegalArgumentException(toString());
      };
      case RealType ignored -> switch (a0) {
        case BigInteger a -> new Real(new BigRational(a));
        case BigRational a -> new Real(a);
        default -> throw new IllegalArgumentException(toString());
      };
      default -> throw new IllegalArgumentException(toString());
    };
  }

  Object mapLeaves(UnaryOperator<Object> f) {
    return new Cast(type, mapLeaves(f, args[0]));
  }

  Type type() {
    return type;
  }

  Cast(Type type, Object a) {
    super(a);
    this.type = type;
  }
}
