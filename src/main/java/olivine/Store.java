package olivine;

public final class Store extends Instruction {
  Term value;
  Term pointer;

  public Store(Term value, Term pointer) {
    this.value = value;
    this.pointer = pointer;
  }
}
