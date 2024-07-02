package olivine;

import static org.junit.jupiter.api.Assertions.*;

import java.math.BigInteger;
import java.util.Iterator;
import java.util.List;
import java.util.NoSuchElementException;
import org.junit.jupiter.api.Test;

class TermTest {
  @Test
  void tag() {
    assertEquals(Tag.nullConstant, Term.NULL.tag());
    assertEquals(Tag.intConstant, Term.intConstant(Type.I32, 1).tag());
  }

  @Test
  void identity() {
    assertNotEquals(Term.NULL, Term.intConstant(Type.I64, 1));
  }

  @Test
  void floatConstant() {
    var one = Term.floatConstant(Type.FLOAT, "1.0");
    assertEquals("1.0", one.toString());
    assertEquals(one, Term.floatConstant(Type.FLOAT, "1.0"));
  }

  @Test
  void intConstant() {
    var a = Term.intConstant(Type.I32, 123);
    assertEquals("123", a.toString());
    var b = Term.intConstant(Type.I32, 123);
    assertEquals(a, b);
    var z = Term.intConstant(Type.I32, 124);
    assertNotEquals(a, z);
    assertThrows(IndexOutOfBoundsException.class, () -> a.get(10));
  }

  @Test
  void fneg() {
    var a = Term.floatConstant(Type.FLOAT, "1.0").fneg();
    assertEquals(a, Term.floatConstant(Type.FLOAT, "1.0").fneg());
    assertNotEquals(a, Term.floatConstant(Type.FLOAT, "2.0").fneg());
    assertEquals(1, a.size());
    assertEquals(Term.floatConstant(Type.FLOAT, "1.0"), a.get(0));
    assertThrows(IndexOutOfBoundsException.class, () -> a.get(10));

    Term r = null;
    for (var x : a) r = x;
    assertEquals(Term.floatConstant(Type.FLOAT, "1.0"), r);
  }

  @Test
  void type() {
    assertEquals(Type.PTR, Term.NULL.type());
  }

  @Test
  void add() {
    var one = Term.intConstant(Type.I128, 1);
    var two = Term.intConstant(Type.I128, 2);
    var a = one.add(two);
    assertEquals(one, a.get(0));
    assertEquals(two, a.get(1));
    assertEquals(a, one.add(two));
    assertNotEquals(a, one.add(one));
    assertEquals(Type.I128, a.type());

    Term r = null;
    for (var x : a) r = x;
    assertEquals(two, r);
  }

  @Test
  void testIntConstantWithLong() {
    Term term = Term.intConstant(Type.I1, 10L);
    assertEquals("10", term.toString());
    assertEquals(Type.I1, term.type());
  }

  @Test
  void testIntConstantWithBigInteger() {
    BigInteger value = new BigInteger("123456789");
    Term term = Term.intConstant(Type.I32, value);
    assertEquals("123456789", term.toString());
    assertEquals(Type.I32, term.type());
  }

  @Test
  void testFloatConstant() {
    Term term = Term.floatConstant(Type.FLOAT, "3.14");
    assertEquals("3.14", term.toString());
    assertEquals(Type.FLOAT, term.type());
  }

  @Test
  void testFNeg() {
    Term term = Term.intConstant(Type.I1, 5L);
    Term fneg = term.fneg();
    assertEquals(Tag.fneg, fneg.tag());
    assertEquals(term, fneg.get(0));
  }

  @Test
  void testAdd() {
    Term term1 = Term.intConstant(Type.I1, 2L);
    Term term2 = Term.intConstant(Type.I1, 3L);
    Term add = term1.add(term2);
    assertEquals(Tag.add, add.tag());
    assertEquals(term1, add.get(0));
    assertEquals(term2, add.get(1));
  }

  @Test
  void testSelect() {
    Term cond = Term.TRUE;
    Term ifTrue = Term.intConstant(Type.I1, 1L);
    Term ifFalse = Term.intConstant(Type.I1, 0L);
    Term select = cond.select(ifTrue, ifFalse);
    assertEquals(Tag.select, select.tag());
    assertEquals(cond, select.get(0));
    assertEquals(ifTrue, select.get(1));
    assertEquals(ifFalse, select.get(2));
  }

  @Test
  void testCall() {
    Term func = Term.intConstant(Type.I1, 1L);
    Term arg1 = Term.intConstant(Type.I1, 2L);
    Term arg2 = Term.intConstant(Type.I1, 3L);
    Term call = func.call(List.of(arg1, arg2));
    assertEquals(Tag.call, call.tag());
    assertEquals(func, call.get(0));
    assertEquals(arg1, call.get(1));
    assertEquals(arg2, call.get(2));
  }

