import java.math.BigInteger;

public class TypeTest {
  public static void main(String[] args) {
    assert Type.of(true) == BooleanType.instance;
    assert Type.of(BigInteger.ONE) == IntegerType.instance;
    assert Type.of(BigRational.ONE) == RationalType.instance;
    assert Type.of(new Variable(IndividualType.instance)) == IndividualType.instance;
    assert Type.of(new Add(BigInteger.ONE, BigInteger.ONE)) == IntegerType.instance;
    assert Type.of(new Eq(BigInteger.ONE, BigInteger.ONE)) == BooleanType.instance;
  }
}
