final class Eq extends Binary {
  Type type() {
    return BooleanType.instance;
  }

  Eq(Object arg0, Object arg1) {
    super(arg0, arg1);
  }
}
