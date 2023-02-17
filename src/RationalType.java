public final class RationalType extends Type {
  @Override
  public String toString() {
    return "BigRational";
  }

  static RationalType instance = new RationalType();
}
