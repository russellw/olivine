import java.util.ArrayList;
import java.util.List;
import java.util.Random;

public class KnuthBendixOrderTest {
  private static final int ITERATIONS = 10000;
  private static final List<Fn> funcs = new ArrayList<>();
  private static final List<Fn> globalVars = new ArrayList<>();
  private static final List<Var> vars = new ArrayList<>();
  private static final Random random = new Random(0);
  private static KnuthBendixOrder order;

  private static Object randomIndividualTerm(int depth) {
    if (depth == 0 || random.nextInt(100) < 40)
      if (vars.isEmpty() || random.nextInt(100) < 30)
        return globalVars.get(random.nextInt(globalVars.size()));
      else return vars.get(random.nextInt(vars.size()));

    var f = funcs.get(random.nextInt(funcs.size()));
    var args = new Object[f.params.length];
    for (var i = 0; i < args.length; i++) args[i] = randomIndividualTerm(depth - 1);
    return new Call(f, args);
  }

  private static Equation randomIndividualEquation(int depth) {
    return new Equation(randomIndividualTerm(depth), randomIndividualTerm(depth));
  }

  private static void makeOrder() {
    var negative = new ArrayList<>();
    var positive = new ArrayList<>();
    for (var f : funcs) {
      var args = new Object[f.params.length];
      for (var i = 0; i < args.length; i++) args[i] = vars.get(0);
      positive.add(new Eq(new Call(f, args), vars.get(0)));
    }
    for (var a : globalVars) positive.add(new Eq(a, vars.get(0)));
    var clauses = new ArrayList<Clause>();
    clauses.add(new Clause(negative, positive));
    order = new KnuthBendixOrder(clauses);
  }

  private static void makeRandomOrder() {
    for (var i = 0; i < 4; i++) funcs.add(new Fn(IndividualType.instance, String.format("f%d", i)));
    for (var i = 0; i < 4; i++)
      globalVars.add(new Fn(IndividualType.instance, String.format("a%d", i)));
    for (var i = 0; i < 4; i++) vars.add(new Var(IndividualType.instance));
    makeOrder();
  }

  private static boolean greater(Object a, Object b) {
    return order.compare(a, b) == PartialOrder.GT;
  }

  private static boolean greater(Equation a, Equation b) {
    return order.compare(true, a, true, b) == PartialOrder.GT;
  }

  public void randomTest() {
    makeRandomOrder();
    for (var i = 0; i < ITERATIONS; i++) {
      var a = randomIndividualTerm(4);
      var b = randomIndividualTerm(4);
      assert !(greater(a, b) && a.equals(b));
      assert !(greater(a, b) && greater(b, a));
    }
  }

  public void greater() {
    var red = new DistinctObject("red");
    var green = new DistinctObject("green");
    var a = new Fn(IndividualType.instance, "a");
    var b = new Fn(IndividualType.instance, "b");
    var p1 = new Fn(BooleanType.instance, "p1");
    var q1 = new Fn(BooleanType.instance, "q1");
    var x = new Var(IndividualType.instance);
    var y = new Var(IndividualType.instance);
    var negative = new ArrayList<>();
    var positive = new ArrayList<>();
    var clauses = new ArrayList<Clause>();

    // order can depend on the contents of the initial clauses. in particular,
    // it can reasonably expect that all functions and global variables will be shown up front
    positive.add(new Eq(red, green));
    positive.add(new Eq(a, b));
    positive.add(new Call(p1, red));
    positive.add(new Call(q1, red));
    clauses.add(new Clause(negative, positive));
    order = new KnuthBendixOrder(clauses);

    checkUnordered(x, y);
    checkUnordered(1, 1);
    checkOrdered(1, 2);
    checkOrdered(red, green);
    checkOrdered(a, b);

    checkUnordered(
        new Add(BigRational.of(1, 3), BigRational.of(1, 3)),
        new Add(BigRational.of(1, 3), BigRational.of(1, 3)));
    checkOrdered(
        new Add(BigRational.of(1, 3), BigRational.of(1, 3)),
        new Add(BigRational.of(1, 3), BigRational.of(2, 3)));
    checkOrdered(
        new Add(BigRational.of(1, 3), BigRational.of(1, 3)),
        new Sub(BigRational.of(1, 3), BigRational.of(1, 3)));

    checkUnordered(new Call(p1, red), new Call(p1, red));
    checkOrdered(new Call(p1, red), new Call(p1, green));
    checkOrdered(new Call(p1, red), new Call(q1, red));

    checkUnordered(new Call(p1, x), new Call(p1, x));
    checkUnordered(new Call(p1, x), new Call(p1, y));
    checkOrdered(new Call(p1, x), new Call(q1, x));
  }

