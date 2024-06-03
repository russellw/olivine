package olivine;

import java.util.List;

public final class Function extends Global {
  public final Type returnType;
  public final List<Variable> params;
  public final boolean varargs;
  public Block entry;

  public Function(String name, Type returnType, List<Variable> params, boolean varargs) {
    super(name);
    this.returnType = returnType;
    this.params = params;
    this.varargs = varargs;
  }

  @Override
  public Type type() {
    throw new UnsupportedOperationException(toString());
  }

  @Override
  public Tag tag() {
    return Tag.FUNCTION;
  }
}
