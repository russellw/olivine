import java.math.BigInteger;

public abstract class Type {
  @SuppressWarnings("DuplicateBranchesInSwitch")
  static Type of(Object a) {
    return switch (a) {
      case Boolean ignored -> BooleanType.instance;
      case BigInteger ignored -> IntegerType.instance;
      case Integer ignored -> IntType.instance;
      case BigRational ignored -> RationalType.instance;
      case Real ignored -> RealType.instance;
      case DistinctObject ignored -> IndividualType.instance;
      case Variable a1 -> a1.type;
      case Fn a1 -> a1.type();
      case Term a1 -> a1.type();
      case Quantifier ignored -> BooleanType.instance;
      default -> throw new IllegalArgumentException(a.toString());
    };
  }

  final String descriptor() {
    var s = toString();
    if (s.length() == 1) return s;
    return 'L' + s + ';';
  }

  final void setDefault(Object a) {
    switch (a) {
      case Fn a1 -> {
        if (a1.rtype == null) a1.rtype = this;
      }
      case Call a1 -> setDefault(a1.fn);
      default -> {}
    }
  }

  final void setRequired(Object a) {
    setDefault(a);
    if (!equals(of(a))) throw new TypeError(String.format("%s does not have type %s", a, this));
  }

  @SuppressWarnings("DuplicateBranchesInSwitch")
  static boolean numeric(Type type) {
    return switch (type) {
      case IntType ignored -> true;
      case IntegerType ignored -> true;
      case RationalType ignored -> true;
      case RealType ignored -> true;
      default -> false;
    };
  }
}
