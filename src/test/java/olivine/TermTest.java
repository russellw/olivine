package olivine;

import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.Test;

class TermTest {
  @Test
  void tag() {
    assertEquals(Tag.NULL, Term.NULL.tag());
    assertEquals(Tag.INTEGER, Term.of(1).tag());
  }

  @Test
  void of() {
    var a = Term.of(123);
    assertEquals("123", a.toString());
    var b = Term.of(123);
    assertEquals(a, b);
    var z = Term.of(-123);
    assertNotEquals(a, z);
  }

  @Test
  void fneg() {}
}
