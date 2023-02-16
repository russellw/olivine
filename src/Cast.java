import java.math.BigInteger;
import java.util.Map;

public final class Cast extends Term {
  private final Type type;

  Object eval(Map<Object, Object> map) {
    var a = Etc.get(map, args[0]);
    if (type.equals(Type.of(a))) return a;

    // Different languages have different conventions on the default rounding mode for
    // converting fractions to integers. TPTP
    // defines it as floor, so that is used here. To use a different rounding mode,
    // explicity round the rational number first,
    // and then convert to integer.
    return switch (type) {
      case IntegerType ignored -> switch (a) {
        case BigRational a1 -> Etc.divFloor(a1.num, a1.den);
        case Real a1 -> Etc.divFloor(a1.val().num, a1.val().den);
        default -> throw new IllegalArgumentException(toString());
      };
      case RationalType ignored -> switch (a) {
        case BigInteger a1 -> new BigRational(a1);
        case Real a1 -> a1.val();
        default -> throw new IllegalArgumentException(toString());
      };
      case RealType ignored -> switch (a) {
        case BigInteger a1 -> new Real(new BigRational(a1));
        case BigRational a1 -> new Real(a1);
        default -> throw new IllegalArgumentException(toString());
      };
      default -> throw new IllegalArgumentException(toString());
    };
  }

  @Override
  Term remake(Object[] v) {
    return new Cast(type, v[0]);
  }

  Type type() {
    return type;
  }

  Cast(Type type, Object a) {
    super(a);
    this.type = type;
  }
}
