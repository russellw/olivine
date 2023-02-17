public final class New extends Term {
  private final Type type;

  public New(Type type) {
    this.type = type;
  }

  @Override
  Term remake(Object[] v) {
    return new New(type);
  }

  Type type() {
    return type;
  }
}
