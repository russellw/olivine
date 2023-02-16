import java.math.BigInteger;
import java.util.List;

public class TermTest {
  static Object succ(Object a0) {
    return switch (a0) {
      case Integer a -> a + 1;
      case BigInteger a -> a.add(BigInteger.ONE);
      default -> a0;
    };
  }

  public static void main(String[] args) {
    var x = new Variable(null);
    assert Term.mapLeaves(TermTest::succ, x) == x;
    assert Term.mapLeaves(TermTest::succ, 5).equals(6);
    var a = (Add) Term.mapLeaves(TermTest::succ, new Add(10, 20));
    assert a.args[0].equals(11);
    assert a.args[1].equals(21);

    assert Term.eq(Term.splice(a, List.of(), 0, 9), 9);
    assert Term.eq(Term.splice(a, List.of(0), 0, 9), new Add(9, 21));
    assert Term.eq(Term.splice(a, List.of(1), 0, 9), new Add(11, 9));
  }
}
