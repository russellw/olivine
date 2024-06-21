package olivine;

public final class GlobalVariable extends Global {
  private final Type type;
  public Term value;

  public GlobalVariable(String name, Type type) {
    super(name);
    this.type = type;
  }

  @Override
  public Tag tag() {
    return Tag.GLOBAL_VARIABLE;
  }

  @Override
  public Type type() {
    return type;
  }
}