  @Test
  void testIterator() {
    Term term = Term.intConstant(Type.I1, 5L);
    Iterator<Term> iterator = term.iterator();
    assertFalse(iterator.hasNext());
    assertThrows(NoSuchElementException.class, iterator::next);
  }

  @Test
  void testNull() {
    Term term = Term.NULL;
    assertEquals(Tag.nullConstant, term.tag());
    assertEquals(Type.PTR, term.type());
  }

  @Test
  void testEqualsAndHashCode() {
    Term term1 = Term.intConstant(Type.I1, 5L);
    Term term2 = Term.intConstant(Type.I1, 5L);
    Term term3 = Term.intConstant(Type.I1, 6L);
    assertEquals(term1, term2);
    assertNotEquals(term1, term3);
    assertEquals(term1.hashCode(), term2.hashCode());
    assertNotEquals(term1.hashCode(), term3.hashCode());
  }

  @Test
  void testSize() {
    Term term = Term.intConstant(Type.I1, 5L);
    assertEquals(0, term.size());
    Term add = term.add(term);
    assertEquals(2, add.size());
  }

  @Test
  void testGet() {
    Term term1 = Term.intConstant(Type.I1, 2L);
    Term term2 = Term.intConstant(Type.I1, 3L);
    Term add = term1.add(term2);
    assertEquals(term1, add.get(0));
    assertEquals(term2, add.get(1));
    assertThrows(IndexOutOfBoundsException.class, () -> add.get(2));
  }

  @Test
  public void testZeroInitializerForIntType() {
    // Test I1 type
    Term result = Term.zeroinitializer(Type.I1);
    assertSame(result.tag(), Tag.intConstant);
    assertEquals(0, result.intValueExact());

    // Test I32 type
    result = Term.zeroinitializer(Type.I32);
    assertSame(result.tag(), Tag.intConstant);
    assertEquals(0, result.intValueExact());

    // Test I64 type
    result = Term.zeroinitializer(Type.I64);
    assertSame(result.tag(), Tag.intConstant);
    assertEquals(0, result.intValueExact());
  }

  @Test
  public void testZeroInitializerForFloatType() {
    // Test FLOAT type
    Term result = Term.zeroinitializer(Type.FLOAT);
    assertSame(result.tag(), Tag.floatConstant);
    assertEquals("0", result.toString());

    // Test DOUBLE type
    result = Term.zeroinitializer(Type.DOUBLE);
    assertSame(result.tag(), Tag.floatConstant);
    assertEquals("0", result.toString());

    // Test HALF type
    result = Term.zeroinitializer(Type.HALF);
    assertSame(result.tag(), Tag.floatConstant);
    assertEquals("0", result.toString());
  }

  @Test
  public void testZeroInitializerForArrayType() {
    // Test array of I32
    Type arrayType = Type.I32.array(3);
    Term result = Term.zeroinitializer(arrayType);
    assertSame(result.tag(), Tag.array);
    assertEquals(3, result.size());
    for (Term element : result) {
      assertSame(element.tag(), Tag.intConstant);
      assertEquals(0, element.intValueExact());
    }

    // Test array of FLOAT
    arrayType = Type.FLOAT.array(2);
    result = Term.zeroinitializer(arrayType);
    assertSame(result.tag(), Tag.array);
    assertEquals(2, result.size());
    for (Term element : result) {
      assertSame(element.tag(), Tag.floatConstant);
      assertEquals("0", element.toString());
    }
  }

  @Test
  public void testZeroInitializerForUnsupportedType() {
    // Test unsupported type should throw IllegalArgumentException
    Type unsupportedType = Type.OPAQUE;
    assertThrows(IllegalArgumentException.class, () -> Term.zeroinitializer(unsupportedType));
  }

  @Test
  void testRewriteOnBaseTerm() {
    Term term = Term.NULL;
    Term[] terms = {};
    Term result = term.rewrite(terms);
    assertSame(term, result);
  }

  @Test
  void testRewriteOnFNeg() {
    Term arg = Term.intConstant(Type.I32, 42);
    Term term = arg.fneg();
    Term[] terms = {Term.intConstant(Type.I32, 43)};
    Term result = term.rewrite(terms);
    assertNotSame(term, result);
    assertEquals(Tag.fneg, result.tag());
    assertEquals(terms[0], result.get(0));
  }

  @Test
  void testRewriteOnAddr() {
    Term arg = Term.intConstant(Type.I32, 42);
    Term term = arg.addr();
    Term[] terms = {Term.intConstant(Type.I32, 43)};
    Term result = term.rewrite(terms);
    assertNotSame(term, result);
    assertEquals(Tag.addr, result.tag());
    assertEquals(terms[0], result.get(0));
  }

