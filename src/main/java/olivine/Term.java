package olivine;

import java.math.BigInteger;
import java.util.*;

// TODO: element/terms name
public abstract class Term implements Iterable<Term> {
  private static final class AShr extends BinaryTerm {
    public AShr(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    public Term rewrite(Term[] terms) {
      assert terms.length == 2;
      return new AShr(terms[0], terms[1]);
    }

    @Override
    public Tag tag() {
      return Tag.ASHR;
    }
  }

  private static final class Add extends BinaryTerm {
    public Add(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    public Term rewrite(Term[] terms) {
      assert terms.length == 2;
      return new Add(terms[0], terms[1]);
    }

    @Override
    public Tag tag() {
      return Tag.ADD;
    }
  }

  private static final class Addr extends UnaryTerm {
    public Addr(Term arg) {
      super(arg);
    }

    @Override
    public Term rewrite(Term[] terms) {
      assert terms.length == 1;
      return new Addr(terms[0]);
    }

    @Override
    public Tag tag() {
      return Tag.ADDR;
    }

    @Override
    public Type type() {
      return Type.PTR;
    }
  }

  private static final class Alloca extends UnaryTerm {
    private final Type type;

    public Alloca(Type type, Term numElements) {
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
    public Term rewrite(Term[] terms) {
      assert terms.length == 1;
      return new Alloca(type, terms[0]);
    }

    @Override
    public Tag tag() {
      return Tag.ALLOCA;
    }

    @Override
    public String toString() {
      return "alloca(%s, %s)".formatted(type, arg);
    }

    @Override
    public Type type() {
      return Type.PTR;
    }
  }

  private static final class And extends BinaryTerm {
    public And(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    public Term rewrite(Term[] terms) {
      assert terms.length == 2;
      return new And(terms[0], terms[1]);
    }

    @Override
    public Tag tag() {
      return Tag.AND;
    }
  }

  private static final class Array extends NaryTerm {
    private final Type type;

    public Array(Type type, Term[] elements) {
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
    public Term rewrite(Term[] terms) {
      return new Array(type, terms);
    }

    @Override
    public Tag tag() {
      return Tag.ARRAY;
    }

    @Override
    public String toString() {
      var sb = new StringBuilder();
      sb.append('[');
      var more = false;
      for (var element : terms) {
        if (more) sb.append(", ");
        more = true;
        sb.append(element.type());
        sb.append(' ');
        sb.append(element);
      }
      sb.append(']');
      return sb.toString();
    }

    @Override
    public Type type() {
      return type.array(terms.length);
    }

    @Override
    public void verify() {
      super.verify();
      for (var element : terms) assert element.type().equals(type);
    }
  }

  private abstract static class BinaryTerm extends Term {
    public final Term arg0, arg1;

    public BinaryTerm(Term arg0, Term arg1) {
      this.arg0 = arg0;
      this.arg1 = arg1;
    }

    @Override
    public boolean equals(Object o) {
      if (this == o) return true;
      if (o == null || getClass() != o.getClass()) return false;
      BinaryTerm terms = (BinaryTerm) o;
      return Objects.equals(arg0, terms.arg0) && Objects.equals(arg1, terms.arg1);
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
    public int hashCode() {
      return Objects.hash(arg0, arg1);
    }

    @Override
    public Iterator<Term> iterator() {
      return Arrays.asList(arg0, arg1).iterator();
    }

    @Override
    public int size() {
      return 2;
    }

    @Override
    public Type type() {
      return arg0.type();
    }

    @Override
    public void verify() {
      super.verify();
      assert arg0.type().equals(arg1.type());
    }
  }

  private static final class Call extends NaryTerm {
    public Call(Term[] terms) {
      super(terms);
    }

    @Override
    public Term rewrite(Term[] terms) {
      return new Call(terms);
    }

    @Override
    public Tag tag() {
      return Tag.CALL;
    }

    @Override
    public Type type() {
      var function = (Function) terms[0];
      return function.returnType;
    }
  }

  private static final class Cast extends UnaryTerm {
    private final Type type;

