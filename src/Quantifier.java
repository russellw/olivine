import java.util.Arrays;

public abstract class Quantifier {
  final Variable[] variables;
  final Object body;

  @Override
  public String toString() {
    return getClass().getSimpleName() + Arrays.toString(variables) + body;
  }

  Quantifier(Variable[] variables, Object body) {
    this.variables = variables;
    this.body = body;
  }
}
