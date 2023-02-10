abstract class Quantifier {
  final Var[] vars;
  final Object body;

  Quantifier(Var[] vars, Object body) {
    this.vars = vars;
    this.body = body;
  }
}
