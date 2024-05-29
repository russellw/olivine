package olivine;

public final class GlobalVar extends Global {
  private final Type type;

  public GlobalVar(String name, Type type) {
    super(name);
    this.type = type;
  }

  @Override
  public Type type() {
    return type;
  }

  @Override
  public Tag tag() {
    return Tag.GLOBAL_VAR;
  }
}
