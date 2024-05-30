package olivine;

import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.Test;

class LlvmParserTest {
  @Test
  void isIdPart() {
    assertTrue(LlvmParser.isIdPart('a'));
    assertTrue(LlvmParser.isIdPart('z'));
    assertTrue(LlvmParser.isIdPart('A'));
    assertTrue(LlvmParser.isIdPart('Z'));
    assertTrue(LlvmParser.isIdPart('0'));
    assertTrue(LlvmParser.isIdPart('9'));
    assertTrue(LlvmParser.isIdPart('_'));
    assertTrue(LlvmParser.isIdPart('-'));
    assertTrue(LlvmParser.isIdPart('.'));
    assertTrue(LlvmParser.isIdPart('$'));
    assertFalse(LlvmParser.isIdPart(' '));
    assertFalse(LlvmParser.isIdPart('%'));
    assertFalse(LlvmParser.isIdPart('@'));
  }
}
