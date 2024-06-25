package olivine;

public final class Variable extends Term {
  private final Type type;

  public Variable(Type type) {
    this.type = type;
  }

  @Override
  public Tag tag() {
    return Tag.VARIABLE;
  }

  @Override
  public String toString() {
    return '%' + Integer.toHexString(hashCode());
  }

  @Override
  public Type type() {
    return type;
  }
}
