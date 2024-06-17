package olivine;

public final class Br extends Instruction {
  final Term cond;
  final Block ifTrue, ifFalse;

  @Override
  void verify() {
    cond.verify();
    assert cond.type() == Type.I1;
  }

  public Br(Term cond, Block ifTrue, Block ifFalse) {
    this.cond = cond;
    this.ifTrue = ifTrue;
    this.ifFalse = ifFalse;
  }
}