    public Cast(Term arg, Type type) {
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
    public Term rewrite(Term[] terms) {
      assert terms.length == 1;
      return new Cast(terms[0], type);
    }

    @Override
    public Tag tag() {
      return Tag.CAST;
    }

    @Override
    public Type type() {
      return type;
    }
  }

  private static final class ElementPtr extends BinaryTerm {
    private final Type type;

    public ElementPtr(Type type, Term ptrVal, Term idx) {
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
    public Term rewrite(Term[] terms) {
      assert terms.length == 2;
      return new ElementPtr(type, terms[0], terms[1]);
    }

    @Override
    public Tag tag() {
      return Tag.ELEMENT_PTR;
    }

    @Override
    public String toString() {
      return "element_ptr(%s, %s, %s)".formatted(type, arg0, arg1);
    }

    @Override
    public Type type() {
      return Type.PTR;
    }

    @Override
    public void verify() {
      arg0.verify();
      arg1.verify();
      assert arg0.type() == Type.PTR;
      assert arg1.type().isInt();
    }
  }

  private static final class Eq extends BinaryTerm {
    public Eq(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    public Term rewrite(Term[] terms) {
      assert terms.length == 2;
      return new Eq(terms[0], terms[1]);
    }

    @Override
    public Tag tag() {
      return Tag.EQ;
    }

    @Override
    public Type type() {
      return Type.I1;
    }
  }

  private static final class FAdd extends BinaryTerm {
    public FAdd(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    public Term rewrite(Term[] terms) {
      assert terms.length == 2;
      return new FAdd(terms[0], terms[1]);
    }

    @Override
    public Tag tag() {
      return Tag.FADD;
    }

    @Override
    public void verify() {
      super.verify();
      assert arg0.type().isFloat();
    }
  }

  private static final class FDiv extends BinaryTerm {
    public FDiv(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    public Term rewrite(Term[] terms) {
      assert terms.length == 2;
      return new FDiv(terms[0], terms[1]);
    }

    @Override
    public Tag tag() {
      return Tag.FDIV;
    }

    @Override
    public void verify() {
      super.verify();
      assert arg0.type().isFloat();
    }
  }

  private static final class FEq extends BinaryTerm {
    public FEq(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    public Term rewrite(Term[] terms) {
      assert terms.length == 2;
      return new FEq(terms[0], terms[1]);
    }

    @Override
    public Tag tag() {
      return Tag.FEQ;
    }

    @Override
    public Type type() {
      return Type.I1;
    }

    @Override
    public void verify() {
      super.verify();
      assert arg0.type().isFloat();
    }
  }

  private static final class FLe extends BinaryTerm {
    public FLe(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    public Term rewrite(Term[] terms) {
      assert terms.length == 2;
      return new FLe(terms[0], terms[1]);
    }

    @Override
    public Tag tag() {
      return Tag.FLE;
    }

    @Override
    public Type type() {
      return Type.I1;
    }

    @Override
    public void verify() {
      super.verify();
      assert arg0.type().isFloat();
    }
  }

  private static final class FLt extends BinaryTerm {
    public FLt(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    public Term rewrite(Term[] terms) {
      assert terms.length == 2;
      return new FLt(terms[0], terms[1]);
    }

    @Override
    public Tag tag() {
      return Tag.FLT;
    }

    @Override
    public Type type() {
      return Type.I1;
    }

    @Override
    public void verify() {
      super.verify();
      assert arg0.type().isFloat();
    }
  }

  private static final class FMul extends BinaryTerm {
    public FMul(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    public Term rewrite(Term[] terms) {
      assert terms.length == 2;
      return new FMul(terms[0], terms[1]);
    }

    @Override
    public Tag tag() {
      return Tag.FMUL;
    }

    @Override
    public void verify() {
      super.verify();
      assert arg0.type().isFloat();
    }
  }

  private static final class FNe extends BinaryTerm {
    public FNe(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    public Term rewrite(Term[] terms) {
      assert terms.length == 2;
      return new FNe(terms[0], terms[1]);
    }

    @Override
    public Tag tag() {
      return Tag.FNE;
    }

    @Override
    public Type type() {
      return Type.I1;
    }

    @Override
    public void verify() {
      super.verify();
      assert arg0.type().isFloat();
    }
  }

