package olivine;

public final class Store extends Instruction {
  public Term pointer;
  public Term value;

  public Store(Term value, Term pointer) {
    this.value = value;
    this.pointer = pointer;
  }

  @Override
  public void dump() {
    System.out.printf("\tStore %s, %s\n", value, pointer);
  }

  @Override
  public void verify() {
    value.verify();
    assert value.type() != Type.VOID;
    assert pointer.type() == Type.PTR;
  }
}
