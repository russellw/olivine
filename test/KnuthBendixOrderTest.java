import java.util.ArrayList;
import java.util.List;
import java.util.Random;

public class KnuthBendixOrderTest {
  private static final int ITERATIONS = 10000;
  private static final List<Fn> fns = new ArrayList<>();
  private static final List<Fn> nullaryFns = new ArrayList<>();
  private static final List<Variable> variables = new ArrayList<>();
  private static final Random random = new Random(0);
  private static KnuthBendixOrder order;

  private static Object randomIndividualTerm(int depth) {
    if (depth == 0 || random.nextInt(100) < 40)
      if (variables.isEmpty() || random.nextInt(100) < 30)
        return nullaryFns.get(random.nextInt(nullaryFns.size()));
      else return variables.get(random.nextInt(variables.size()));

    var f = fns.get(random.nextInt(fns.size()));
    var args = new Object[f.params.length];
    for (var i = 0; i < args.length; i++) args[i] = randomIndividualTerm(depth - 1);
    return new Call(f, args);
  }

  @SuppressWarnings("SameParameterValue")
  private static Equation randomIndividualEquation(int depth) {
    return new Equation(randomIndividualTerm(depth), randomIndividualTerm(depth));
  }

  private static void makeRandomOrder() {
    for (var i = 0; i < 4; i++) fns.add(new Fn(IndividualType.instance, String.format("f%d", i)));
    for (var i = 0; i < 4; i++)
      nullaryFns.add(new Fn(IndividualType.instance, String.format("a%d", i)));
    for (var i = 0; i < 4; i++) variables.add(new Variable(IndividualType.instance));
    order = new KnuthBendixOrder();
  }

  private static boolean greater(Object a, Object b) {
    return order.compare(a, b) == PartialOrder.GT;
  }

  private static boolean greater(Equation a, Equation b) {
    return order.compare(true, a, true, b) == PartialOrder.GT;
  }

  static void randomTest() {
    makeRandomOrder();
    for (var i = 0; i < ITERATIONS; i++) {
      var a = randomIndividualTerm(4);
      var b = randomIndividualTerm(4);
      assert !(greater(a, b) && Term.eq(a, b));
      assert !(greater(a, b) && greater(b, a));
    }
  }

  static void greater() {
    var red = new DistinctObject("red");
    var green = new DistinctObject("green");
    var a = new Fn(IndividualType.instance, "a");
    var b = new Fn(IndividualType.instance, "b");
    var p1 = new Fn(BooleanType.instance, "p1");
    var q1 = new Fn(BooleanType.instance, "q1");
    var x = new Variable(IndividualType.instance);
    var y = new Variable(IndividualType.instance);
    order = new KnuthBendixOrder();

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
    if (Term.eq(a.left, b.left) && Term.eq(a.right, b.right)) return true;
    return Term.eq(a.left, b.right) && Term.eq(a.right, b.left);
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

  private static boolean containsSubterm(Object a, Object b) {
    if (Term.eq(a, b)) return true;
    for (var ai : Term.args(a)) if (containsSubterm(ai, b)) return true;
    return false;
  }

  static void totalOnGroundTerms() {
    makeRandomOrder();
    variables.clear();
    for (var i = 0; i < ITERATIONS; i++) {
      var a = randomIndividualTerm(4);
      var b = randomIndividualTerm(4);
      if (!Term.eq(a, b)) checkOrdered(a, b);
    }
  }

  static void containsSubtermRelation() {
    makeRandomOrder();
    for (var i = 0; i < ITERATIONS; i++) {
      var a = randomIndividualTerm(4);
      var b = randomIndividualTerm(4);
      if (Term.eq(a, b)) continue;
      assert !containsSubterm(a, b) || (greater(a, b));
      assert !containsSubterm(b, a) || (greater(b, a));
    }
  }

  static void cast() {
    var a = new Fn(RealType.instance, "a");
    var b = new Fn(RealType.instance, "b");
    order = new KnuthBendixOrder();

    checkOrdered(new Cast(RealType.instance, a), new Cast(RationalType.instance, a));
    checkOrdered(new Cast(RealType.instance, a), new Cast(RealType.instance, b));
    checkEqual(new Cast(RealType.instance, a), new Cast(RealType.instance, a));
  }

  static void eqlEquations() {
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

  static void totalOnGroundEquations() {
    makeRandomOrder();
    variables.clear();
    for (var i = 0; i < ITERATIONS; i++) {
      var a = randomIndividualEquation(4);
      var b = randomIndividualEquation(4);
      if (!eql(a, b)) checkOrdered(a, b);
    }
  }

  private static void assertEquals(Object a, Object b) {
    assert a.equals(b);
  }

  public static void main(String[] args) {
    greater();
    eqlEquations();
    totalOnGroundTerms();
    totalOnGroundEquations();
    containsSubtermRelation();
    randomTest();
    cast();
  }
}
