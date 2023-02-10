import java.util.Set;

class VarTest {
  public static void main(String[] args) {
    var x = new Var(IndividualType.instance);
    assert Var.freeVars(7).equals(Set.of());
    assert Var.freeVars(x).equals(Set.of(x));
    assert Var.freeVars(new Add(x, x)).equals(Set.of(x));
    assert Var.freeVars(new All(new Var[] {}, new Eq(x, x))).equals(Set.of(x));
    assert Var.freeVars(new All(new Var[] {x}, new Eq(x, x))).equals(Set.of());
  }
}
