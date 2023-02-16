public final class OpaqueType extends Type {
  final String name;

  @Override
  public String toString() {
    return name;
  }

  OpaqueType(String name) {
    this.name = name;
  }
}
