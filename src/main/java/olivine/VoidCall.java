package olivine;

public final class VoidCall extends Instruction {
  final Term call;

  public VoidCall(Term call) {
    this.call = call;
  }
}
