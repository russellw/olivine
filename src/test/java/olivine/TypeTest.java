package olivine;

import static org.junit.jupiter.api.Assertions.*;

import java.util.Iterator;
import java.util.List;
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

  @Test
  void struct() {
    var s = Type.struct(Type.I32, Type.I32, Type.I32);
    assertEquals(s, Type.struct(Type.I32, Type.I32, Type.I32));
    assertNotEquals(s, Type.struct(Type.I32, Type.I32, Type.I16));
  }

  @Test
  public void testPTRKind() {
    assertEquals(Kind.PTR, Type.PTR.kind());
  }

  @Test
  public void testPTRToString() {
    assertEquals("ptr", Type.PTR.toString());
  }

  @Test
  public void testOPAQUEKind() {
    assertEquals(Kind.OPAQUE, Type.OPAQUE.kind());
  }

  @Test
  public void testOPAQUEToString() {
    assertEquals("opaque", Type.OPAQUE.toString());
  }

  @Test
  public void testVOIDKind() {
    assertEquals(Kind.VOID, Type.VOID.kind());
  }

  @Test
  public void testVOIDToString() {
    assertEquals("void", Type.VOID.toString());
  }

  @Test
  public void testI32Kind() {
    assertEquals(Kind.INT, Type.I32.kind());
  }

  @Test
  public void testI32Bits() {
    assertEquals(32, Type.I32.bits());
  }

  @Test
  public void testI32ToString() {
    assertEquals("i32", Type.I32.toString());
  }

  @Test
  public void testArrayKind() {
    Type array = Type.I32.array(5);
    assertEquals(Kind.ARRAY, array.kind());
  }

  @Test
  public void testArrayGet() {
    Type array = Type.I32.array(5);
    assertEquals(Type.I32, array.get(0));
  }

  @Test
  public void testArraySize() {
    Type array = Type.I32.array(5);
    assertEquals(1, array.size());
  }

  @Test
  public void testVectorKind() {
    Type vector = Type.I32.vector(5);
    assertEquals(Kind.VECTOR, vector.kind());
  }

  @Test
  public void testVectorGet() {
    Type vector = Type.I32.vector(5);
    assertEquals(Type.I32, vector.get(0));
  }

  @Test
  public void testVectorSize() {
    Type vector = Type.I32.vector(5);
    assertEquals(1, vector.size());
  }

  @Test
  public void testStructKind() {
    Type struct = Type.struct(Type.I32, Type.FLOAT);
    assertEquals(Kind.STRUCT, struct.kind());
  }

  @Test
  public void testStructGet() {
    Type struct = Type.struct(Type.I32, Type.FLOAT);
    assertEquals(Type.I32, struct.get(0));
    assertEquals(Type.FLOAT, struct.get(1));
  }

  @Test
  public void testStructSize() {
    Type struct = Type.struct(Type.I32, Type.FLOAT);
    assertEquals(2, struct.size());
  }

  @Test
  public void testFunctionKind() {
    Type function = Type.function(Type.VOID, List.of(Type.I32, Type.FLOAT), false);
    assertEquals(Kind.FUNCTION, function.kind());
  }

  @Test
  public void testFunctionGet() {
    Type function = Type.function(Type.VOID, List.of(Type.I32, Type.FLOAT), false);
    assertEquals(Type.VOID, function.get(0));
    assertEquals(Type.I32, function.get(1));
    assertEquals(Type.FLOAT, function.get(2));
  }

  @Test
  public void testFunctionSize() {
    Type function = Type.function(Type.VOID, List.of(Type.I32, Type.FLOAT), false);
    assertEquals(3, function.size());
  }

  @Test
  public void testIteratorHasNext() {
    Iterator<Type> iterator = Type.VOID.iterator();
    assertFalse(iterator.hasNext());
  }

  @Test
  public void testIteratorNextThrowsException() {
    Iterator<Type> iterator = Type.VOID.iterator();
    assertThrows(UnsupportedOperationException.class, iterator::next);
  }

  @Test
  public void testArrayToString() {
    Type array = Type.I32.array(5);
    assertEquals("[5 x i32]", array.toString());
  }

  @Test
  public void testVectorToString() {
    Type vector = Type.I32.vector(5);
    assertEquals("<5 x i32>", vector.toString());
  }
}
