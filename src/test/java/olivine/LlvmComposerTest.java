package olivine;

import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.Test;

class LlvmComposerTest {
  @Test
  public void testIsIdWithEmptyString() {
    assertFalse(LlvmComposer.isId(""));
  }

  @Test
  public void testIsIdWithStartingDigit() {
    assertFalse(LlvmComposer.isId("1test"));
  }

  @Test
  public void testIsIdWithValidId() {
    // Assuming 'a' and 'test123' are valid IDs
    assertTrue(LlvmComposer.isId("a"));
    assertTrue(LlvmComposer.isId("test123"));
  }

  @Test
  public void testIsIdWithInvalidCharacters() {
    // Assuming 'test!@#' contains invalid characters
    assertFalse(LlvmComposer.isId("test!@#"));
  }

  @Test
  public void testIsIdWithMixedValidAndInvalidCharacters() {
    assertTrue(LlvmComposer.isId("valid_id"));
    assertTrue(LlvmComposer.isId("valid-id"));
    assertFalse(LlvmComposer.isId("invalid*id"));
  }
}