  private static void checkOrdered(Object a, Object b) {
    assert (greater(a, b) || greater(b, a));
  }

  private static boolean eql(Equation a, Equation b) {
    if (a.left.equals(b.left) && a.right.equals(b.right)) return true;
    return a.left.equals(b.right) && a.right.equals(b.left);
  }

  private static void checkOrdered(Equation a, Equation b) {
    assert (greater(a, b) || greater(b, a));
  }

  private static void checkUnordered(Object a, Object b) {
    assert !(greater(a, b));
    assert !(greater(b, a));
  }

  private static void checkEqual(Object a, Object b) {
    assertEquals(order.compare(a, b), PartialOrder.EQ);
  }

  private static boolean containsSubterm(Object a0, Object b) {
    if (a0.equals(b)) return true;
    if (a0 instanceof Instruction a) for (var ai : a) if (containsSubterm(ai, b)) return true;
    return false;
  }

  public void totalOnGroundTerms() {
    makeRandomOrder();
    vars.clear();
    for (var i = 0; i < ITERATIONS; i++) {
      var a = randomIndividualTerm(4);
      var b = randomIndividualTerm(4);
      if (!a.equals(b)) checkOrdered(a, b);
    }
  }

  public void containsSubtermRelation() {
    makeRandomOrder();
    for (var i = 0; i < ITERATIONS; i++) {
      var a = randomIndividualTerm(4);
      var b = randomIndividualTerm(4);
      if (a.equals(b)) continue;
      if (containsSubterm(a, b)) assert (greater(a, b));
      if (containsSubterm(b, a)) assert (greater(b, a));
    }
  }

  /*
  public void cast() {
    var negative = new ArrayList<>();
    var positive = new ArrayList<>();
    var a = new GlobalVar("a", Type.REAL);
    var b = new GlobalVar("b", Type.REAL);
    positive.add(new Eq( a, b));
    var clauses = new ArrayList<Clause>();
    clauses.add(new Clause(negative, positive));
    order = new KnuthBendixOrder(clauses);

    TODO
    checkOrdered(Term.cast(Type.REAL, a), Term.cast(Type.RATIONAL, a));
    checkOrdered(Term.cast(Type.REAL, a), Term.cast(Type.REAL, b));
    checkEqual(Term.cast(Type.REAL, a), Term.cast(Type.REAL, a));
  }
     */

  public void eqlEquations() {
    makeRandomOrder();
    for (var i = 0; i < ITERATIONS; i++) {
      var a = randomIndividualTerm(4);
      var b = randomIndividualTerm(4);
      assertEquals(
          PartialOrder.EQ, order.compare(true, new Equation(a, b), true, new Equation(a, b)));
      assertEquals(
          PartialOrder.EQ, order.compare(true, new Equation(a, b), true, new Equation(b, a)));
    }
  }

  public void totalOnGroundEquations() {
    makeRandomOrder();
    vars.clear();
    for (var i = 0; i < ITERATIONS; i++) {
      var a = randomIndividualEquation(4);
      var b = randomIndividualEquation(4);
      if (!eql(a, b)) checkOrdered(a, b);
    }
  }

  static void assertEquals(Object a, Object b) {
    assert a.equals(b);
  }
}
