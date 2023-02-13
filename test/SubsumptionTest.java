import java.util.ArrayList;

public class SubsumptionTest {
  @SuppressWarnings("AssertWithSideEffects")
  public static void main(String[] args) {
    var a = new Fn(IntegerType.instance, "a");
    var b = new Fn(IntegerType.instance, "b");
    var p = new Fn(BooleanType.instance, "p");
    var q = new Fn(BooleanType.instance, "q");
    var x = new Variable(IntegerType.instance);
    var y = new Variable(IntegerType.instance);
    var z = new Variable(IntegerType.instance);
    var negative = new ArrayList<>();
    var positive = new ArrayList<>();
    Clause c, d;
    var subsumption = new Subsumption();

    // false <= false
    c = new Clause(negative, positive);
    negative.clear();
    positive.clear();
    d = new Clause(negative, positive);
    assert subsumption.subsumes(c, d);

    // false <= p
    negative.clear();
    positive.clear();
    c = new Clause(negative, positive);
    negative.clear();
    positive.clear();
    positive.add(p);
    d = new Clause(negative, positive);
    assert subsumption.subsumes(c, d);
    assert !subsumption.subsumes(d, c);

    // p <= p
    negative.clear();
    positive.clear();
    positive.add(p);
    c = new Clause(negative, positive);
    negative.clear();
    positive.clear();
    positive.add(p);
    d = new Clause(negative, positive);
    assert subsumption.subsumes(c, d);

    // !p <= !p
    negative.clear();
    negative.add(p);
    positive.clear();
    c = new Clause(negative, positive);
    negative.clear();
    negative.add(p);
    positive.clear();
    d = new Clause(negative, positive);
    assert subsumption.subsumes(c, d);

    // p <= p | p
    negative.clear();
    positive.clear();
    positive.add(p);
    c = new Clause(negative, positive);
    negative.clear();
    positive.clear();
    positive.add(p);
    positive.add(p);
    d = new Clause(negative, positive);
    assert subsumption.subsumes(c, d);
    assert !subsumption.subsumes(d, c);

    // p !<= !p
    negative.clear();
    positive.clear();
    positive.add(p);
    c = new Clause(negative, positive);
    negative.clear();
    negative.add(p);
    positive.clear();
    d = new Clause(negative, positive);
    assert !subsumption.subsumes(c, d);
    assert !subsumption.subsumes(d, c);

    // p | q <= q | p
    negative.clear();
    positive.clear();
    positive.add(p);
    positive.add(q);
    c = new Clause(negative, positive);
    negative.clear();
    positive.clear();
    positive.add(q);
    positive.add(p);
    d = new Clause(negative, positive);
    assert subsumption.subsumes(c, d);
    assert subsumption.subsumes(d, c);

    // p | q <= p | q | p
    negative.clear();
    positive.clear();
    positive.add(p);
    positive.add(q);
    c = new Clause(negative, positive);
    negative.clear();
    positive.clear();
    positive.add(p);
    positive.add(q);
    positive.add(p);
    d = new Clause(negative, positive);
    assert subsumption.subsumes(c, d);
    assert !subsumption.subsumes(d, c);

    // p(a) | p(b) | q(a) | q(b) | <= p(a) | q(a) | p(b) | q(b)
    negative.clear();
    positive.clear();
    positive.add(new Call(p, a));
    positive.add(new Call(p, b));
    positive.add(new Call(q, a));
    positive.add(new Call(q, b));
    c = new Clause(negative, positive);
    negative.clear();
    positive.clear();
    positive.add(new Call(p, a));
    positive.add(new Call(q, a));
    positive.add(new Call(p, b));
    positive.add(new Call(q, b));
    d = new Clause(negative, positive);
    assert subsumption.subsumes(c, d);
    assert subsumption.subsumes(d, c);

    // p(6,7) | p(4,5) <= q(6,7) | q(4,5) | p(0,1) | p(2,3) | p(4,4) | p(4,5) | p(6,6) | p(6,7)
    negative.clear();
    positive.clear();
    positive.add(new Call(p, 6, 7));
    positive.add(new Call(p, 4, 5));
    c = new Clause(negative, positive);
    negative.clear();
    positive.clear();
    positive.add(new Call(q, 6, 7));
    positive.add(new Call(q, 4, 5));
    positive.add(new Call(p, 0, 1));
    positive.add(new Call(p, 2, 3));
    positive.add(new Call(p, 4, 4));
    positive.add(new Call(p, 4, 5));
    positive.add(new Call(p, 6, 6));
    positive.add(new Call(p, 6, 7));
    d = new Clause(negative, positive);
    assert subsumption.subsumes(c, d);
    assert !subsumption.subsumes(d, c);

    // p(x,y) <= p(a,b)
    negative.clear();
    positive.clear();
    positive.add(new Call(p, x, y));
    c = new Clause(negative, positive);
    negative.clear();
    positive.clear();
    positive.add(new Call(p, a, b));
    d = new Clause(negative, positive);
    assert subsumption.subsumes(c, d);
    assert !subsumption.subsumes(d, c);

    // p(x,x) !<= p(a,b)
    negative.clear();
    positive.clear();
    positive.add(new Call(p, x, x));
    c = new Clause(negative, positive);
    negative.clear();
    positive.clear();
    positive.add(new Call(p, a, b));
    d = new Clause(negative, positive);
    assert !subsumption.subsumes(c, d);
    assert !subsumption.subsumes(d, c);

    // p(x) <= p(y)
    negative.clear();
    positive.clear();
    positive.add(new Call(p, x));
    c = new Clause(negative, positive);
    negative.clear();
    positive.clear();
    positive.add(new Call(p, y));
    d = new Clause(negative, positive);
    assert subsumption.subsumes(c, d);
    assert subsumption.subsumes(d, c);

    // p(x) | p(a(x)) | p(a(a(x))) <= p(y) | p(a(y)) | p(a(a(y)))
    negative.clear();
    positive.clear();
    positive.add(new Call(p, x));
    positive.add(new Call(p, new Call(a, x)));
    positive.add(new Call(p, new Call(a, new Call(a, x))));
    c = new Clause(negative, positive);
    negative.clear();
    positive.clear();
    positive.add(new Call(p, y));
    positive.add(new Call(p, new Call(a, y)));
    positive.add(new Call(p, new Call(a, new Call(a, y))));
    d = new Clause(negative, positive);
    assert subsumption.subsumes(c, d);
    assert subsumption.subsumes(d, c);

    // p(x) | p(a) <= p(a) | p(b)
    negative.clear();
    positive.clear();
    positive.add(new Call(p, x));
    positive.add(new Call(p, a));
    c = new Clause(negative, positive);
    negative.clear();
    positive.clear();
    positive.add(new Call(p, a));
    positive.add(new Call(p, b));
    d = new Clause(negative, positive);
    assert subsumption.subsumes(c, d);
    assert !subsumption.subsumes(d, c);

    // p(x) | p(a(x)) <= p(a(y)) | p(y)
    negative.clear();
    positive.clear();
    positive.add(new Call(p, x));
    positive.add(new Call(p, new Call(a, x)));
    c = new Clause(negative, positive);
    negative.clear();
    positive.clear();
    positive.add(new Call(p, new Call(a, y)));
    positive.add(new Call(p, y));
    d = new Clause(negative, positive);
    assert subsumption.subsumes(c, d);
    assert subsumption.subsumes(d, c);

    // p(x) | p(a(x)) | p(a(a(x))) <= p(a(a(y))) | p(a(y)) | p(y)
    negative.clear();
    positive.clear();
    positive.add(new Call(p, x));
    positive.add(new Call(p, new Call(a, x)));
    positive.add(new Call(p, new Call(a, new Call(a, x))));
    c = new Clause(negative, positive);
    negative.clear();
    positive.clear();
    positive.add(new Call(p, new Call(a, new Call(a, y))));
    positive.add(new Call(p, new Call(a, y)));
    positive.add(new Call(p, y));
    d = new Clause(negative, positive);
    assert subsumption.subsumes(c, d);
    assert subsumption.subsumes(d, c);

    // (a = x) <= (a = b)
    negative.clear();
    positive.clear();
    positive.add(new Eq(a, x));
    c = new Clause(negative, positive);
    negative.clear();
    positive.clear();
    positive.add(new Eq(a, b));
    d = new Clause(negative, positive);
    assert subsumption.subsumes(c, d);
    assert !subsumption.subsumes(d, c);

    // (x = a) <= (a = b)
    negative.clear();
    positive.clear();
    positive.add(new Eq(x, a));
    c = new Clause(negative, positive);
    negative.clear();
    positive.clear();
    positive.add(new Eq(a, b));
    d = new Clause(negative, positive);
    assert subsumption.subsumes(c, d);
    assert !subsumption.subsumes(d, c);

    // !p(y) | !p(x) | q(x) <= !p(a) | !p(b) | q(b)
    negative.clear();
    negative.add(new Call(p, y));
    negative.add(new Call(p, x));
    positive.clear();
    positive.add(new Call(q, x));
    c = new Clause(negative, positive);
    negative.clear();
    negative.add(new Call(p, a));
    negative.add(new Call(p, b));
    positive.clear();
    positive.add(new Call(q, b));
    d = new Clause(negative, positive);
    assert subsumption.subsumes(c, d);
    assert !subsumption.subsumes(d, c);

    // !p(x) | !p(y) | q(x) <= !p(a) | !p(b) | q(b)
    negative.clear();
    negative.add(new Call(p, x));
    negative.add(new Call(p, y));
    positive.clear();
    positive.add(new Call(q, x));
    c = new Clause(negative, positive);
    negative.clear();
    negative.add(new Call(p, a));
    negative.add(new Call(p, b));
    positive.clear();
    positive.add(new Call(q, b));
    d = new Clause(negative, positive);
    assert subsumption.subsumes(c, d);
    assert !subsumption.subsumes(d, c);

    // (x = a) | (1 = y) !<= (1 = a) | (z = 0)
    negative.clear();
    positive.clear();
    positive.add(new Eq(x, a));
    positive.add(new Eq(1, y));
    c = new Clause(negative, positive);
    negative.clear();
    positive.clear();
    positive.add(new Eq(1, a));
    positive.add(new Eq(z, 0));
    d = new Clause(negative, positive);
    assert !subsumption.subsumes(c, d);
    assert !subsumption.subsumes(d, c);

    // p(x,a(x)) !<= p(a(y),a(y))
    negative.clear();
    positive.clear();
    positive.add(new Call(p, x, new Call(a, x)));
    c = new Clause(negative, positive);
    negative.clear();
    positive.clear();
    positive.add(new Call(p, new Call(a, y), new Call(a, y)));
    d = new Clause(negative, positive);
    assert !subsumption.subsumes(c, d);
    assert !subsumption.subsumes(d, c);
  }
}