  @Test
  void testRewriteOnLoad() {
    Term arg = Term.intConstant(Type.I32, 42);
    Type type = Type.I32;
    Term term = arg.load(type);
    Term[] terms = {Term.intConstant(Type.I32, 43)};
    Term result = term.rewrite(terms);
    assertNotSame(term, result);
    assertEquals(Tag.load, result.tag());
    assertEquals(terms[0], result.get(0));
    assertEquals(type, result.type());
  }

  @Test
  void testRewriteOnAlloca() {
    Term arg = Term.intConstant(Type.I32, 42);
    Type type = Type.I32;
    Term term = Term.alloca(type, arg);
    Term[] terms = {Term.intConstant(Type.I32, 43)};
    Term result = term.rewrite(terms);
    assertNotSame(term, result);
    assertEquals(Tag.alloca, result.tag());
    assertEquals(terms[0], result.get(0));
    assertEquals(Type.PTR, result.type());
  }

  @Test
  void testRewriteOnElementPtr() {
    Term arg1 = Term.intConstant(Type.I32, 42);
    Term arg2 = Term.intConstant(Type.I32, 43);
    Type type = Type.I32;
    Term term = arg1.elementPtr(type, arg2);
    Term[] terms = {Term.intConstant(Type.I32, 44), Term.intConstant(Type.I32, 45)};
    Term result = term.rewrite(terms);
    assertNotSame(term, result);
    assertEquals(Tag.elementPtr, result.tag());
    assertEquals(terms[0], result.get(0));
    assertEquals(terms[1], result.get(1));
    assertEquals(Type.PTR, result.type());
  }

  @Test
  void testRewriteOnCast() {
    Term arg = Term.intConstant(Type.I32, 42);
    Type type = Type.I32;
    Term term = arg.cast(type);
    Term[] terms = {Term.intConstant(Type.I32, 43)};
    Term result = term.rewrite(terms);
    assertNotSame(term, result);
    assertEquals(Tag.cast, result.tag());
    assertEquals(terms[0], result.get(0));
    assertEquals(type, result.type());
  }

  @Test
  void testRewriteOnSCast() {
    Term arg = Term.intConstant(Type.I32, 42);
    Type type = Type.I32;
    Term term = arg.scast(type);
    Term[] terms = {Term.intConstant(Type.I32, 43)};
    Term result = term.rewrite(terms);
    assertNotSame(term, result);
    assertEquals(Tag.scast, result.tag());
    assertEquals(terms[0], result.get(0));
    assertEquals(type, result.type());
  }

  @Test
  void testRewriteOnEq() {
    Term arg1 = Term.intConstant(Type.I32, 42);
    Term arg2 = Term.intConstant(Type.I32, 43);
    Term term = arg1.eq(arg2);
    Term[] terms = {Term.intConstant(Type.I32, 44), Term.intConstant(Type.I32, 45)};
    Term result = term.rewrite(terms);
    assertNotSame(term, result);
    assertEquals(Tag.eq, result.tag());
    assertEquals(terms[0], result.get(0));
    assertEquals(terms[1], result.get(1));
  }

  @Test
  void testRewriteOnNe() {
    Term arg1 = Term.intConstant(Type.I32, 42);
    Term arg2 = Term.intConstant(Type.I32, 43);
    Term term = arg1.ne(arg2);
    Term[] terms = {Term.intConstant(Type.I32, 44), Term.intConstant(Type.I32, 45)};
    Term result = term.rewrite(terms);
    assertNotSame(term, result);
    assertEquals(Tag.ne, result.tag());
    assertEquals(terms[0], result.get(0));
    assertEquals(terms[1], result.get(1));
  }

  @Test
  void testRewriteOnSLe() {
    Term arg1 = Term.intConstant(Type.I32, 42);
    Term arg2 = Term.intConstant(Type.I32, 43);
    Term term = arg1.sle(arg2);
    Term[] terms = {Term.intConstant(Type.I32, 44), Term.intConstant(Type.I32, 45)};
    Term result = term.rewrite(terms);
    assertNotSame(term, result);
    assertEquals(Tag.sle, result.tag());
    assertEquals(terms[0], result.get(0));
    assertEquals(terms[1], result.get(1));
  }

  @Test
  void testRewriteOnSLt() {
    Term arg1 = Term.intConstant(Type.I32, 42);
    Term arg2 = Term.intConstant(Type.I32, 43);
    Term term = arg1.slt(arg2);
    Term[] terms = {Term.intConstant(Type.I32, 44), Term.intConstant(Type.I32, 45)};
    Term result = term.rewrite(terms);
    assertNotSame(term, result);
    assertEquals(Tag.slt, result.tag());
    assertEquals(terms[0], result.get(0));
    assertEquals(terms[1], result.get(1));
  }

