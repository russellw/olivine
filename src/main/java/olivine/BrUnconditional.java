package olivine;

public final class BrUnconditional extends Instruction {
  final Block dest;

  public BrUnconditional(Block dest) {
    this.dest = dest;
  }
}
