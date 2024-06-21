package olivine;

public final class BrUnconditional extends Instruction {
  public final Block dest;

  public BrUnconditional(Block dest) {
    this.dest = dest;
  }
}
