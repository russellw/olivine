import java.math.BigInteger;

public class BigRationalTest {
  public static void main(String[] args) {
    assert BigRational.of("123").equals(new BigRational(BigInteger.valueOf(123), BigInteger.ONE));
    assert BigRational.of("+123").equals(new BigRational(BigInteger.valueOf(123), BigInteger.ONE));
    assert BigRational.of("-123").equals(new BigRational(BigInteger.valueOf(-123), BigInteger.ONE));
    assert BigRational.of("123/456")
        .equals(new BigRational(BigInteger.valueOf(123), BigInteger.valueOf(456)));

    assert BigRational.ofDecimal("123")
        .equals(new BigRational(BigInteger.valueOf(123), BigInteger.ONE));
    assert BigRational.ofDecimal("+123")
        .equals(new BigRational(BigInteger.valueOf(123), BigInteger.ONE));
    assert BigRational.ofDecimal("-123")
        .equals(new BigRational(BigInteger.valueOf(-123), BigInteger.ONE));
    assert BigRational.ofDecimal("123.456")
        .equals(new BigRational(BigInteger.valueOf(123456), BigInteger.valueOf(1000)));
    assert BigRational.ofDecimal("123.456e3")
        .equals(new BigRational(BigInteger.valueOf(123456), BigInteger.valueOf(1)));
    assert BigRational.ofDecimal("123.456e-3")
        .equals(new BigRational(BigInteger.valueOf(123456), BigInteger.valueOf(1000000)));

    assert BigRational.of("0").ceil().equals(BigRational.ZERO);
    assert BigRational.of("1/10").ceil().equals(BigRational.ONE);
    assert BigRational.of("5/10").ceil().equals(BigRational.ONE);
    assert BigRational.of("9/10").ceil().equals(BigRational.ONE);
    assert BigRational.of("-1/10").ceil().equals(BigRational.ZERO);
    assert BigRational.of("-5/10").ceil().equals(BigRational.ZERO);
    assert BigRational.of("-9/10").ceil().equals(BigRational.ZERO);

    assert BigRational.of("0").floor().equals(BigRational.ZERO);
    assert BigRational.of("1/10").floor().equals(BigRational.ZERO);
    assert BigRational.of("5/10").floor().equals(BigRational.ZERO);
    assert BigRational.of("9/10").floor().equals(BigRational.ZERO);
    assert BigRational.of("-1/10").floor().equals(BigRational.ONE.neg());
    assert BigRational.of("-5/10").floor().equals(BigRational.ONE.neg());
    assert BigRational.of("-9/10").floor().equals(BigRational.ONE.neg());

    assert BigRational.of("0").round().equals(BigRational.ZERO);
    assert BigRational.of("1/10").round().equals(BigRational.ZERO);
    assert BigRational.of("5/10").round().equals(BigRational.ZERO);
    assert BigRational.of("9/10").round().equals(BigRational.ONE);
    assert BigRational.of("-1/10").round().equals(BigRational.ZERO);
    assert BigRational.of("-5/10").round().equals(BigRational.ZERO);

    assert BigRational.of("-9/10").round().equals(BigRational.ONE.neg());

    assert BigRational.of("0").truncate().equals(BigRational.ZERO);
    assert BigRational.of("1/10").truncate().equals(BigRational.ZERO);
    assert BigRational.of("5/10").truncate().equals(BigRational.ZERO);
    assert BigRational.of("9/10").truncate().equals(BigRational.ZERO);
    assert BigRational.of("-1/10").truncate().equals(BigRational.ZERO);
    assert BigRational.of("-5/10").truncate().equals(BigRational.ZERO);
    assert BigRational.of("-9/10").truncate().equals(BigRational.ZERO);

    assert BigRational.of(7)
        .divEuclidean(BigRational.of(3))
        .equals(new BigRational(BigInteger.valueOf(2)));
    assert BigRational.of(7)
        .divEuclidean(BigRational.of(-3))
        .equals(new BigRational(BigInteger.valueOf(-2)));
    assert BigRational.of(-7)
        .divEuclidean(BigRational.of(3))
        .equals(new BigRational(BigInteger.valueOf(-3)));
    assert BigRational.of(-7)
        .divEuclidean(BigRational.of(-3))
        .equals(new BigRational(BigInteger.valueOf(3)));

    assert BigRational.of(7)
        .remEuclidean(BigRational.of(3))
        .equals(new BigRational(BigInteger.valueOf(1)));
    assert BigRational.of(7)
        .remEuclidean(BigRational.of(-3))
        .equals(new BigRational(BigInteger.valueOf(1)));
    assert BigRational.of(-7)
        .remEuclidean(BigRational.of(3))
        .equals(new BigRational(BigInteger.valueOf(2)));
    assert BigRational.of(-7)
        .remEuclidean(BigRational.of(-3))
        .equals(new BigRational(BigInteger.valueOf(2)));

    assert BigRational.of(5)
        .divFloor(BigRational.of(3))
        .equals(new BigRational(BigInteger.valueOf(1)));
    assert BigRational.of(5)
        .divFloor(BigRational.of(-3))
        .equals(new BigRational(BigInteger.valueOf(-2)));

    assert BigRational.of(-5)
        .divFloor(BigRational.of(3))
        .equals(new BigRational(BigInteger.valueOf(-2)));
    assert BigRational.of(-5)
        .divFloor(BigRational.of(-3))
        .equals(new BigRational(BigInteger.valueOf(1)));

    assert BigRational.of(5)
        .remFloor(BigRational.of(3))
        .equals(new BigRational(BigInteger.valueOf(2)));
    assert BigRational.of(5)
        .remFloor(BigRational.of(-3))
        .equals(new BigRational(BigInteger.valueOf(-1)));
    assert BigRational.of(-5)
        .remFloor(BigRational.of(3))
        .equals(new BigRational(BigInteger.valueOf(1)));
    assert BigRational.of(-5)
        .remFloor(BigRational.of(-3))
        .equals(new BigRational(BigInteger.valueOf(-2)));

    assert BigRational.of(5)
        .divTruncate(BigRational.of(3))
        .equals(new BigRational(BigInteger.valueOf(5 / 3)));
    assert BigRational.of(5)
        .divTruncate(BigRational.of(-3))
        .equals(new BigRational(BigInteger.valueOf(5 / -3)));
    assert BigRational.of(-5)
        .divTruncate(BigRational.of(3))
        .equals(new BigRational(BigInteger.valueOf(-5 / 3)));
    assert BigRational.of(-5)
        .divTruncate(BigRational.of(-3))
        .equals(new BigRational(BigInteger.valueOf(-5 / -3)));

    assert BigRational.of(5)
        .remTruncate(BigRational.of(3))
        .equals(new BigRational(BigInteger.valueOf(5 % 3)));
    assert BigRational.of(5)
        .remTruncate(BigRational.of(-3))
        .equals(new BigRational(BigInteger.valueOf(5 % -3)));
    assert BigRational.of(-5)
        .remTruncate(BigRational.of(3))
        .equals(new BigRational(BigInteger.valueOf(-5 % 3)));

    assert BigRational.of(-5)
        .remTruncate(BigRational.of(-3))
        .equals(new BigRational(BigInteger.valueOf(-5 % -3)));

    assert BigRational.of("1").add(BigRational.of("2")).equals(BigRational.of("3"));
    assert BigRational.of("1/3").add(BigRational.of("2/3")).equals(BigRational.of("1"));
    assert BigRational.ofDecimal("0.1")
        .add(BigRational.ofDecimal("0.2"))
        .equals(BigRational.ofDecimal("0.3"));
    assert BigRational.ofDecimal("0.1")
        .add(BigRational.ofDecimal("-0.2"))
        .equals(BigRational.ofDecimal("-0.1"));

    assert BigRational.of("1").sub(BigRational.of("2")).equals(BigRational.of("-1"));
    assert BigRational.of("1/3").sub(BigRational.of("2/3")).equals(BigRational.of("-1/3"));
    assert BigRational.ofDecimal("0.1")
        .sub(BigRational.ofDecimal("0.2"))
        .equals(BigRational.ofDecimal("-0.1"));
    assert BigRational.ofDecimal("0.1")
        .sub(BigRational.ofDecimal("-0.2"))
        .equals(BigRational.ofDecimal("0.3"));

    assert BigRational.of("1").mul(BigRational.of("2")).equals(BigRational.of("2"));
    assert BigRational.of("1/3").mul(BigRational.of("2/3")).equals(BigRational.of("2/9"));
    assert BigRational.ofDecimal("0.1")
        .mul(BigRational.ofDecimal("0.2"))
        .equals(BigRational.ofDecimal("0.02"));
    assert BigRational.ofDecimal("0.1")
        .mul(BigRational.ofDecimal("-0.2"))
        .equals(BigRational.ofDecimal("-0.02"));

    assert BigRational.of("1").div(BigRational.of("2")).equals(BigRational.of("1/2"));
    assert BigRational.of("1/3").div(BigRational.of("2/3")).equals(BigRational.of("1/2"));
    assert BigRational.ofDecimal("0.1")
        .div(BigRational.ofDecimal("0.2"))
        .equals(BigRational.ofDecimal("0.5"));
    assert BigRational.ofDecimal("0.1")
        .div(BigRational.ofDecimal("-0.2"))
        .equals(BigRational.ofDecimal("-0.5"));

    assert BigRational.of("0").equals(BigRational.of("-0"));
    assert BigRational.of("1/3").equals(BigRational.of("2/6"));

    assert BigRational.of("1/10").equals(BigRational.ofDecimal("0.1"));
    assert BigRational.of("1/10").equals(BigRational.ofDecimal("0.10"));
    assert BigRational.of("-1/10").equals(BigRational.ofDecimal("-0.10"));
    assert !BigRational.of("0").equals(BigRational.of("1"));
    assert !BigRational.of("1").equals(BigRational.of("-1"));
    assert !BigRational.ofDecimal("1e1000")
        .equals(BigRational.ofDecimal("1e1000").sub(BigRational.ONE));

    assert BigRational.of("-1").compareTo(BigRational.of("0")) < 0;
    assert BigRational.of("0").compareTo(BigRational.of("0")) == 0;
    assert BigRational.of("1").compareTo(BigRational.of("0")) > 0;
    assert BigRational.of("1").compareTo(BigRational.of("2")) < 0;
    assert BigRational.of("-1").compareTo(BigRational.of("-2")) > 0;
    assert BigRational.of("1/8").compareTo(BigRational.of("1/9")) > 0;
    assert BigRational.of("-1/8").compareTo(BigRational.of("-1/9")) < 0;
    assert BigRational.of(3, 4).compareTo(BigRational.of(5, 7)) > 0;

    assert BigRational.of(1, 999).neg().equals(BigRational.of("-1/999"));
  }
}
