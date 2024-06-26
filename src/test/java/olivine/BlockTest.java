package olivine;

import static org.junit.jupiter.api.Assertions.*;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class BlockTest {
  private Block block;
  private Instruction assignInstruction;
  private Instruction retVoidInstruction;
  private List<Instruction> initialInstructions;
  private List<Instruction> replacementInstructions;

  @BeforeEach
  public void setUp() {
    block = new Block();
    assignInstruction = new Assign(new Variable(Type.I32), Term.intConstant(Type.I32, 42));
    retVoidInstruction = new RetVoid();

    initialInstructions = new ArrayList<>();
    replacementInstructions = new ArrayList<>();

    // Adding initial instructions to the block
    initialInstructions.add(new RetVoid());
    initialInstructions.add(new RetVoid());

    // Adding replacement instructions
    replacementInstructions.add(new RetVoid());
    replacementInstructions.add(new BrUnconditional(new Block()));
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

  @Test
  public void testSuccessorsWithBrUnconditional() {
    Block dest = new Block();
    Block block = new Block();
    block.add(new BrUnconditional(dest));

    List<Block> successors = block.successors();

    assertEquals(1, successors.size());
    assertTrue(successors.contains(dest));
  }

  @Test
  public void testSuccessorsWithBr() {
    Block ifTrue = new Block();
    Block ifFalse = new Block();
    Block block = new Block();
    block.add(new Br(Term.TRUE, ifTrue, ifFalse));

    List<Block> successors = block.successors();

    assertEquals(2, successors.size());
    assertTrue(successors.contains(ifTrue));
    assertTrue(successors.contains(ifFalse));
  }

  @Test
  public void testSuccessorsWithNoBranches() {
    Block block = new Block();
    block.add(new RetVoid());

    List<Block> successors = block.successors();

    assertTrue(successors.isEmpty());
  }

  @Test
  void testReplaceClearsExistingInstructions() {
    // Ensure the block has initial instructions
    assertEquals(0, block.size());

    // Replace instructions
    block.replace(replacementInstructions);

    // Ensure the block's instructions have been replaced
    assertEquals(2, block.size());
    assertEquals(replacementInstructions, blockToList(block));
  }

  @Test
  void testReplaceWithEmptyList() {
    // Replace instructions with an empty list
    block.replace(new ArrayList<>());

    // Ensure the block is now empty
    assertEquals(0, block.size());
  }

  @Test
  void testReplaceWithNonEmptyList() {
    // Replace instructions with a non-empty list
    block.replace(replacementInstructions);

    // Ensure the block has the same instructions as the replacement list
    assertEquals(2, block.size());
    assertEquals(replacementInstructions, blockToList(block));
  }

  @Test
  void testReplaceMultipleTimes() {
    // Replace instructions with a non-empty list
    block.replace(replacementInstructions);

    // Replace again with the initial list
    block.replace(initialInstructions);

    // Ensure the block has the same instructions as the initial list
    assertEquals(2, block.size());
    assertEquals(initialInstructions, blockToList(block));

    // Replace again with an empty list
    block.replace(new ArrayList<>());

    // Ensure the block is now empty
    assertEquals(0, block.size());
  }

  private List<Instruction> blockToList(Block block) {
    List<Instruction> instructionsList = new ArrayList<>();
    block.forEach(instructionsList::add);
    return instructionsList;
  }
}
