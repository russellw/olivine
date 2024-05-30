package olivine;

import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.Test;

class EtcTest {
  @Test
  void testParseHexDigit_withDigitCharacters() {
    assertEquals(0, Etc.parseHexDigit('0'));
    assertEquals(1, Etc.parseHexDigit('1'));
    assertEquals(2, Etc.parseHexDigit('2'));
    assertEquals(3, Etc.parseHexDigit('3'));
    assertEquals(4, Etc.parseHexDigit('4'));
    assertEquals(5, Etc.parseHexDigit('5'));
    assertEquals(6, Etc.parseHexDigit('6'));
    assertEquals(7, Etc.parseHexDigit('7'));
    assertEquals(8, Etc.parseHexDigit('8'));
    assertEquals(9, Etc.parseHexDigit('9'));
  }

  @Test
  void testParseHexDigit_withLowercaseHexCharacters() {
    assertEquals(10, Etc.parseHexDigit('a'));
    assertEquals(11, Etc.parseHexDigit('b'));
    assertEquals(12, Etc.parseHexDigit('c'));
    assertEquals(13, Etc.parseHexDigit('d'));
    assertEquals(14, Etc.parseHexDigit('e'));
    assertEquals(15, Etc.parseHexDigit('f'));
  }

  @Test
  void testParseHexDigit_withUppercaseHexCharacters() {
    assertEquals(10, Etc.parseHexDigit('A'));
    assertEquals(11, Etc.parseHexDigit('B'));
    assertEquals(12, Etc.parseHexDigit('C'));
    assertEquals(13, Etc.parseHexDigit('D'));
    assertEquals(14, Etc.parseHexDigit('E'));
    assertEquals(15, Etc.parseHexDigit('F'));
  }

  @Test
  void testParseHexDigit_withInvalidCharacters() {
    assertThrows(IllegalArgumentException.class, () -> Etc.parseHexDigit('g'));
    assertThrows(IllegalArgumentException.class, () -> Etc.parseHexDigit('G'));
    assertThrows(IllegalArgumentException.class, () -> Etc.parseHexDigit('z'));
    assertThrows(IllegalArgumentException.class, () -> Etc.parseHexDigit('@'));
    assertThrows(IllegalArgumentException.class, () -> Etc.parseHexDigit(' '));
  }
}
