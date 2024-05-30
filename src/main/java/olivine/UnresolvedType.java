package olivine;

public final class UnresolvedType extends Type {
  final String name;

  UnresolvedType(String name) {
    this.name = name;
  }

  @Override
  public String toString() {
    return name;
  }

  @Override
  public Kind kind() {
    return Kind.UNRESOLVED;
  }
}
