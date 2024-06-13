package olivine;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Set;

public final class Block implements Iterable<Instruction> {
  private final List<Instruction> instructions = new ArrayList<>();

  List<Block> successors() {
    return switch (last()) {
      case BrUnconditional brUnconditional -> List.of(brUnconditional.dest);
      case Br br -> List.of(br.ifTrue, br.ifFalse);
      default -> List.of();
    };
  }

  @Override
  public Iterator<Instruction> iterator() {
    return instructions.iterator();
  }

  public void getBlocks(Set<Block> visited, List<Block> blocks) {
    if (!visited.add(this)) return;
    blocks.add(this);
    for (var block : successors()) block.getBlocks(visited, blocks);
  }

  public Instruction pop() {
    var last = instructions.getLast();
    instructions.remove(size() - 1);
    return last;
  }

  public void remove(int i) {
    instructions.remove(i);
  }

  public void add(Instruction instruction) {
    instructions.add(instruction);
  }

  public int size() {
    return instructions.size();
  }

  public Instruction last() {
    return instructions.getLast();
  }
}
