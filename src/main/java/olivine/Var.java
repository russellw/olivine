package olivine;

public final class Var extends Term {
  private final Type type;

  public Var(Type type) {
    this.type = type;
  }

  @Override
  public Type type() {
    return type;
  }

  @Override
  public Tag tag() {
    return Tag.VAR;
  }
}