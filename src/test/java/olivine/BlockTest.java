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
    assignInstruction = new Assign(new Variable(Type.I32), Term.intConstant(Type.I32, 42));
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

  @Test
  public void testPop() {
    block.add(assignInstruction);
    block.add(retVoidInstruction);
    assertEquals(retVoidInstruction, block.pop());
    assertEquals(1, block.size());
    assertEquals(assignInstruction, block.pop());
    assertEquals(0, block.size());
    assertThrows(RuntimeException.class, () -> block.pop());
  }

  @Test
  public void testRemove() {
    block.add(assignInstruction);
    block.add(retVoidInstruction);
    block.remove(0);
    assertEquals(1, block.size());
    assertEquals(retVoidInstruction, block.last());
    block.remove(0);
    assertEquals(0, block.size());
    assertThrows(IndexOutOfBoundsException.class, () -> block.remove(0));
  }

  @Test
  public void testAddMultiple() {
    for (int i = 0; i < 100; i++) {
      block.add(new Assign(new Variable(Type.I32), Term.intConstant(Type.I32, i)));
    }
    assertEquals(100, block.size());
    for (int i = 99; i >= 0; i--) {
      assertEquals(Term.intConstant(Type.I32, i), getTerm(block.pop()));
    }
    assertEquals(0, block.size());
  }

  private Term getTerm(Instruction instruction) {
    return ((Assign) instruction).value;
  }

  @Test
  public void testIteratorWithMultipleElements() {
    for (int i = 0; i < 100; i++) {
      block.add(new Assign(new Variable(Type.I32), Term.intConstant(Type.I32, i)));
    }
    int count = 0;
    for (Instruction instr : block) {
      assertEquals(Term.intConstant(Type.I32, count), getTerm(instr));
      count++;
    }
    assertEquals(100, count);
  }
}
