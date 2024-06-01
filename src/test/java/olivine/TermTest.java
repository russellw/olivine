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
    assertEquals(Tag.NULL, Term.NULL.tag());
    assertEquals(Tag.INT, Term.intConstant(Type.I32, 1).tag());
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
    assertEquals(Tag.FNEG, fneg.tag());
    assertEquals(term, fneg.get(0));
  }

  @Test
  void testAdd() {
    Term term1 = Term.intConstant(Type.I1, 2L);
    Term term2 = Term.intConstant(Type.I1, 3L);
    Term add = term1.add(term2);
    assertEquals(Tag.ADD, add.tag());
    assertEquals(term1, add.get(0));
    assertEquals(term2, add.get(1));
  }

  @Test
  void testSelect() {
    Term cond = Term.TRUE;
    Term ifTrue = Term.intConstant(Type.I1, 1L);
    Term ifFalse = Term.intConstant(Type.I1, 0L);
    Term select = cond.select(ifTrue, ifFalse);
    assertEquals(Tag.SELECT, select.tag());
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
    assertEquals(Tag.CALL, call.tag());
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
    assertEquals(Tag.NULL, term.tag());
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
}
