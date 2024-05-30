package olivine;

public final class Ret extends Instruction {
  final Term value;

  public Ret(Term value) {
    this.value = value;
  }
}
