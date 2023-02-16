public class AddTest {
  public static void main(String[] args) {
    assert new Add(null, null).apply(1, 2).equals(3);
    assert new Add(1, 2).eval(null).equals(3);
  }
}
