import java.math.BigDecimal;
import java.math.BigInteger;
import java.util.Objects;

public final class BigRational extends Number implements Comparable<BigRational> {
  static final BigRational ZERO = new BigRational(BigInteger.ZERO);
  static final BigRational ONE = new BigRational(BigInteger.ONE);
  final BigInteger num, den;

  BigRational(BigInteger num) {
    this.num = num;
    den = BigInteger.ONE;
  }

  BigRational(BigInteger num, BigInteger den) {
    switch (den.signum()) {
      case -1 -> {
        num = num.negate();
        den = den.negate();
      }
      case 0 -> throw new ArithmeticException();
    }
    var g = num.gcd(den);
    num = num.divide(g);
    den = den.divide(g);
    this.num = num;
    this.den = den;
  }

  BigRational add(BigRational b) {
    return new BigRational(num.multiply(b.den).add(b.num.multiply(den)), den.multiply(b.den));
  }

  BigRational ceil() {
    return new BigRational(Etc.divFloor(num.add(den.subtract(BigInteger.ONE)), den));
  }

  public int compareTo(BigRational b) {
    return num.multiply(b.den).compareTo(b.num.multiply(den));
  }

  BigRational div(BigRational b) {
    return new BigRational(num.multiply(b.den), den.multiply(b.num));
  }

  BigRational divEuclidean(BigRational b) {
    return new BigRational(Etc.divEuclidean(num.multiply(b.den), den.multiply(b.num)));
  }

  public boolean equals(Object b) {
    if (this == b) return true;
    if (b == null || getClass() != b.getClass()) return false;
    var b1 = (BigRational) b;
    return num.equals(b1.num) && den.equals(b1.den);
  }

  public int hashCode() {
    return Objects.hash(num, den);
  }

  BigRational divFloor(BigRational b) {
    return new BigRational(Etc.divFloor(num.multiply(b.den), den.multiply(b.num)));
  }

  BigRational divTruncate(BigRational b) {
    return new BigRational(num.multiply(b.den).divide(den.multiply(b.num)));
  }

  public double doubleValue() {
    // Potential better algorithm:
    // https://stackoverflow.com/questions/33623875/converting-an-arbitrary-precision-rational-number-ocaml-zarith-to-an-approxim
    return num.doubleValue() / den.doubleValue();
  }

  public float floatValue() {
    return (float) doubleValue();
  }

  BigRational floor() {
    return new BigRational(Etc.divFloor(num, den));
  }

  public int intValue() {
    return num.divide(den).intValue();
  }

  public long longValue() {
    return num.divide(den).longValue();
  }

  BigRational mul(BigRational b) {
    return new BigRational(num.multiply(b.num), den.multiply(b.den));
  }

  BigRational neg() {
    return new BigRational(num.negate(), den);
  }

  static BigRational of(BigDecimal value) {
    var n = value.unscaledValue();
    var scale = value.scale();
    return (scale >= 0)
        ? new BigRational(n, BigInteger.TEN.pow(scale))
        : new BigRational(n.multiply(BigInteger.TEN.pow(-scale)));
  }

  static BigRational of(long num) {
    return new BigRational(BigInteger.valueOf(num));
  }

  static BigRational of(String s) {
    var v = s.split("/");
    var num = new BigInteger(v[0]);
    if (v.length == 1) return new BigRational(num);
    var den = new BigInteger(v[1]);
    return new BigRational(num, den);
  }

  static BigRational of(long num, long den) {
    return new BigRational(BigInteger.valueOf(num), BigInteger.valueOf(den));
  }

  static BigRational ofDecimal(String s) {
    return of(new BigDecimal(s));
  }

  BigRational remEuclidean(BigRational b) {
    return new BigRational(Etc.remEuclidean(num.multiply(b.den), den.multiply(b.num)));
  }

  BigRational remFloor(BigRational b) {
    return new BigRational(Etc.remFloor(num.multiply(b.den), den.multiply(b.num)));
  }

  BigRational remTruncate(BigRational b) {
    return new BigRational(num.multiply(b.den).remainder(den.multiply(b.num)));
  }

  BigRational round() {
    var n = num.shiftLeft(1).add(den);
    var d = den.shiftLeft(1);
    n = Etc.divFloor(n, d);
    if (num.testBit(0) && den.equals(BigInteger.TWO) && n.testBit(0)) {
      n = n.subtract(BigInteger.ONE);
    }
    return new BigRational(n);
  }

  BigRational sub(BigRational b) {
    return new BigRational(num.multiply(b.den).subtract(b.num.multiply(den)), den.multiply(b.den));
  }

  public String toString() {
    return num.toString() + '/' + den;
  }

  BigRational truncate() {
    return new BigRational(num.divide(den));
  }
}
