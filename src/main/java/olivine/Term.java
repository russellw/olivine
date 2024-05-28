package olivine;

import java.math.BigInteger;
import java.util.AbstractList;
import java.util.Objects;

public abstract class Term extends AbstractList<Term> {
  static final Term NULL = new Null();

  static Term of(long value) {
    return new IntegerConstant(BigInteger.valueOf(value));
  }

  static Term floatConstant(String value) {
    return new FloatConstant(value);
  }

  abstract Tag tag();

  Term fneg() {
    return new FNeg(this);
  }

  @Override
  public int size() {
    return 0;
  }

  @Override
  public Term get(int index) {
    throw new UnsupportedOperationException(toString());
  }

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

  private static final class FloatConstant extends Term {
    private final String value;

    FloatConstant(String value) {
      this.value = value;
    }

    @Override
    public String toString() {
      return value;
    }

    @Override
    public boolean equals(Object o) {
      if (this == o) return true;
      if (o == null || getClass() != o.getClass()) return false;
      FloatConstant that = (FloatConstant) o;
      return Objects.equals(value, that.value);
    }

    @Override
    public int hashCode() {
      return Objects.hashCode(value);
    }

    @Override
    Tag tag() {
      return Tag.FLOAT;
    }
  }

  private abstract static class UnaryTerm extends Term {
    private final Term arg;

    private UnaryTerm(Term arg) {
      this.arg = arg;
    }

    @Override
    public int size() {
      return 1;
    }

    @Override
    public Term get(int index) {
      assert 0 <= index && index < size();
      return arg;
    }
  }

  private static final class FNeg extends UnaryTerm {
    FNeg(Term arg) {
      super(arg);
    }

    @Override
    Tag tag() {
      return Tag.FNEG;
    }
  }

  private abstract static class BinaryTerm extends Term {
    private final Term arg0, arg1;

    BinaryTerm(Term arg0, Term arg1) {
      this.arg0 = arg0;
      this.arg1 = arg1;
    }

    @Override
    public int size() {
      return 2;
    }

    @Override
    public Term get(int index) {
      assert 0 <= index && index < size();
      return index == 0 ? arg0 : arg1;
    }
  }

  private static final class Add extends BinaryTerm {
    Add(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    Tag tag() {
      return Tag.ADD;
    }
  }
}
