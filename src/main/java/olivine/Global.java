package olivine;

public abstract class Global extends Term {
  public final String name;

  protected Global(String name) {
    this.name = name;
  }

  @Override
  public String toString() {
    if (name == null) return super.toString();
    return name;
  }
}
