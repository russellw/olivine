package olivine;

public final class Ret extends Instruction {
  public final Term value;

  public Ret(Term value) {
    this.value = value;
  }

  @Override
  public void dump() {
    System.out.printf("\tRet %s\n", value);
  }

  @Override
  public void verify() {
    value.verify();
    assert value.type() != Type.VOID;
  }
}
