import java.math.BigInteger;

class TermTest {
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
    assert a.get(0).equals(11);
    assert a.get(1).equals(21);
  }
}
