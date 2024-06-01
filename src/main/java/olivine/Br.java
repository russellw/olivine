package olivine;

public final class Br extends Instruction {
  final Term cond;
  final Block ifTrue, ifFalse;

  public Br(Term cond, Block ifTrue, Block ifFalse) {
    this.cond = cond;
    this.ifTrue = ifTrue;
    this.ifFalse = ifFalse;
  }
}
