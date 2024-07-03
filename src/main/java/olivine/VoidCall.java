package olivine;

public final class VoidCall extends Instruction {
  public final Term call;

  public VoidCall(Term call) {
    this.call = call;
  }

  @Override
  public void dump() {
    System.out.println("\t" + call);
  }

  @Override
  public void verify() {
    call.verify();
    assert call.tag() == Tag.call;
    var function = (Function) call.get(0);
    assert function.returnType == Type.VOID;
  }
}
