package olivine;

public final class VoidCall extends Instruction {
  final Term from;

  public VoidCall(Term from) {
    this.from = from;
  }
}