  private static final class FNeg extends UnaryTerm {
    public FNeg(Term arg) {
      super(arg);
    }

    @Override
    public Term rewrite(Term[] terms) {
      assert terms.length == 1;
      return new FNeg(terms[0]);
    }

    @Override
    public Tag tag() {
      return Tag.FNEG;
    }

    @Override
    public void verify() {
      super.verify();
      assert arg.type().isFloat();
    }
  }

  private static final class FRem extends BinaryTerm {
    public FRem(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    public Term rewrite(Term[] terms) {
      assert terms.length == 2;
      return new FRem(terms[0], terms[1]);
    }

    @Override
    public Tag tag() {
      return Tag.FREM;
    }

    @Override
    public void verify() {
      super.verify();
      assert arg0.type().isFloat();
    }
  }

  private static final class FSub extends BinaryTerm {
    public FSub(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    public Term rewrite(Term[] terms) {
      assert terms.length == 2;
      return new FSub(terms[0], terms[1]);
    }

    @Override
    public Tag tag() {
      return Tag.FSUB;
    }

    @Override
    public void verify() {
      super.verify();
      assert arg0.type().isFloat();
    }
  }

  private static final class FieldPtr extends UnaryTerm {
    private final int idx;
    private final Type struct;

    public FieldPtr(Type struct, Term ptrVal, int idx) {
      super(ptrVal);
      this.struct = struct;
      this.idx = idx;
    }

    @Override
    public boolean equals(Object o) {
      if (this == o) return true;
      if (o == null || getClass() != o.getClass()) return false;
      if (!super.equals(o)) return false;
      FieldPtr terms = (FieldPtr) o;
      return idx == terms.idx && Objects.equals(struct, terms.struct);
    }

    @Override
    public int hashCode() {
      return Objects.hash(super.hashCode(), struct, idx);
    }

    @Override
    public int intValueExact() {
      return idx;
    }

    @Override
    public Term rewrite(Term[] terms) {
      assert terms.length == 1;
      return new FieldPtr(struct, terms[0], idx);
    }

    @Override
    public Type struct() {
      return struct;
    }

    @Override
    public Tag tag() {
      return Tag.FIELD_PTR;
    }

    @Override
    public String toString() {
      return "field_ptr(%s, %s, %d)".formatted(struct, arg, idx);
    }

    @Override
    public Type type() {
      return Type.PTR;
    }

