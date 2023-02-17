public final class VoidType extends Type {
  @Override
  public String toString() {
    return "V";
  }

  static VoidType instance = new VoidType();
}
