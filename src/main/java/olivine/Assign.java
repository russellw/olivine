package olivine;

public final class Assign extends Instruction {
  final Var variable;
  final Term value;

  public Assign(Var variable, Term value) {
    this.variable = variable;
    this.value = value;
  }
}
