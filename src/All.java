final class All extends Quantifier {
  All(Var[] vars, Object body) {
    super(vars, body);
  }

  static Object quantify(Object a) {
    var free = Var.freeVars(a);
    if (free.isEmpty()) return a;
    return new All(free.toArray(new Var[0]), a);
  }
}
