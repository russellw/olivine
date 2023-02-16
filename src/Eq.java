public final class Eq extends Term {
  Type type() {
    return BooleanType.instance;
  }

  Eq(Object a, Object b) {
    super(a, b);
  }
}
