public final class All extends Quantifier {
  All(Variable[] variables, Object body) {
    super(variables, body);
  }

  static Object quantify(Object a) {
    var free = Variable.freeVariables(a);
    if (free.isEmpty()) return a;
    return new All(free.toArray(new Variable[0]), a);
  }
}
