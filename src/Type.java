import java.math.BigInteger;

abstract class Type {
  static Type of(Object a0) {
    return switch (a0) {
      case Boolean ignored -> BooleanType.instance;
      case BigInteger ignored -> IntegerType.instance;
      case Integer ignored -> IntType.instance;
      case BigRational ignored -> RationalType.instance;
      case Real ignored -> RealType.instance;
      case DistinctObject ignored -> IndividualType.instance;
      case Var a -> a.type;
      case Fn a -> a.type();
      case Instruction a -> a.type();
      default -> throw new IllegalArgumentException(a0.toString());
    };
  }
}
