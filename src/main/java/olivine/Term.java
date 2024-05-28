package olivine;

import java.math.BigInteger;
import java.util.Objects;

public abstract class Term {
  static final Term NULL = new Null();

  static Term of(long value) {
    return new IntegerConstant(BigInteger.valueOf(value));
  }

  abstract Tag tag();

  private static final class Null extends Term {
    @Override
    Tag tag() {
      return Tag.NULL;
    }
  }

  private static final class IntegerConstant extends Term {
    private final BigInteger value;

    IntegerConstant(BigInteger value) {
      this.value = value;
    }

    @Override
    public String toString() {
      return value.toString();
    }

    @Override
    public boolean equals(Object o) {
      if (this == o) return true;
      if (o == null || getClass() != o.getClass()) return false;
      IntegerConstant that = (IntegerConstant) o;
      return Objects.equals(value, that.value);
    }

    @Override
    public int hashCode() {
      return Objects.hashCode(value);
    }

    @Override
    Tag tag() {
      return Tag.INTEGER;
    }
  }

  private static final class UnaryTerm extends Term {
    private final Tag tag;

    private UnaryTerm(Tag tag) {
      this.tag = tag;
    }

    @Override
    Tag tag() {
      return tag;
    }
  }
}
