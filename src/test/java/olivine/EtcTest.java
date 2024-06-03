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

  @Test
  public void testExtension_withExtension() {
    assertEquals("txt", Etc.extension("file.txt"));
    assertEquals("jpg", Etc.extension("image.jpg"));
    assertEquals("pdf", Etc.extension("document.pdf"));
  }

  @Test
  public void testExtension_withMultipleDots() {
    assertEquals("gz", Etc.extension("archive.tar.gz"));
    assertEquals("docx", Etc.extension("file.name.with.dots.docx"));
  }

  @Test
  public void testExtension_withNoExtension() {
    assertEquals("", Etc.extension("file"));
    assertEquals("", Etc.extension("anotherfile."));
  }

  @Test
  public void testExtension_withEmptyString() {
    assertEquals("", Etc.extension(""));
  }

  @Test
  public void testExtension_withDotOnly() {
    assertEquals("", Etc.extension("."));
  }

  @Test
  void testWithoutDirectory() {
    assertEquals("file.txt", Etc.withoutDirectory("/path/to/file.txt"));
    assertEquals("file.txt", Etc.withoutDirectory("file.txt"));
    assertEquals("file.txt", Etc.withoutDirectory("C:\\path\\to\\file.txt"));
    assertEquals("file", Etc.withoutDirectory("/path/to/file"));
    assertEquals("file", Etc.withoutDirectory("file"));
  }

  @Test
  void testWithoutExtension() {
    assertEquals("file", Etc.withoutExtension("file.txt"));
    assertEquals("file", Etc.withoutExtension("file."));
    assertEquals("file", Etc.withoutExtension("file"));
    assertEquals("file.name", Etc.withoutExtension("file.name.txt"));
    assertEquals("", Etc.withoutExtension(".hiddenfile"));
  }

  @Test
  void testBaseName() {
    assertEquals("file", Etc.baseName("/path/to/file.txt"));
    assertEquals("file", Etc.baseName("file.txt"));
    assertEquals("file", Etc.baseName("C:\\path\\to\\file.txt"));
    assertEquals("file", Etc.baseName("/path/to/file"));
    assertEquals("file", Etc.baseName("file"));
    assertEquals("file.name", Etc.baseName("/path/to/file.name.txt"));
    assertEquals("", Etc.baseName("/path/to/.hiddenfile"));
  }

  @Test
  void testHexDigitForDigits() {
    // Test for n from 0 to 9
    for (int n = 0; n < 10; n++) {
      int expected = '0' + n;
      assertEquals(expected, Etc.hexDigit(n), "Failed for n = " + n);
    }
  }

  @Test
  void testHexDigitForLetters() {
    // Test for n from 10 to 15
    for (int n = 10; n < 16; n++) {
      int expected = 'a' - 10 + n;
      assertEquals(expected, Etc.hexDigit(n), "Failed for n = " + n);
    }
  }

  @Test
  void testHexDigitThrowsAssertionErrorForNegative() {
    // Test for negative values
    assertThrows(AssertionError.class, () -> Etc.hexDigit(-1));
  }

  @Test
  void testHexDigitThrowsAssertionErrorForTooLargeValues() {
    // Test for values >= 16
    assertThrows(AssertionError.class, () -> Etc.hexDigit(16));
    assertThrows(AssertionError.class, () -> Etc.hexDigit(17));
  }
}
