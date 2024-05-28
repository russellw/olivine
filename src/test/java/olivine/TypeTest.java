package olivine;

import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.Test;

class TypeTest {

  @Test
  void bits() {
    assertEquals(16, Type.I16.bits());
  }

  @Test
  void size() {
    assertEquals(0, Type.I16.size());
  }

  @Test
  void iterator() {
    Type r = null;
    for (var t : Type.I16) r = t;
    assertNull(r);
  }

  @Test
  void kind() {
    assertEquals(Kind.INT, Type.I16.kind());
  }
}
