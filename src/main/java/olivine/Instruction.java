package olivine;

public abstract class Instruction {
  public void dump() {
    System.out.printf("\t%s\n", getClass().getSimpleName());
  }

  public void verify() {}
}
