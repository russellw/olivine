package olivine;

public abstract class Instruction {
  void dump() {
    System.out.printf("\t%s\n", getClass().getSimpleName());
  }

  public void verify() {}
}
