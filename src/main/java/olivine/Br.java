package olivine;

public final class Br extends Instruction {
  public final Term cond;
  public final Block ifTrue, ifFalse;

  public Br(Term cond, Block ifTrue, Block ifFalse) {
    this.cond = cond;
    this.ifTrue = ifTrue;
    this.ifFalse = ifFalse;
  }

  @Override
  public void verify() {
    cond.verify();
    assert cond.type() == Type.I1;
  }
}
