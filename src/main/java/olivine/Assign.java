package olivine;

public final class Assign extends Instruction {
  final Variable variable;
  final Term value;

  @Override
  void verify() {
    value.verify();
    var type = value.type();
    assert type != Type.VOID;
    assert variable.type().equals(type);
  }

  public Assign(Variable variable, Term value) {
    this.variable = variable;
    this.value = value;
  }
}
