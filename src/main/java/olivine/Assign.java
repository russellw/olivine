package olivine;

public final class Assign extends Instruction {
  public final Term value;
  public final Variable variable;

  public Assign(Variable variable, Term value) {
    this.variable = variable;
    this.value = value;
  }

  @Override
  public void verify() {
    value.verify();
    var type = value.type();
    assert type != Type.VOID;
    assert variable.type().equals(type);
  }
}
