package olivine;

import static org.junit.jupiter.api.Assertions.*;

import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class FunctionTest {
  private Function function;
  private Type voidType;
  private Type intType;
  private Block block;

  @BeforeEach
  public void setup() {
    voidType = Type.VOID;
    intType = Type.I32;
    block = new Block();
  }

  @Test
  public void testBlocksSingleBlock() {
    Block entry = new Block();
    Function function = new Function("testFunction", Type.VOID, List.of(), false);
    function.entry = entry;

    List<Block> blocks = function.blocks();

    assertEquals(1, blocks.size());
    assertTrue(blocks.contains(entry));
  }

  @Test
  public void testBlocksMultipleBlocks() {
    Block entry = new Block();
    Block block2 = new Block();
    Block block3 = new Block();

    entry.add(new BrUnconditional(block2));
    block2.add(new BrUnconditional(block3));

    Function function = new Function("testFunction", Type.VOID, List.of(), false);
    function.entry = entry;

    List<Block> blocks = function.blocks();

    assertEquals(3, blocks.size());
    assertTrue(blocks.contains(entry));
    assertTrue(blocks.contains(block2));
    assertTrue(blocks.contains(block3));
  }

  @Test
  public void testBlocksNoEntry() {
    Function function = new Function("testFunction", Type.VOID, List.of(), false);

    List<Block> blocks = function.blocks();

    assertTrue(blocks.isEmpty());
  }

  @Test
  public void testVerifyFunctionWithVoidReturnTypeAndRetVoid() {
    function = new Function("testFunction", voidType, List.of(), false);
    block.add(new RetVoid());
    function.entry = block;

    assertDoesNotThrow(() -> function.verifyFunction());
  }

  @Test
  public void testVerifyFunctionWithNonVoidReturnTypeAndRet() {
    function = new Function("testFunction", intType, List.of(), false);
    Term returnValue = Term.intConstant(intType, 10);
    block.add(new Ret(returnValue));
    function.entry = block;

    assertDoesNotThrow(() -> function.verifyFunction());
  }

  @Test
  public void testVerifyFunctionWithVoidReturnTypeAndRet() {
    function = new Function("testFunction", voidType, List.of(), false);
    Term returnValue = Term.intConstant(intType, 10);
    block.add(new Ret(returnValue));
    function.entry = block;

    assertThrows(AssertionError.class, () -> function.verifyFunction());
  }

  @Test
  public void testVerifyFunctionWithNonVoidReturnTypeAndRetVoid() {
    function = new Function("testFunction", intType, List.of(), false);
    block.add(new RetVoid());
    function.entry = block;

    assertThrows(AssertionError.class, () -> function.verifyFunction());
  }

  @Test
  public void testVerifyFunctionWithNonVoidReturnTypeAndRetWithMismatchedType() {
    function = new Function("testFunction", intType, List.of(), false);
    Term returnValue = Term.intConstant(Type.I1, 1);
    block.add(new Ret(returnValue));
    function.entry = block;

    assertThrows(AssertionError.class, () -> function.verifyFunction());
  }
}
