public final class IntegerType extends Type {
  static IntegerType instance = new IntegerType();

  @Override
  public String toString() {
    return "java/math/BigInteger";
  }
}
