package olivine;

import static org.junit.jupiter.api.Assertions.*;

import java.util.Iterator;
import java.util.List;
import java.util.Map;
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
    assertThrows(Throwable.class, iterator::next);
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

  @Test
  public void testArray() {
    Type intType = Type.I32;
    Type arrayType = intType.array(5);

    // Verify kind and string representation
    assertEquals(Kind.ARRAY, arrayType.kind());
    assertEquals("[5 x i32]", arrayType.toString());

    // Verify size and get method
    assertEquals(1, arrayType.size());
    assertEquals(intType, arrayType.get(0));

    // Verify iterator
    Iterator<Type> iterator = arrayType.iterator();
    assertTrue(iterator.hasNext());
    assertEquals(intType, iterator.next());
    assertFalse(iterator.hasNext());
  }

  @Test
  public void testVector() {
    Type floatType = Type.FLOAT;
    Type vectorType = floatType.vector(4);

    // Verify kind and string representation
    assertEquals(Kind.VECTOR, vectorType.kind());
    assertEquals("<4 x float>", vectorType.toString());

    // Verify size and get method
    assertEquals(1, vectorType.size());
    assertEquals(floatType, vectorType.get(0));

    // Verify iterator
    Iterator<Type> iterator = vectorType.iterator();
    assertTrue(iterator.hasNext());
    assertEquals(floatType, iterator.next());
    assertFalse(iterator.hasNext());
  }

  @Test
  public void testStruct() {
    Type[] fields = {Type.I32, Type.FLOAT, Type.PTR};
    Type structType = Type.struct(fields);

    // Verify kind and string representation
    assertEquals(Kind.STRUCT, structType.kind());
    assertEquals("{i32,float,ptr}", structType.toString());

    // Verify size and get method
    assertEquals(3, structType.size());
    assertEquals(Type.I32, structType.get(0));
    assertEquals(Type.FLOAT, structType.get(1));
    assertEquals(Type.PTR, structType.get(2));

    // Verify iterator
    Iterator<Type> iterator = structType.iterator();
    assertTrue(iterator.hasNext());
    assertEquals(Type.I32, iterator.next());
    assertTrue(iterator.hasNext());
    assertEquals(Type.FLOAT, iterator.next());
    assertTrue(iterator.hasNext());
    assertEquals(Type.PTR, iterator.next());
    assertFalse(iterator.hasNext());
  }

  @Test
  void testRewriteBaseType() {
    assertEquals(Type.I32, Type.I32.rewrite(new Type[] {}));
    assertEquals(Type.FLOAT, Type.FLOAT.rewrite(new Type[] {}));
  }

  @Test
  void testRewriteArrayType() {
    Type original = Type.I32.array(4);
    Type rewritten = original.rewrite(new Type[] {Type.FLOAT});
    assertEquals(Type.FLOAT.array(4), rewritten);
  }

  @Test
  void testRewriteVectorType() {
    Type original = Type.I32.vector(4);
    Type rewritten = original.rewrite(new Type[] {Type.FLOAT});
    assertEquals(Type.FLOAT.vector(4), rewritten);
  }

  @Test
  void testRewriteStructType() {
    Type original = Type.struct(Type.I32, Type.FLOAT);
    Type rewritten = original.rewrite(new Type[] {Type.DOUBLE, Type.I8});
    assertEquals(Type.struct(Type.DOUBLE, Type.I8), rewritten);
  }

  @Test
  void testRewriteFunctionType() {
    Type original = Type.function(new Type[] {Type.I32, Type.FLOAT}, false);
    Type rewritten = original.rewrite(new Type[] {Type.DOUBLE, Type.I8});
    assertEquals(Type.function(new Type[] {Type.DOUBLE, Type.I8}, false), rewritten);
  }

  @Test
  void testRewriteEmptyStructType() {
    Type original = Type.struct();
    Type rewritten = original.rewrite(new Type[] {});
    assertEquals(Type.struct(), rewritten);
  }

  @Test
  void testResolveUnresolvedType() {
    // Given
    Type unresolvedType = new UnresolvedType("int32");
    Map<String, Type> typeMap = Map.of("int32", Type.I32);

    // When
    Type resolvedType = unresolvedType.resolve(typeMap);

    // Then
    assertEquals(Type.I32, resolvedType);
  }

  @Test
  void testResolveArrayType() {
    // Given
    Type unresolvedType = new UnresolvedType("int32");
    Type arrayType = unresolvedType.array(10);
    Map<String, Type> typeMap = Map.of("int32", Type.I32);

    // When
    Type resolvedType = arrayType.resolve(typeMap);

    // Then
    assertEquals(Type.I32.array(10), resolvedType);
  }

  @Test
  void testResolveStructType() {
    // Given
    Type unresolvedType1 = new UnresolvedType("float");
    Type unresolvedType2 = new UnresolvedType("double");
    Type structType = Type.struct(unresolvedType1, unresolvedType2);
    Map<String, Type> typeMap =
        Map.of(
            "float", Type.FLOAT,
            "double", Type.DOUBLE);

    // When
    Type resolvedType = structType.resolve(typeMap);

    // Then
    Type expectedStruct = Type.struct(Type.FLOAT, Type.DOUBLE);
    assertEquals(expectedStruct, resolvedType);
  }

  @Test
  void testResolveNestedStructType() {
    // Given
    Type unresolvedType1 = new UnresolvedType("float");
    Type unresolvedType2 = new UnresolvedType("nestedStruct");
    Type structType = Type.struct(unresolvedType1, unresolvedType2);
    Type nestedStructType = Type.struct(new UnresolvedType("double"));
    Map<String, Type> typeMap =
        Map.of(
            "float", Type.FLOAT,
            "nestedStruct", nestedStructType,
            "double", Type.DOUBLE);

    // When
    Type resolvedType = structType.resolve(typeMap);

    // Then
    Type expectedNestedStruct = Type.struct(Type.DOUBLE);
    Type expectedStruct = Type.struct(Type.FLOAT, expectedNestedStruct);
    assertEquals(expectedStruct, resolvedType);
  }

  @Test
  void testResolveFunctionType() {
    // Given
    Type unresolvedReturnType = new UnresolvedType("void");
    Type unresolvedParamType1 = new UnresolvedType("int32");
    Type unresolvedParamType2 = new UnresolvedType("float");
    Type functionType =
        Type.function(
            new Type[] {unresolvedReturnType, unresolvedParamType1, unresolvedParamType2}, false);
    Map<String, Type> typeMap =
        Map.of(
            "void", Type.VOID,
            "int32", Type.I32,
            "float", Type.FLOAT);

    // When
    Type resolvedType = functionType.resolve(typeMap);

    // Then
    Type expectedFunctionType = Type.function(new Type[] {Type.VOID, Type.I32, Type.FLOAT}, false);
    assertEquals(expectedFunctionType, resolvedType);
  }
}
