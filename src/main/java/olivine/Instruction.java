package olivine;

public abstract class Instruction {
  public void verify() {}

  void dump() {
    System.out.printf("\t%s\n", getClass().getSimpleName());
  }
}
