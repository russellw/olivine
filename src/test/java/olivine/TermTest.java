package olivine;

import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.Test;

class TermTest {
  @Test
  void tag() {
    assertEquals(Term.NULL.tag(), Tag.NULL);
  }
}
