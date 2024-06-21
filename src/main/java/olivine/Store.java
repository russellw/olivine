package olivine;

public final class Store extends Instruction {
  public Term value;
  public Term pointer;

  @Override
  public void verify() {
    value.verify();
    assert value.type() != Type.VOID;
    assert pointer.type() == Type.PTR;
  }

  public Store(Term value, Term pointer) {
    this.value = value;
    this.pointer = pointer;
  }
}
