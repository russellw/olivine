package olivine;

public final class Case {
  public Block dest;
  public Term val;

  public Case(Term val, Block dest) {
    this.val = val;
    this.dest = dest;
  }
}
