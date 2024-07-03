package olivine;

public final class GlobalVariable extends Global {
  public Type type;
  public Term value;

  public GlobalVariable(String name) {
    super(name);
  }

  @Override
  public Tag tag() {
    return Tag.globalVariable;
  }

  @Override
  public Type type() {
    return type;
  }
}
