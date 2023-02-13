final class Div extends Binary {
  Div(Object a, Object b) {
    super(a, b);
  }

  Object apply(BigRational a, BigRational b) {
    return a.div(b);
  }
}
