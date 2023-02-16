import java.util.Set;

public class VarTest {
  public static void main(String[] args) {
    var x = new Variable(IndividualType.instance);
    assert Variable.freeVariables(7).equals(Set.of());
    assert Variable.freeVariables(x).equals(Set.of(x));
    assert Variable.freeVariables(new Add(x, x)).equals(Set.of(x));
    assert Variable.freeVariables(new All(new Variable[] {}, new Eq(x, x))).equals(Set.of(x));
    assert Variable.freeVariables(new All(new Variable[] {x}, new Eq(x, x))).equals(Set.of());
  }
}
