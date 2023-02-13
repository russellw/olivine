abstract class Quantifier {
  final Variable[] variables;
  final Object body;

  Quantifier(Variable[] variables, Object body) {
    this.variables = variables;
    this.body = body;
  }
}
