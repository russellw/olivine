package olivine;

import static org.junit.jupiter.api.Assertions.*;

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
    assertEquals(Term.floatConstant(Type.FLOAT, "1.0"), a.getFirst());
    assertThrows(IndexOutOfBoundsException.class, () -> a.get(10));
  }

  @Test
  void floatConstant() {
    var one = Term.floatConstant(Type.FLOAT, "1.0");
    assertEquals("1.0", one.toString());
    assertEquals(one, Term.floatConstant(Type.FLOAT, "1.0"));
  }

  @Test
  void type() {
    assertEquals(Type.PTR, Term.NULL.type());
  }
}
