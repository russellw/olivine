package olivine;

import java.math.BigInteger;
import java.util.*;

public abstract class Term implements Iterable<Term> {
  static final Term NULL = new Null();
  static final Term ONE = intConstant(Type.I32, 1);
  static final Term TRUE = intConstant(Type.I1, 1);
  static final Term FALSE = intConstant(Type.I1, 0);

  static Term zeroinitializer(Type type) {
    return switch (type.kind()) {
      case INT -> intConstant(type, 0);
      case ARRAY -> {
        var count = type.count();
        type = type.get(0);
        var elements = new Term[count];
        Arrays.fill(elements, zeroinitializer(type));
        yield array(type, elements);
      }
      default -> {
        if (type.isFloat()) yield floatConstant(type, "0");
        throw new IllegalArgumentException(type.toString());
      }
    };
  }

  static Term intConstant(Type type, long value) {
    assert value >= 0;
    return new IntConstant(type, BigInteger.valueOf(value));
  }

  static Term intConstant(Type type, BigInteger value) {
    assert value.signum() >= 0;
    return new IntConstant(type, value);
  }

  static Term floatConstant(Type type, String value) {
    return new FloatConstant(type, value);
  }

  abstract Tag tag();

  abstract Type type();

  public static Term array(Type type, Term[] elements) {
    return new Array(type, elements);
  }

  Term fneg() {
    return new FNeg(this);
  }

  Term addr() {
    return new Addr(this);
  }

  Term load(Type type) {
    return new Load(type, this);
  }

  Term cast(Type type) {
    return new Cast(this, type);
  }

  Term scast(Type type) {
    return new SCast(this, type);
  }

  Term feq(Term b) {
    return new FEq(this, b);
  }

  Term fne(Term b) {
    return new FNe(this, b);
  }

  Term fle(Term b) {
    return new FLe(this, b);
  }

  Term flt(Term b) {
    return new FLt(this, b);
  }

  Term eq(Term b) {
    return new Eq(this, b);
  }

  Term ne(Term b) {
    return new Ne(this, b);
  }

  Term sle(Term b) {
    return new SLe(this, b);
  }

  Term slt(Term b) {
    return new SLt(this, b);
  }

  Term ule(Term b) {
    return new ULe(this, b);
  }

  Term ult(Term b) {
    return new ULt(this, b);
  }

  Term add(Term b) {
    return new Add(this, b);
  }

  Term fadd(Term b) {
    return new FAdd(this, b);
  }

  Term fsub(Term b) {
    return new FSub(this, b);
  }

  Term fmul(Term b) {
    return new FMul(this, b);
  }

  Term fdiv(Term b) {
    return new FDiv(this, b);
  }

  Term frem(Term b) {
    return new FRem(this, b);
  }

  Term sub(Term b) {
    return new Sub(this, b);
  }

  Term mul(Term b) {
    return new Mul(this, b);
  }

  Term udiv(Term b) {
    return new UDiv(this, b);
  }

  Term sdiv(Term b) {
    return new SDiv(this, b);
  }

  Term urem(Term b) {
    return new URem(this, b);
  }

  Term and(Term b) {
    return new And(this, b);
  }

  Term or(Term b) {
    return new Or(this, b);
  }

  Term xor(Term b) {
    return new Xor(this, b);
  }

  Term shl(Term b) {
    return new Shl(this, b);
  }

  Term ashr(Term b) {
    return new AShr(this, b);
  }

  Term lshr(Term b) {
    return new LShr(this, b);
  }

  Term srem(Term b) {
    return new SRem(this, b);
  }

  Term select(Term ifTrue, Term ifFalse) {
    return new Select(this, ifTrue, ifFalse);
  }

  Term call(List<Term> args) {
    var terms = new Term[1 + args.size()];
    terms[0] = this;
    for (var i = 0; i < args.size(); i++) terms[1 + i] = args.get(i);
    return new Call(terms);
  }

  public int size() {
    return 0;
  }

  @Override
  public Iterator<Term> iterator() {
    return Collections.emptyIterator();
  }