  @Test
  void testRewriteOnULe() {
    Term arg1 = Term.intConstant(Type.I32, 42);
    Term arg2 = Term.intConstant(Type.I32, 43);
    Term term = arg1.ule(arg2);
    Term[] terms = {Term.intConstant(Type.I32, 44), Term.intConstant(Type.I32, 45)};
    Term result = term.rewrite(terms);
    assertNotSame(term, result);
    assertEquals(Tag.ule, result.tag());
    assertEquals(terms[0], result.get(0));
    assertEquals(terms[1], result.get(1));
  }

  @Test
  void testRewriteOnULt() {
    Term arg1 = Term.intConstant(Type.I32, 42);
    Term arg2 = Term.intConstant(Type.I32, 43);
    Term term = arg1.ult(arg2);
    Term[] terms = {Term.intConstant(Type.I32, 44), Term.intConstant(Type.I32, 45)};
    Term result = term.rewrite(terms);
    assertNotSame(term, result);
    assertEquals(Tag.ult, result.tag());
    assertEquals(terms[0], result.get(0));
    assertEquals(terms[1], result.get(1));
  }

  @Test
  void testRewriteOnAdd() {
    Term arg1 = Term.intConstant(Type.I32, 42);
    Term arg2 = Term.intConstant(Type.I32, 43);
    Term term = arg1.add(arg2);
    Term[] terms = {Term.intConstant(Type.I32, 44), Term.intConstant(Type.I32, 45)};
    Term result = term.rewrite(terms);
    assertNotSame(term, result);
    assertEquals(Tag.add, result.tag());
    assertEquals(terms[0], result.get(0));
    assertEquals(terms[1], result.get(1));
  }

  @Test
  void testRewriteOnSub() {
    Term arg1 = Term.intConstant(Type.I32, 42);
    Term arg2 = Term.intConstant(Type.I32, 43);
    Term term = arg1.sub(arg2);
    Term[] terms = {Term.intConstant(Type.I32, 44), Term.intConstant(Type.I32, 45)};
    Term result = term.rewrite(terms);
    assertNotSame(term, result);
    assertEquals(Tag.sub, result.tag());
    assertEquals(terms[0], result.get(0));
    assertEquals(terms[1], result.get(1));
  }

  @Test
  void testRewriteOnMul() {
    Term arg1 = Term.intConstant(Type.I32, 42);
    Term arg2 = Term.intConstant(Type.I32, 43);
    Term term = arg1.mul(arg2);
    Term[] terms = {Term.intConstant(Type.I32, 44), Term.intConstant(Type.I32, 45)};
    Term result = term.rewrite(terms);
    assertNotSame(term, result);
    assertEquals(Tag.mul, result.tag());
    assertEquals(terms[0], result.get(0));
    assertEquals(terms[1], result.get(1));
  }

  @Test
  void testRewriteOnUDiv() {
    Term arg1 = Term.intConstant(Type.I32, 42);
    Term arg2 = Term.intConstant(Type.I32, 43);
    Term term = arg1.udiv(arg2);
    Term[] terms = {Term.intConstant(Type.I32, 44), Term.intConstant(Type.I32, 45)};
    Term result = term.rewrite(terms);
    assertNotSame(term, result);
    assertEquals(Tag.udiv, result.tag());
    assertEquals(terms[0], result.get(0));
    assertEquals(terms[1], result.get(1));
  }

  @Test
  void testRewriteOnSDiv() {
    Term arg1 = Term.intConstant(Type.I32, 42);
    Term arg2 = Term.intConstant(Type.I32, 43);
    Term term = arg1.sdiv(arg2);
    Term[] terms = {Term.intConstant(Type.I32, 44), Term.intConstant(Type.I32, 45)};
    Term result = term.rewrite(terms);
    assertNotSame(term, result);
    assertEquals(Tag.sdiv, result.tag());
    assertEquals(terms[0], result.get(0));
    assertEquals(terms[1], result.get(1));
  }

  @Test
  void testRewriteOnURem() {
    Term arg1 = Term.intConstant(Type.I32, 42);
    Term arg2 = Term.intConstant(Type.I32, 43);
    Term term = arg1.urem(arg2);
    Term[] terms = {Term.intConstant(Type.I32, 44), Term.intConstant(Type.I32, 45)};
    Term result = term.rewrite(terms);
    assertNotSame(term, result);
    assertEquals(Tag.urem, result.tag());
    assertEquals(terms[0], result.get(0));
    assertEquals(terms[1], result.get(1));
  }

