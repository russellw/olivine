final class Eq extends Binary {
  Type type() {
    return BooleanType.instance;
  }

  Eq(Object a, Object b) {
    super(a, b);
  }
}
