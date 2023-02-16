import java.util.HashMap;
import java.util.Map;

public class UnificationTest {
  public static void main(String[] args) {
    // https://en.wikipedia.org/wiki/Unification_(computer_science)#Examples_of_syntactic_unification_of_first-order_terms
    var a = new Fn(IndividualType.instance, "a");
    var b = new Fn(IndividualType.instance, "b");
    var f = new Fn(IndividualType.instance, "f");
    var g = new Fn(IndividualType.instance, "g");
    var x = new Variable(IndividualType.instance);
    var y = new Variable(IndividualType.instance);
    var z = new Variable(IndividualType.instance);
    Map<Variable, Object> map;

    // Succeeds. (tautology)
    map = new HashMap<>();
    assert Unification.unify(a, a, map);
    assert map.isEmpty();

    // a and b do not match
    map = new HashMap<>();
    assert !Unification.unify(a, b, map);

    // Succeeds. (tautology)
    map = new HashMap<>();
    assert Unification.unify(x, x, map);
    assert map.isEmpty();

    // x is unified with the constant a
    map = new HashMap<>();
    assert Unification.unify(a, x, map);
    assert map.size() == 1;
    assert Term.eq(Term.replace(map, x), a);

    // x and y are aliased
    map = new HashMap<>();
    assert Unification.unify(x, y, map);
    assert map.size() == 1;
    assert Term.eq(Term.replace(map, x), Term.replace(map, y));

    // function and constant symbols match, x is unified with the constant b
    map = new HashMap<>();
    assert Unification.unify(new Call(f, a, x), new Call(f, a, b), map);
    assert map.size() == 1;
    assert Term.eq(Term.replace(map, x), b);

    // f and g do not match
    map = new HashMap<>();
    assert !Unification.unify(new Call(f, a), new Call(g, a), map);

    // x and y are aliased
    map = new HashMap<>();
    assert Unification.unify(new Call(f, x), new Call(f, y), map);
    assert map.size() == 1;
    assert Term.eq(Term.replace(map, x), Term.replace(map, y));

    // f and g do not match
    map = new HashMap<>();
    assert !Unification.unify(new Call(f, x), new Call(g, y), map);

    // Fails. The f function symbols have different arity
    map = new HashMap<>();
    assert !Unification.unify(new Call(f, x), new Call(f, y, z), map);

    // Unifies y with the term g(x)
    map = new HashMap<>();
    assert Unification.unify(new Call(f, new Call(g, x)), new Call(f, y), map);
    assert map.size() == 1;
    assert Term.eq(Term.replace(map, y), new Call(g, x));

    // Unifies x with constant a, and y with the term g(a)
    map = new HashMap<>();
    assert Unification.unify(new Call(f, new Call(g, x), x), new Call(f, y, a), map);
    assert map.size() == 2;
    assert Term.eq(Term.replace(map, x), a);
    assert Term.eq(Term.replace(map, y), new Call(g, a));

    // Returns false in first-order logic and many modern Prolog dialects (enforced by the occurs
    // check).
    map = new HashMap<>();
    assert !Unification.unify(x, new Call(f, x), map);

    // Both x and y are unified with the constant a
    map = new HashMap<>();
    assert Unification.unify(x, y, map);
    assert Unification.unify(y, a, map);
    assert map.size() == 2;
    assert Term.eq(Term.replace(map, x), a);
    assert Term.eq(Term.replace(map, y), a);

    // As above (order of equations in set doesn't matter)
    map = new HashMap<>();
    assert Unification.unify(a, y, map);
    assert Unification.unify(x, y, map);
    assert map.size() == 2;
    assert Term.eq(Term.replace(map, x), a);
    assert Term.eq(Term.replace(map, y), a);

    // Fails. a and b do not match, so x can't be unified with both
    map = new HashMap<>();
    assert Unification.unify(x, a, map);
    assert !Unification.unify(b, x, map);

    // match is a subset of unify.
    // Different results in several cases;
    // in particular, has no notion of an occurs check.
    // Assumes the inputs have disjoint variables

    // Succeeds. (tautology)
    map = new HashMap<>();
    assert Unification.match(a, a, map);
    assert map.isEmpty();

    // a and b do not match
    map = new HashMap<>();
    assert !Unification.match(a, b, map);

    // Succeeds. (tautology)
    map = new HashMap<>();
    assert Unification.match(x, x, map);
    assert map.isEmpty();

    // a and x do not match
    map = new HashMap<>();
    assert !Unification.match(a, x, map);

    // x and y are aliased
    map = new HashMap<>();
    assert Unification.match(x, y, map);
    assert map.size() == 1;
    assert Term.eq(Term.replace(map, x), Term.replace(map, y));

    // function and constant symbols match, x is unified with the constant b
    map = new HashMap<>();
    assert Unification.match(new Call(f, a, x), new Call(f, a, b), map);
    assert map.size() == 1;
    assert Term.eq(Term.replace(map, x), b);

    // f and g do not match
    map = new HashMap<>();
    assert !Unification.match(new Call(f, a), new Call(g, a), map);

    // x and y are aliased
    map = new HashMap<>();
    assert Unification.match(new Call(f, x), new Call(f, y), map);
    assert map.size() == 1;
    assert Term.eq(Term.replace(map, x), Term.replace(map, y));

    // f and g do not match
    map = new HashMap<>();
    assert !Unification.match(new Call(f, x), new Call(g, y), map);

    // Fails. The f function symbols have different arity
    map = new HashMap<>();
    assert !Unification.match(new Call(f, x), new Call(f, y, z), map);

    // g(x) and y do not match
    map = new HashMap<>();
    assert !Unification.match(new Call(f, new Call(g, x)), new Call(f, y), map);

    // g(x) and y do not match
    map = new HashMap<>();
    assert !Unification.match(new Call(f, new Call(g, x), x), new Call(f, y, a), map);
  }
}
