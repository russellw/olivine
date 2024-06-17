package olivine;

public final class Ret extends Instruction {
  final Term value;

  @Override
  void verify() {
    value.verify();
    assert value.type() != Type.VOID;
  }

  public Ret(Term value) {
    this.value = value;
  }
}