  @Test
  void testRewriteOnSRem() {
    Term arg1 = Term.intConstant(Type.I32, 42);
    Term arg2 = Term.intConstant(Type.I32, 43);
    Term term = arg1.srem(arg2);
    Term[] terms = {Term.intConstant(Type.I32, 44), Term.intConstant(Type.I32, 45)};
    Term result = term.rewrite(terms);
    assertNotSame(term, result);
    assertEquals(Tag.srem, result.tag());
    assertEquals(terms[0], result.get(0));
    assertEquals(terms[1], result.get(1));
  }

  @Test
  void testRewriteOnAnd() {
    Term arg1 = Term.intConstant(Type.I32, 42);
    Term arg2 = Term.intConstant(Type.I32, 43);
    Term term = arg1.and(arg2);
    Term[] terms = {Term.intConstant(Type.I32, 44), Term.intConstant(Type.I32, 45)};
    Term result = term.rewrite(terms);
    assertNotSame(term, result);
    assertEquals(Tag.and, result.tag());
    assertEquals(terms[0], result.get(0));
    assertEquals(terms[1], result.get(1));
  }

  @Test
  void testRewriteOnOr() {
    Term arg1 = Term.intConstant(Type.I32, 42);
    Term arg2 = Term.intConstant(Type.I32, 43);
    Term term = arg1.or(arg2);
    Term[] terms = {Term.intConstant(Type.I32, 44), Term.intConstant(Type.I32, 45)};
    Term result = term.rewrite(terms);
    assertNotSame(term, result);
    assertEquals(Tag.or, result.tag());
    assertEquals(terms[0], result.get(0));
    assertEquals(terms[1], result.get(1));
  }

  @Test
  void testRewriteOnXor() {
    Term arg1 = Term.intConstant(Type.I32, 42);
    Term arg2 = Term.intConstant(Type.I32, 43);
    Term term = arg1.xor(arg2);
    Term[] terms = {Term.intConstant(Type.I32, 44), Term.intConstant(Type.I32, 45)};
    Term result = term.rewrite(terms);
    assertNotSame(term, result);
    assertEquals(Tag.xor, result.tag());
    assertEquals(terms[0], result.get(0));
    assertEquals(terms[1], result.get(1));
  }

  @Test
  void testRewriteOnShl() {
    Term arg1 = Term.intConstant(Type.I32, 42);
    Term arg2 = Term.intConstant(Type.I32, 43);
    Term term = arg1.shl(arg2);
    Term[] terms = {Term.intConstant(Type.I32, 44), Term.intConstant(Type.I32, 45)};
    Term result = term.rewrite(terms);
    assertNotSame(term, result);
    assertEquals(Tag.shl, result.tag());
    assertEquals(terms[0], result.get(0));
    assertEquals(terms[1], result.get(1));
  }

  @Test
  void testRewriteOnLShr() {
    Term arg1 = Term.intConstant(Type.I32, 42);
    Term arg2 = Term.intConstant(Type.I32, 43);
    Term term = arg1.lshr(arg2);
    Term[] terms = {Term.intConstant(Type.I32, 44), Term.intConstant(Type.I32, 45)};
    Term result = term.rewrite(terms);
    assertNotSame(term, result);
    assertEquals(Tag.lshr, result.tag());
    assertEquals(terms[0], result.get(0));
    assertEquals(terms[1], result.get(1));
  }

  @Test
  void testRewriteOnAShr() {
    Term arg1 = Term.intConstant(Type.I32, 42);
    Term arg2 = Term.intConstant(Type.I32, 43);
    Term term = arg1.ashr(arg2);
    Term[] terms = {Term.intConstant(Type.I32, 44), Term.intConstant(Type.I32, 45)};
    Term result = term.rewrite(terms);
    assertNotSame(term, result);
    assertEquals(Tag.ashr, result.tag());
    assertEquals(terms[0], result.get(0));
    assertEquals(terms[1], result.get(1));
  }

  @Test
  void predicates() {
    var term = Term.ONE.eq(Term.ONE);
    assertEquals(Type.I1, term.type());
  }

  @Test
  void verifyElementPtr() {
    var a = new Variable(Type.PTR);
    var i = Term.ONE;
    a.elementPtr(Type.DOUBLE, i).verify();
    assertThrows(Throwable.class, a.elementPtr(Type.DOUBLE, a)::verify);
    assertThrows(Throwable.class, i.elementPtr(Type.DOUBLE, i)::verify);
  }
}
