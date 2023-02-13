final class Equation {
  // TODO reduce to Eq?
  final Object left, right;

  Equation(Object left, Object right) {
    assert equatable(left, right);
    this.left = left;
    this.right = right;
  }

  static boolean equatable(Object a, Object b) {
    if (!Type.of(a).equals(Type.of(b))) return false;
    return Type.of(b) != BooleanType.instance || b == Boolean.TRUE;
  }

  Equation(Object a0) {
    assert Type.of(a0) == BooleanType.instance;
    if (a0 instanceof Eq a) {
      left = a.args[0];
      right = a.args[1];
      return;
    }
    left = a0;
    right = Boolean.TRUE;
  }

  Object extract() {
    if (right == Boolean.TRUE) return left;
    return new Eq(left, right);
  }

  public String toString() {
    return left.toString() + '=' + right;
  }
}
