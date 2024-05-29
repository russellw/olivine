package olivine;

import java.math.BigInteger;
import java.util.Iterator;
import java.util.NoSuchElementException;
import java.util.Objects;

public abstract class Term implements Iterable<Term> {
  static final Term NULL = new Null();
  static final Term TRUE = intConstant(Type.BOOL, 1);
  static final Term FALSE = intConstant(Type.BOOL, 0);

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

  Term add(Term b) {
    return new Add(this, b);
  }

  public int size() {
    return 0;
  }

  @Override
  public Iterator<Term> iterator() {
    return new Iterator0();
  }

  public Term get(int index) {
    throw new IndexOutOfBoundsException("%s, %s".formatted(this, index));
  }

  private static class Iterator0 implements Iterator<Term> {
    @Override
    public boolean hasNext() {
      return false;
    }

    @Override
    public Term next() {
      throw new NoSuchElementException();
    }
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
      IntConstant terms = (IntConstant) o;
      return Objects.equals(value, terms.value);
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
      FloatConstant terms = (FloatConstant) o;
      return Objects.equals(value, terms.value);
    }

    @Override
    public int hashCode() {
      return Objects.hashCode(value);
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

  private abstract static class Term1 extends Term {
    private final Term arg;

    private Term1(Term arg) {
      this.arg = arg;
    }

    @Override
    Type type() {
      return arg.type();
    }

    @Override
    public boolean equals(Object o) {
      if (this == o) return true;
      if (o == null || getClass() != o.getClass()) return false;
      Term1 terms = (Term1) o;
      return Objects.equals(arg, terms.arg);
    }

    @Override
    public int hashCode() {
      return Objects.hashCode(arg);
    }

    @Override
    public int size() {
      return 1;
    }

    @Override
    public Term get(int index) {
      if (index != 0) throw new IndexOutOfBoundsException("%s, %s".formatted(this, index));
      return arg;
    }

    @Override
    public Iterator<Term> iterator() {
      return new Iterator1(this);
    }

    private static final class Iterator1 implements Iterator<Term> {
      private final Term1 term;
      private int position;

      public Iterator1(Term1 term) {
        this.term = term;
        this.position = 0;
      }

      @Override
      public boolean hasNext() {
        return position == 0;
      }

      @Override
      public Term next() {
        return term.get(position++);
      }
    }
  }

  private static final class FNeg extends Term1 {
    FNeg(Term arg) {
      super(arg);
    }

    @Override
    Tag tag() {
      return Tag.FNEG;
    }
  }

  private abstract static class Term2 extends Term {
    private final Term arg0, arg1;

    Term2(Term arg0, Term arg1) {
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
    public boolean equals(Object o) {
      if (this == o) return true;
      if (o == null || getClass() != o.getClass()) return false;
      Term2 terms = (Term2) o;
      return Objects.equals(arg0, terms.arg0) && Objects.equals(arg1, terms.arg1);
    }

    @Override
    public int hashCode() {
      return Objects.hash(arg0, arg1);
    }

    @Override
    public Term get(int index) {
      return switch (index) {
        case 0 -> arg0;
        case 1 -> arg1;
        default -> throw new IndexOutOfBoundsException("%s, %s".formatted(this, index));
      };
    }

    @Override
    public Iterator<Term> iterator() {
      return new Iterator2(this);
    }

    private static final class Iterator2 implements Iterator<Term> {
      private final Term2 term;
      private int position;

      public Iterator2(Term2 term) {
        this.term = term;
        this.position = 0;
      }

      @Override
      public boolean hasNext() {
        return position < 2;
      }

      @Override
      public Term next() {
        return term.get(position++);
      }
    }
  }

  private static final class Add extends Term2 {
    Add(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    Tag tag() {
      return Tag.ADD;
    }
  }
}
