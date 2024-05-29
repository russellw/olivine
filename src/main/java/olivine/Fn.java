package olivine;

import java.util.List;

public final class Fn extends Global {
  public final Type rtype;
  public final List<Var> params;
  public final boolean varargs;
  public Block entry;

  public Fn(String name, Type rtype, List<Var> params, boolean varargs) {
    super(name);
    this.rtype = rtype;
    this.params = params;
    this.varargs = varargs;
  }

  @Override
  public Type type() {
    throw new UnsupportedOperationException(toString());
  }

  @Override
  public Tag tag() {
    return Tag.FN;
  }
}
