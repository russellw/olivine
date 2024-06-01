package olivine;

public final class AssignVoid extends Instruction {
  final Term from;

  public AssignVoid(Term from) {
    this.from = from;
  }
}
