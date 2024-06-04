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

  @Test
  void testSameType() {
    Term intConstant = Term.intConstant(Type.I32, 42);
    Term castTerm = intConstant.cast(Type.I32);
    assertEquals("bitcast", LlvmComposer.cast(castTerm));
  }

  @Test
  void testPtrToInt() {
    Term ptrTerm = Term.alloca(Type.I32, Term.intConstant(Type.I32, 1));
    Term intTerm = Term.intConstant(Type.I32, 1);

    Term castTerm = intTerm.cast(Type.OPAQUE);

    assertThrows(Exception.class, () -> LlvmComposer.cast(castTerm));

    Term ptrToIntTerm = ptrTerm.cast(Type.I32);
    assertEquals("ptrtoint", LlvmComposer.cast(ptrToIntTerm));
  }

  @Test
  void testIntToPtr() {
    Term intTerm = Term.intConstant(Type.I32, 1);
    Term ptrTerm = Term.alloca(Type.I32, intTerm);

    Term intToPtrTerm = intTerm.cast(Type.PTR);
    assertEquals("inttoptr", LlvmComposer.cast(intToPtrTerm));
  }

  @Test
  void testIntToFloat() {
    Term intTerm = Term.intConstant(Type.I32, 1);
    Term floatTerm = intTerm.cast(Type.FLOAT);

    assertEquals("uitofp", LlvmComposer.cast(floatTerm));
  }

  @Test
  void testFloatToInt() {
    Term floatTerm = Term.floatConstant(Type.FLOAT, "1.0");
    Term intTerm = floatTerm.cast(Type.I32);

    assertEquals("fptoui", LlvmComposer.cast(intTerm));
  }

  @Test
  void testIntZext() {
    Term smallIntTerm = Term.intConstant(Type.I8, 1);
    Term largeIntTerm = smallIntTerm.cast(Type.I32);

    assertEquals("zext", LlvmComposer.cast(largeIntTerm));
  }

  @Test
  void testIntTrunc() {
    Term largeIntTerm = Term.intConstant(Type.I32, 1);
    Term smallIntTerm = largeIntTerm.cast(Type.I8);

    assertEquals("trunc", LlvmComposer.cast(smallIntTerm));
  }

  @Test
  void testFloatFpext() {
    Term smallFloatTerm = Term.floatConstant(Type.FLOAT, "1.0");
    Term largeFloatTerm = smallFloatTerm.cast(Type.DOUBLE);

    assertEquals("fpext", LlvmComposer.cast(largeFloatTerm));
  }

  @Test
  void testFloatFptrunc() {
    Term largeFloatTerm = Term.floatConstant(Type.DOUBLE, "1.0");
    Term smallFloatTerm = largeFloatTerm.cast(Type.FLOAT);

    assertEquals("fptrunc", LlvmComposer.cast(smallFloatTerm));
  }

  @Test
  void testInvalidCast() {
    Term floatTerm = Term.floatConstant(Type.FLOAT, "1.0");
    Term invalidCastTerm = floatTerm.cast(Type.PTR);

    assertThrows(IllegalArgumentException.class, () -> LlvmComposer.cast(invalidCastTerm));
  }
}
