package olivine;

public final class VoidCall extends Instruction {
  final Term call;

  @Override
  void verify() {
    assert call.tag() == Tag.CALL;
    var function = (Function) call.get(0);
    assert function.returnType == Type.VOID;
  }

  public VoidCall(Term call) {
    this.call = call;
  }
}
