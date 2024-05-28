package olivine;

import java.math.BigInteger;
import java.util.AbstractList;
import java.util.Objects;

public abstract class Term extends AbstractList<Term> {
  static final Term NULL = new Null();

  static Term intConstant(Type type, long value) {
    assert value >= 0;
    return new IntConstant(type, BigInteger.valueOf(value));
  }

  static Term floatConstant(Type type, String value) {
    return new FloatConstant(type, value);
  }

  abstract Tag tag();

  abstract Type type();

  Term fneg() {
    return new FNeg(this);
  }

  @Override
  public int size() {
    return 0;
  }

  @Override
  public Term get(int index) {
    throw new IndexOutOfBoundsException(String.format("%s, %s", this, index));
  }

  private static final class Null extends Term {
    @Override
    Tag tag() {
      return Tag.NULL;
    }

    @Override
    Type type() {
      return Type.PTR;
    }
  }

  private static final class IntConstant extends Term {
    private final Type type;
    private final BigInteger value;

    private IntConstant(Type type, BigInteger value) {
      this.type = type;
      this.value = value;
    }

    @Override
    Type type() {
      return type;
    }

    @Override
    public String toString() {
      return value.toString();
    }

    @Override
    public boolean equals(Object o) {
      if (this == o) return true;
      if (o == null || getClass() != o.getClass()) return false;
      IntConstant that = (IntConstant) o;
      return Objects.equals(value, that.value);
    }

    @Override
    public int hashCode() {
      return Objects.hashCode(value);
    }

    @Override
    Tag tag() {
      return Tag.INT;
    }
  }

  private static final class FloatConstant extends Term {
    private final Type type;
    private final String value;

    private FloatConstant(Type type, String value) {
      this.type = type;
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
      if (!super.equals(o)) return false;
      FloatConstant terms = (FloatConstant) o;
      return Objects.equals(value, terms.value);
    }

    @Override
    public int hashCode() {
      return Objects.hash(super.hashCode(), value);
    }

    @Override
    Type type() {
      return type;
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
    Type type() {
      return arg.type();
    }

    @Override
    public int size() {
      return 1;
    }

    @Override
    public Term get(int index) {
      if (index != 0) throw new IndexOutOfBoundsException(String.format("%s, %s", this, index));
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
    Type type() {
      return arg0.type();
    }

    @Override
    public int size() {
      return 2;
    }

    @Override
    public Term get(int index) {
      if (!(0 <= index && index < 2))
        throw new IndexOutOfBoundsException(String.format("%s, %s", this, index));
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
