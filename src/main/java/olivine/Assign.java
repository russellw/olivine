package olivine;

public final class Assign extends Instruction {
  final Var to;
  final Term from;

  public Assign(Var to, Term from) {
    this.to = to;
    this.from = from;
  }
}
