import java.math.BigInteger;

abstract class Type {
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
      default -> throw new IllegalArgumentException(a.toString());
    };
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
