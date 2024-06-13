package olivine;

import static org.junit.jupiter.api.Assertions.*;

import java.util.List;
import org.junit.jupiter.api.Test;

class FunctionTest {
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
}
