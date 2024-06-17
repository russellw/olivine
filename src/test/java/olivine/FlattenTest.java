package olivine;

import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.Test;

class FlattenTest {
  @Test
  void testFlat() {
    assertTrue(Flatten.flat(Term.TRUE));
    assertTrue(Flatten.flat(Term.ONE.add(Term.ONE)));
    assertFalse(Flatten.flat(Term.ONE.add(Term.ONE.add(Term.ONE))));
  }
}