    @Override
    public void verify() {
      arg.verify();
      assert arg.type() == Type.PTR;
      assert struct.kind() == Kind.STRUCT;
      assert 0 <= idx && idx < struct.size();
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
    public Tag tag() {
      return Tag.FLOAT;
    }

    @Override
    public String toString() {
      return value;
    }

    @Override
    public Type type() {
      return type;
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
    public int intValueExact() {
      return value.intValueExact();
    }

    @Override
    public Tag tag() {
      return Tag.INT;
    }

    @Override
    public String toString() {
      return value.toString();
    }

    @Override
    public Type type() {
      return type;
    }
  }

  private static final class LShr extends BinaryTerm {
    public LShr(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    public Term rewrite(Term[] terms) {
      assert terms.length == 2;
      return new LShr(terms[0], terms[1]);
    }

    @Override
    public Tag tag() {
      return Tag.LSHR;
    }
  }

  private static final class Load extends UnaryTerm {
    private final Type type;

    public Load(Type type, Term pointer) {
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
    public Term rewrite(Term[] terms) {
      assert terms.length == 1;
      return new Load(type, terms[0]);
    }

    @Override
    public Tag tag() {
      return Tag.LOAD;
    }

    @Override
    public String toString() {
      return "load(%s, %s)".formatted(type, arg);
    }

    @Override
    public Type type() {
      return type;
    }
  }

  private static final class Mul extends BinaryTerm {
    public Mul(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    public Term rewrite(Term[] terms) {
      assert terms.length == 2;
      return new Mul(terms[0], terms[1]);
    }

    @Override
    public Tag tag() {
      return Tag.MUL;
    }
  }

  // TODO: names
  private abstract static class NaryTerm extends Term {
    public final Term[] terms;

    public NaryTerm(Term[] terms) {
      this.terms = terms;
    }

    @Override
    public boolean equals(Object o) {
      if (this == o) return true;
      if (o == null || getClass() != o.getClass()) return false;
      NaryTerm terms1 = (NaryTerm) o;
      return Objects.deepEquals(terms, terms1.terms);
    }

    @Override
    public Term get(int i) {
      return terms[i];
    }

    @Override
    public int hashCode() {
      return Arrays.hashCode(terms);
    }

    @Override
    public Iterator<Term> iterator() {
      return Arrays.asList(terms).iterator();
    }

    @Override
    public int size() {
      return terms.length;
    }
  }

  private static final class Ne extends BinaryTerm {
    public Ne(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    public Term rewrite(Term[] terms) {
      assert terms.length == 2;
      return new Ne(terms[0], terms[1]);
    }

    @Override
    public Tag tag() {
      return Tag.NE;
    }

    @Override
    public Type type() {
      return Type.I1;
    }
  }

  private static final class Or extends BinaryTerm {
    public Or(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    public Term rewrite(Term[] terms) {
      assert terms.length == 2;
      return new Or(terms[0], terms[1]);
    }

    @Override
    public Tag tag() {
      return Tag.OR;
    }
  }

  private static final class SCast extends UnaryTerm {
    private final Type type;

    public SCast(Term arg, Type type) {
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
    public Term rewrite(Term[] terms) {
      assert terms.length == 1;
      return new SCast(terms[0], type);
    }

    @Override
    public Tag tag() {
      return Tag.SCAST;
    }

    @Override
    public Type type() {
      return type;
    }
  }

  private static final class SDiv extends BinaryTerm {
    public SDiv(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    public Term rewrite(Term[] terms) {
      assert terms.length == 2;
      return new SDiv(terms[0], terms[1]);
    }

    @Override
    public Tag tag() {
      return Tag.SDIV;
    }
  }

  private static final class SLe extends BinaryTerm {
    public SLe(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    public Term rewrite(Term[] terms) {
      assert terms.length == 2;
      return new SLe(terms[0], terms[1]);
    }

    @Override
    public Tag tag() {
      return Tag.SLE;
    }

    @Override
    public Type type() {
      return Type.I1;
    }
  }

  private static final class SLt extends BinaryTerm {
    public SLt(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    public Term rewrite(Term[] terms) {
      assert terms.length == 2;
      return new SLt(terms[0], terms[1]);
    }

    @Override
    public Tag tag() {
      return Tag.SLT;
    }

    @Override
    public Type type() {
      return Type.I1;
    }
  }

  private static final class SRem extends BinaryTerm {
    public SRem(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    public Term rewrite(Term[] terms) {
      assert terms.length == 2;
      return new SRem(terms[0], terms[1]);
    }

    @Override
    public Tag tag() {
      return Tag.SREM;
    }
  }

  public static final class Select extends TernaryTerm {
    public Select(Term cond, Term ifTrue, Term ifFalse) {
      super(cond, ifTrue, ifFalse);
    }

    @Override
    public Term rewrite(Term[] terms) {
      assert terms.length == 3;
      return new Select(terms[0], terms[1], terms[2]);
    }

    @Override
    public Tag tag() {
      return Tag.SELECT;
    }

    @Override
    public Type type() {
      return arg1.type();
    }

    @Override
    public void verify() {
      super.verify();
      assert arg0.type() == Type.I1;
      assert arg1.type().equals(arg2.type());
    }
  }

  private static final class Shl extends BinaryTerm {
    public Shl(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    public Term rewrite(Term[] terms) {
      assert terms.length == 2;
      return new Shl(terms[0], terms[1]);
    }

    @Override
    public Tag tag() {
      return Tag.SHL;
    }
  }

  private static final class Struct extends NaryTerm {
    private final Type type;

    public Struct(Type type, Term[] fields) {
      super(fields);
      this.type = type;
    }

    @Override
    public boolean equals(Object o) {
      if (this == o) return true;
      if (o == null || getClass() != o.getClass()) return false;
      if (!super.equals(o)) return false;
      Struct terms = (Struct) o;
      return Objects.equals(type, terms.type);
    }

    @Override
    public int hashCode() {
      return Objects.hash(super.hashCode(), type);
    }

    @Override
    public Term rewrite(Term[] terms) {
      return new Struct(type, terms);
    }

    @Override
    public Tag tag() {
      return Tag.STRUCT;
    }

    @Override
    public String toString() {
      var sb = new StringBuilder();
      sb.append('{');
      var more = false;
      for (var element : terms) {
        if (more) sb.append(", ");
        more = true;
        sb.append(element.type());
        sb.append(' ');
        sb.append(element);
      }
      sb.append('}');
      return sb.toString();
    }

    @Override
    public Type type() {
      return type;
    }

    @Override
    public void verify() {
      super.verify();
      assert type.kind() == Kind.STRUCT;
      assert terms.length == type.size();
      for (var i = 0; i < terms.length; i++) assert terms[i].type().equals(type.get(i));
    }
  }

  private static final class Sub extends BinaryTerm {
    public Sub(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    public Term rewrite(Term[] terms) {
      assert terms.length == 2;
      return new Sub(terms[0], terms[1]);
    }

    @Override
    public Tag tag() {
      return Tag.SUB;
    }
  }

  private abstract static class TernaryTerm extends Term {
    public final Term arg0, arg1, arg2;

    public TernaryTerm(Term arg0, Term arg1, Term arg2) {
      this.arg0 = arg0;
      this.arg1 = arg1;
      this.arg2 = arg2;
    }

    @Override
    public boolean equals(Object o) {
      if (this == o) return true;
      if (o == null || getClass() != o.getClass()) return false;
      TernaryTerm terms = (TernaryTerm) o;
      return Objects.equals(arg0, terms.arg0)
          && Objects.equals(arg1, terms.arg1)
          && Objects.equals(arg2, terms.arg2);
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
    public int hashCode() {
      return Objects.hash(arg0, arg1, arg2);
    }

    @Override
    public Iterator<Term> iterator() {
      return Arrays.asList(arg0, arg1, arg2).iterator();
    }

    @Override
    public int size() {
      return 3;
    }
  }

  private static final class UDiv extends BinaryTerm {
    public UDiv(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    public Term rewrite(Term[] terms) {
      assert terms.length == 2;
      return new UDiv(terms[0], terms[1]);
    }

    @Override
    public Tag tag() {
      return Tag.UDIV;
    }
  }

  private static final class ULe extends BinaryTerm {
    public ULe(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    public Term rewrite(Term[] terms) {
      assert terms.length == 2;
      return new ULe(terms[0], terms[1]);
    }

    @Override
    public Tag tag() {
      return Tag.ULE;
    }

    @Override
    public Type type() {
      return Type.I1;
    }
  }

  private static final class ULt extends BinaryTerm {
    public ULt(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    public Term rewrite(Term[] terms) {
      assert terms.length == 2;
      return new ULt(terms[0], terms[1]);
    }

    @Override
    public Tag tag() {
      return Tag.ULT;
    }

    @Override
    public Type type() {
      return Type.I1;
    }
  }

  private static final class URem extends BinaryTerm {
    public URem(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    public Term rewrite(Term[] terms) {
      assert terms.length == 2;
      return new URem(terms[0], terms[1]);
    }

    @Override
    public Tag tag() {
      return Tag.UREM;
    }
  }

  private abstract static class UnaryTerm extends Term {
    public final Term arg;

    private UnaryTerm(Term arg) {
      this.arg = arg;
    }

    @Override
    public boolean equals(Object o) {
      if (this == o) return true;
      if (o == null || getClass() != o.getClass()) return false;
      UnaryTerm terms = (UnaryTerm) o;
      return Objects.equals(arg, terms.arg);
    }

    @Override
    public Term get(int i) {
      // TODO: assert?
      if (i != 0) throw new IndexOutOfBoundsException("%s, %s".formatted(this, i));
      return arg;
    }

    @Override
    public int hashCode() {
      return Objects.hashCode(arg);
    }

    @Override
    public Iterator<Term> iterator() {
      return Collections.singletonList(arg).iterator();
    }

    @Override
    public int size() {
      return 1;
    }

    @Override
    public Type type() {
      return arg.type();
    }
  }

  private static final class Undef extends Term {
    private final Type type;

    public Undef(Type type) {
      this.type = type;
    }

    @Override
    public boolean equals(Object o) {
      if (this == o) return true;
      if (o == null || getClass() != o.getClass()) return false;
      Undef terms = (Undef) o;
      return Objects.equals(type, terms.type);
    }

    @Override
    public int hashCode() {
      return Objects.hashCode(type);
    }

    @Override
    public Tag tag() {
      return Tag.UNDEF;
    }

    @Override
    public Type type() {
      return type;
    }
  }

  private static final class Xor extends BinaryTerm {
    public Xor(Term arg0, Term arg1) {
      super(arg0, arg1);
    }

    @Override
    public Term rewrite(Term[] terms) {
      assert terms.length == 2;
      return new Xor(terms[0], terms[1]);
    }

    @Override
    public Tag tag() {
      return Tag.XOR;
    }
  }

  public static final Term NULL =
      new Term() {
        @Override
        public Tag tag() {
          return Tag.NULL;
        }

        @Override
        public Type type() {
          return Type.PTR;
        }
      };

  public static final Term FALSE = intConstant(Type.I1, 0);
  public static final Term ONE = intConstant(Type.I32, 1);
  public static final Term TRUE = intConstant(Type.I1, 1);
  private static final BigInteger ones8 = BigInteger.valueOf((1 << 8) - 1);
  private static final BigInteger ones16 = BigInteger.valueOf((1 << 16) - 1);
  private static final BigInteger ones32 = BigInteger.valueOf((1L << 32) - 1);
  private static final BigInteger ones64 = BigInteger.valueOf(2).pow(64).subtract(BigInteger.ONE);
  private static final BigInteger ones128 = BigInteger.valueOf(2).pow(128).subtract(BigInteger.ONE);

  public Term add(Term b) {
    return new Add(this, b);
  }

  public Term addr() {
    return new Addr(this);
  }

  public static Term alloca(Type type, Term numElements) {
    return new Alloca(type, numElements);
  }

  public Term and(Term b) {
    return new And(this, b);
  }

  public static Term array(Type type, Term[] elements) {
    return new Array(type, elements);
  }

  public Term ashr(Term b) {
    return new AShr(this, b);
  }

  public Term call(List<Term> args) {
    var terms = new Term[1 + args.size()];
    terms[0] = this;
    for (var i = 0; i < args.size(); i++) terms[1 + i] = args.get(i);
    return new Call(terms);
  }

  public Term cast(Type type) {
    return new Cast(this, type);
  }

  public Term elementPtr(Type type, Term idx) {
    return new ElementPtr(type, this, idx);
  }

  public Term eq(Term b) {
    return new Eq(this, b);
  }

  public Term fadd(Term b) {
    return new FAdd(this, b);
  }

  public Term fdiv(Term b) {
    return new FDiv(this, b);
  }

  public Term feq(Term b) {
    return new FEq(this, b);
  }

  public Term fieldPtr(Type struct, int idx) {
    return new FieldPtr(struct, this, idx);
  }

  public Term fle(Term b) {
    return new FLe(this, b);
  }

  public static Term floatConstant(Type type, String value) {
    return new FloatConstant(type, value);
  }

  public Term flt(Term b) {
    return new FLt(this, b);
  }

  public Term fmul(Term b) {
    return new FMul(this, b);
  }

  public Term fne(Term b) {
    return new FNe(this, b);
  }

  public Term fneg() {
    return new FNeg(this);
  }

  public Term frem(Term b) {
    return new FRem(this, b);
  }

  public Term fsub(Term b) {
    return new FSub(this, b);
  }

  public Term get(int i) {
    throw new IndexOutOfBoundsException("%s, %s".formatted(this, i));
  }

  public static Term intConstant(Type type, BigInteger value) {
    if (value.signum() < 0)
      value =
          switch (type.bits()) {
            case 128 -> value.and(ones128);
            case 16 -> value.and(ones16);
            case 32 -> value.and(ones32);
            case 64 -> value.and(ones64);
            case 8 -> value.and(ones8);
            default -> throw new IllegalArgumentException("%s %s".formatted(type, value));
          };
    return new IntConstant(type, value);
  }

  public static Term intConstant(Type type, long value) {
    return intConstant(type, BigInteger.valueOf(value));
  }

  public int intValueExact() {
    throw new UnsupportedOperationException(toString());
  }

  @Override
  public Iterator<Term> iterator() {
    return Collections.emptyIterator();
  }

  public Term load(Type type) {
    return new Load(type, this);
  }

  public Term lshr(Term b) {
    return new LShr(this, b);
  }

  public Term mul(Term b) {
    return new Mul(this, b);
  }

  public Term ne(Term b) {
    return new Ne(this, b);
  }

  public Term not() {
    assert type() == Type.I1;
    return xor(TRUE);
  }

  public Term or(Term b) {
    return new Or(this, b);
  }

  public Term rewrite(Term[] terms) {
    assert terms.length == 0;
    return this;
  }

  public Term scast(Type type) {
    return new SCast(this, type);
  }

  public Term sdiv(Term b) {
    return new SDiv(this, b);
  }

  public Term select(Term ifTrue, Term ifFalse) {
    return new Select(this, ifTrue, ifFalse);
  }

  public Term shl(Term b) {
    return new Shl(this, b);
  }

  public int size() {
    return 0;
  }

  public Term sle(Term b) {
    return new SLe(this, b);
  }

  public Term slt(Term b) {
    return new SLt(this, b);
  }

  public Term srem(Term b) {
    return new SRem(this, b);
  }

  public Type struct() {
    throw new UnsupportedOperationException(toString());
  }

  public static Term struct(Type type, List<Term> fields) {
    return new Struct(type, fields.toArray(new Term[0]));
  }

  public static Term struct(Type type, Term[] fields) {
    return new Struct(type, fields);
  }

  public Term sub(Term b) {
    return new Sub(this, b);
  }

  public abstract Tag tag();

  @Override
  public String toString() {
    var sb = new StringBuilder();
    sb.append(tag());
    if (size() != 0) {
      sb.append('(');
      var more = false;
      for (var arg : this) {
        if (more) sb.append(", ");
        more = true;
        sb.append(arg);
      }
      sb.append(')');
    }
    return sb.toString();
  }

  public abstract Type type();

  public Term udiv(Term b) {
    return new UDiv(this, b);
  }

  public Term ule(Term b) {
    return new ULe(this, b);
  }

  public Term ult(Term b) {
    return new ULt(this, b);
  }

  public static Term undef(Type type) {
    return new Undef(type);
  }

  public Term urem(Term b) {
    return new URem(this, b);
  }

  public void verify() {
    for (var arg : this) arg.verify();
  }

  public Term xor(Term b) {
    return new Xor(this, b);
  }

  public static Term zeroinitializer(Type type) {
    return switch (type.kind()) {
      case ARRAY -> {
        var count = type.count();
        type = type.get(0);
        var elements = new Term[count];
        Arrays.fill(elements, zeroinitializer(type));
        yield array(type, elements);
      }
      case INT -> intConstant(type, 0);
      case PTR -> Term.NULL;
      case STRUCT -> {
        var fields = new Term[type.size()];
        for (var i = 0; i < fields.length; i++) fields[i] = zeroinitializer(type.get(i));
        yield struct(type, fields);
      }
      default -> {
        if (type.isFloat()) yield floatConstant(type, "0");
        throw new IllegalArgumentException(type.toString());
      }
    };
  }
}
