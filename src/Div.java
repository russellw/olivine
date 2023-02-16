public final class Div extends Term {
  Div(Object a, Object b) {
    super(a, b);
  }

  Object apply(BigRational a, BigRational b) {
    return a.div(b);
  }
}
