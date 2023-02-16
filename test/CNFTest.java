import java.util.List;

public class CNFTest {
  private static List<Clause> convert(Object a) {
    var cnf = new CNF();
    cnf.add(a);
    return cnf.clauses;
  }

  public static void main(String[] args) {
    List<Clause> clauses;
    Object a;

    // false
    a = false;
    clauses = convert(a);
    assert clauses.size() == 1;
    assert (clauses.get(0).isFalse());

    // true
    a = true;
    clauses = convert(a);
    assert clauses.size() == 0;

    // !false
    a = new Not(false);
    clauses = convert(a);
    assert clauses.size() == 0;

    // !true
    a = new Not(true);
    clauses = convert(a);
    assert clauses.size() == 1;
    assert (clauses.get(0).isFalse());

    // false & false
    a = new And(false, false);
    clauses = convert(a);
    assert clauses.size() == 2;
    assert (clauses.get(0).isFalse());
    assert (clauses.get(1).isFalse());

    // false & true
    a = new And(false, true);
    clauses = convert(a);
    assert clauses.size() == 1;
    assert (clauses.get(0).isFalse());

    // true & false
    a = new And(true, false);
    clauses = convert(a);
    assert clauses.size() == 1;
    assert (clauses.get(0).isFalse());

    // true & true
    a = new And(true, true);
    clauses = convert(a);
    assert clauses.size() == 0;

    // false | false
    a = new Or(false, false);
    clauses = convert(a);
    assert clauses.size() == 1;
    assert (clauses.get(0).isFalse());

    // false | true
    a = new Or(false, true);
    clauses = convert(a);
    assert clauses.size() == 0;

    // true | false
    a = new Or(true, false);
    clauses = convert(a);
    assert clauses.size() == 0;

    // true | true
    a = new Or(true, true);
    clauses = convert(a);
    assert clauses.size() == 0;

    // p & q
    var p = new Fn(BooleanType.instance, "p");
    var q = new Fn(BooleanType.instance, "q");
    a = new And(p, q);
    clauses = convert(a);
    assert clauses.size() == 2;
    assertEql(clauses.get(0), p);
    assertEql(clauses.get(1), q);

    // p | q
    a = new Or(p, q);
    clauses = convert(a);
    assert clauses.size() == 1;
    assertEql(clauses.get(0), p, q);

    // !(p & q)
    a = new Not(new And(p, q));
    clauses = convert(a);
    assert clauses.size() == 1;
    assertEql(clauses.get(0), new Not(p), new Not(q));

    // !(p | q)
    a = new Not(new Or(p, q));
    clauses = convert(a);
    assert clauses.size() == 2;
    assertEql(clauses.get(0), new Not(p));
    assertEql(clauses.get(1), new Not(q));
  }

  private static void assertEquals(Object a, Object b) {
    assert Term.eq(a, b);
  }

  private static void assertEql(Clause c, Object... q) {
    var negativeIndex = 0;
    var positiveIndex = 0;
    for (var a0 : q) {
      if (a0 instanceof Not a) assertEquals(c.negative()[negativeIndex++], a.args[0]);
      else assertEquals(c.positive()[positiveIndex++], a0);
    }
  }
}
