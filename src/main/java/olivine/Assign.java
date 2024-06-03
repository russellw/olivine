package olivine;

public final class Assign extends Instruction {
  final Variable variable;
  final Term value;

  public Assign(Variable variable, Term value) {
    this.variable = variable;
    this.value = value;
  }
}
