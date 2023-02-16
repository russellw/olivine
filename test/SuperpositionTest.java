public class SuperpositionTest {
  static void test(Object a, boolean expected) {
    var cnf = new CNF();
    cnf.add(a);
    var r = Superposition.sat(cnf.clauses, 100);
    assert r == expected;
  }

  public static void main(String[] args) {
    var p = new Fn(BooleanType.instance, "p");
    var q = new Fn(BooleanType.instance, "q");

    test(true, true);
    test(false, false);

    test(p, true);
    test(new Not(p), true);
    test(new Not(new Not(p)), true);

    test(new And(p), true);
    test(new And(p, p), true);
    test(new And(p, p, p), true);
    test(new And(p, new Not(p)), false);

    test(new Or(p), true);
    test(new Or(p, p), true);
    test(new Or(p, p, p), true);
    test(new Or(p, new Not(p)), true);

    test(new Eqv(p, p), true);
    test(new Eqv(p, new Not(p)), false);

    test(new And(p, q), true);
    test(new Or(p, q), true);
  }
}