  public Term get(int i) {
    throw new IndexOutOfBoundsException("%s, %s".formatted(this, i));
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

  int intValueExact() {
    throw new UnsupportedOperationException(toString());
  }

  private static final class IntConstant extends Term {
    private final Type type;
    private final BigInteger value;

    private IntConstant(Type type, BigInteger value) {
      this.type = type;
      this.value = value;
    }

    @Override
    int intValueExact() {
      return value.intValueExact();
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
    public Term get(int i) {
      // TODO: assert?
      if (i != 0) throw new IndexOutOfBoundsException("%s, %s".formatted(this, i));
      return arg;
    }

    @Override
    public Iterator<Term> iterator() {
      return Collections.singletonList(arg).iterator();
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

  private static final class Addr extends Term1 {
    Addr(Term arg) {
      super(arg);
    }

    @Override
    Type type() {
      return Type.PTR;
    }

    @Override
    Tag tag() {
      return Tag.ADDR;
    }
  }

  private static final class Load extends Term1 {
    private final Type type;

    Load(Type type, Term pointer) {
      super(pointer);
      this.type = type;
    }

    @Override
    public boolean equals(Object o) {
      if (this == o) return true;
      if (o == null || getClass() != o.getClass()) return false;
      if (!super.equals(o)) return false;
      Load terms = (Load) o;
      return Objects.equals(type, terms.type);
    }

    @Override
    public int hashCode() {
      return Objects.hash(super.hashCode(), type);
    }

    @Override
    Type type() {
      return type;
    }

    @Override
    Tag tag() {
      return Tag.LOAD;
    }
  }

  static Term alloca(Type type, Term numElements) {
    return new Alloca(type, numElements);
  }

  private static final class Alloca extends Term1 {
    private final Type type;

    Alloca(Type type, Term numElements) {
      super(numElements);
      this.type = type;
    }

    @Override
    public boolean equals(Object o) {
      if (this == o) return true;
      if (o == null || getClass() != o.getClass()) return false;
      if (!super.equals(o)) return false;
      Alloca terms = (Alloca) o;
      return Objects.equals(type, terms.type);
    }

    @Override
    public int hashCode() {
      return Objects.hash(super.hashCode(), type);
    }

    @Override
    Type type() {
      return Type.PTR;
    }

    @Override
    Tag tag() {
      return Tag.ALLOCA;
    }
  }

  Term fieldPtr(Type type, int idx) {
    return new FieldPtr(type, this, idx);
  }

  private static final class FieldPtr extends Term1 {
    private final Type type;
    private final int idx;

    FieldPtr(Type type, Term ptrVal, int idx) {
      super(ptrVal);
      this.type = type;
      this.idx = idx;
    }

    @Override
    public boolean equals(Object o) {
      if (this == o) return true;
      if (o == null || getClass() != o.getClass()) return false;
      if (!super.equals(o)) return false;
      FieldPtr terms = (FieldPtr) o;
      return idx == terms.idx && Objects.equals(type, terms.type);
    }

    @Override
    public int hashCode() {
      return Objects.hash(super.hashCode(), type, idx);
    }

    @Override
    Type type() {
      return Type.PTR;
    }

    @Override
    Tag tag() {
      return Tag.FIELD_PTR;
    }
  }

  Term elementPtr(Type type, Term idx) {
    return new ElementPtr(type, this, idx);
  }

  private static final class ElementPtr extends Term2 {
    private final Type type;

    ElementPtr(Type type, Term ptrVal, Term idx) {
      super(ptrVal, idx);
      this.type = type;
    }

    @Override
    public boolean equals(Object o) {
      if (this == o) return true;
      if (o == null || getClass() != o.getClass()) return false;
      if (!super.equals(o)) return false;
      ElementPtr terms = (ElementPtr) o;
      return Objects.equals(type, terms.type);
    }

    @Override
    public int hashCode() {
      return Objects.hash(super.hashCode(), type);
    }

    @Override
    Type type() {
      return Type.PTR;
    }

    @Override
    Tag tag() {
      return Tag.ELEMENT_PTR;
    }
  }

  private static final class Cast extends Term1 {
    private final Type type;

    Cast(Term arg, Type type) {
      super(arg);
      this.type = type;
    }

    @Override
    public boolean equals(Object o) {
      if (this == o) return true;
      if (o == null || getClass() != o.getClass()) return false;
      if (!super.equals(o)) return false;
      Cast terms = (Cast) o;
      return Objects.equals(type, terms.type);
    }

    @Override
    public int hashCode() {
      return Objects.hash(super.hashCode(), type);
    }

    @Override
    Type type() {
      return type;
    }

    @Override
    Tag tag() {
      return Tag.CAST;
    }
  }

  private static final class SCast extends Term1 {
    private final Type type;

    SCast(Term arg, Type type) {
      super(arg);
      this.type = type;
    }

    @Override
    public boolean equals(Object o) {
      if (this == o) return true;
      if (o == null || getClass() != o.getClass()) return false;
      if (!super.equals(o)) return false;
      SCast terms = (SCast) o;
      return Objects.equals(type, terms.type);
    }

    @Override
    public int hashCode() {
      return Objects.hash(super.hashCode(), type);
    }

    @Override
    Type type() {
      return type;
    }

    @Override
    Tag tag() {
      return Tag.SCAST;
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
    public Term get(int i) {
      return switch (i) {
        case 0 -> arg0;
        case 1 -> arg1;
        default -> throw new IndexOutOfBoundsException("%s, %s".formatted(this, i));
      };
    }

    @Override
    public Iterator<Term> iterator() {
      return Arrays.asList(arg0, arg1).iterator();
    }
  }

  private static final class Eq extends Term2 {
    Eq(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    Tag tag() {
      return Tag.EQ;
    }
  }

  private static final class Ne extends Term2 {
    Ne(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    Tag tag() {
      return Tag.NE;
    }
  }

  private static final class SLe extends Term2 {
    SLe(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    Tag tag() {
      return Tag.SLE;
    }
  }

  private static final class SLt extends Term2 {
    SLt(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    Tag tag() {
      return Tag.SLT;
    }
  }

  private static final class ULe extends Term2 {
    ULe(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    Tag tag() {
      return Tag.ULE;
    }
  }

  private static final class ULt extends Term2 {
    ULt(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    Tag tag() {
      return Tag.ULT;
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

  private static final class FEq extends Term2 {
    FEq(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    Tag tag() {
      return Tag.FEQ;
    }
  }

  private static final class FNe extends Term2 {
    FNe(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    Tag tag() {
      return Tag.FNE;
    }
  }

  private static final class FLe extends Term2 {
    FLe(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    Tag tag() {
      return Tag.FLE;
    }
  }

  private static final class FLt extends Term2 {
    FLt(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    Tag tag() {
      return Tag.FLT;
    }
  }

  private static final class Sub extends Term2 {
    Sub(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    Tag tag() {
      return Tag.SUB;
    }
  }

  private static final class Mul extends Term2 {
    Mul(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    Tag tag() {
      return Tag.MUL;
    }
  }

  private static final class UDiv extends Term2 {
    UDiv(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    Tag tag() {
      return Tag.UDIV;
    }
  }

  private static final class SDiv extends Term2 {
    SDiv(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    Tag tag() {
      return Tag.SDIV;
    }
  }

  private static final class URem extends Term2 {
    URem(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    Tag tag() {
      return Tag.UREM;
    }
  }

  private static final class SRem extends Term2 {
    SRem(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    Tag tag() {
      return Tag.SREM;
    }
  }

  private static final class FAdd extends Term2 {
    FAdd(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    Tag tag() {
      return Tag.FADD;
    }
  }

  private static final class FSub extends Term2 {
    FSub(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    Tag tag() {
      return Tag.FSUB;
    }
  }

  private static final class FMul extends Term2 {
    FMul(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    Tag tag() {
      return Tag.FMUL;
    }
  }

  private static final class FDiv extends Term2 {
    FDiv(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    Tag tag() {
      return Tag.FDIV;
    }
  }

  private static final class FRem extends Term2 {
    FRem(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    Tag tag() {
      return Tag.FREM;
    }
  }

  private static final class And extends Term2 {
    And(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    Tag tag() {
      return Tag.AND;
    }
  }

  private static final class Or extends Term2 {
    Or(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    Tag tag() {
      return Tag.OR;
    }
  }

  private static final class Xor extends Term2 {
    Xor(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    Tag tag() {
      return Tag.XOR;
    }
  }

  private static final class Shl extends Term2 {
    Shl(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    Tag tag() {
      return Tag.SHL;
    }
  }

  private static final class AShr extends Term2 {
    AShr(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    Tag tag() {
      return Tag.ASHR;
    }
  }

  private static final class LShr extends Term2 {
    LShr(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    Tag tag() {
      return Tag.LSHR;
    }
  }

  private abstract static class Term3 extends Term {
    final Term arg0, arg1, arg2;

    Term3(Term arg0, Term arg1, Term arg2) {
      this.arg0 = arg0;
      this.arg1 = arg1;
      this.arg2 = arg2;
    }

    @Override
    public int size() {
      return 3;
    }

    @Override
    public boolean equals(Object o) {
      if (this == o) return true;
      if (o == null || getClass() != o.getClass()) return false;
      Term3 terms = (Term3) o;
      return Objects.equals(arg0, terms.arg0)
          && Objects.equals(arg1, terms.arg1)
          && Objects.equals(arg2, terms.arg2);
    }

    @Override
    public int hashCode() {
      return Objects.hash(arg0, arg1, arg2);
    }

    @Override
    public Term get(int i) {
      return switch (i) {
        case 0 -> arg0;
        case 1 -> arg1;
        case 2 -> arg2;
        default -> throw new IndexOutOfBoundsException("%s, %s".formatted(this, i));
      };
    }

    @Override
    public Iterator<Term> iterator() {
      return Arrays.asList(arg0, arg1, arg2).iterator();
    }
  }

  public static final class Select extends Term3 {
    Select(Term cond, Term ifTrue, Term ifFalse) {
      super(cond, ifTrue, ifFalse);
    }

    @Override
    Tag tag() {
      return Tag.SELECT;
    }

    @Override
    Type type() {
      return arg1.type();
    }
  }

  // TODO: names
  private abstract static class Terms extends Term {
    final Term[] terms;

    Terms(Term[] terms) {
      this.terms = terms;
    }

    @Override
    public boolean equals(Object o) {
      if (this == o) return true;
      if (o == null || getClass() != o.getClass()) return false;
      Terms terms1 = (Terms) o;
      return Objects.deepEquals(terms, terms1.terms);
    }

    @Override
    public int hashCode() {
      return Arrays.hashCode(terms);
    }

    @Override
    public Term get(int i) {
      return terms[i];
    }

    @Override
    public int size() {
      return terms.length;
    }

    @Override
    public Iterator<Term> iterator() {
      return Arrays.asList(terms).iterator();
    }
  }

  private static final class Call extends Terms {
    Call(Term[] terms) {
      super(terms);
    }

    @Override
    Tag tag() {
      return Tag.CALL;
    }

    @Override
    Type type() {
      throw new UnsupportedOperationException(toString());
    }
  }

  private static final class Array extends Terms {
    private final Type type;

    Array(Type type, Term[] elements) {
      super(elements);
      this.type = type;
    }

    @Override
    public boolean equals(Object o) {
      if (this == o) return true;
      if (o == null || getClass() != o.getClass()) return false;
      if (!super.equals(o)) return false;
      Array terms = (Array) o;
      return Objects.equals(type, terms.type);
    }

    @Override
    public int hashCode() {
      return Objects.hash(super.hashCode(), type);
    }

    @Override
    Tag tag() {
      return Tag.ARRAY;
    }

    @Override
    Type type() {
      return type.array(terms.length);
    }
  }
}
