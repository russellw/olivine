final class Div extends Binary {
  Div(Object arg0, Object arg1) {
    super(arg0, arg1);
  }

  Object apply(BigRational a, BigRational b) {
    return a.div(b);
  }
}
