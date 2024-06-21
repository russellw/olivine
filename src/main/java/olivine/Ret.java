package olivine;

public final class Ret extends Instruction {
  public final Term value;

  @Override
  public void verify() {
    value.verify();
    assert value.type() != Type.VOID;
  }

  public Ret(Term value) {
    this.value = value;
  }
}
