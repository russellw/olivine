package olivine;

public final class Case {
  public Term val;
  public Block dest;

  public Case(Term val, Block dest) {
    this.val = val;
    this.dest = dest;
  }
}
