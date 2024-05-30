package olivine;

import static org.junit.jupiter.api.Assertions.*;

import java.util.Iterator;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class BlockTest {
  private Block block;
  private Instruction assignInstruction;
  private Instruction retVoidInstruction;

  @BeforeEach
  public void setUp() {
    block = new Block();
    assignInstruction = new Assign(new Var(Type.I32), Term.intConstant(Type.I32, 42));
    retVoidInstruction = new RetVoid();
  }

  @Test
  public void testAdd() {
    block.add(assignInstruction);
    assertEquals(1, block.size());
  }

  @Test
  public void testSize() {
    assertEquals(0, block.size());
    block.add(assignInstruction);
    assertEquals(1, block.size());
    block.add(retVoidInstruction);
    assertEquals(2, block.size());
  }

  @Test
  public void testLast() {
    block.add(assignInstruction);
    assertEquals(assignInstruction, block.last());
    block.add(retVoidInstruction);
    assertEquals(retVoidInstruction, block.last());
  }

  @Test
  public void testIterator() {
    block.add(assignInstruction);
    block.add(retVoidInstruction);

    Iterator<Instruction> iterator = block.iterator();
    assertTrue(iterator.hasNext());
    assertEquals(assignInstruction, iterator.next());
    assertTrue(iterator.hasNext());
    assertEquals(retVoidInstruction, iterator.next());
    assertFalse(iterator.hasNext());
  }

  @Test
  public void testEmptyBlock() {
    assertEquals(0, block.size());
    assertThrows(RuntimeException.class, () -> block.last());
  }
}
