package olivine;

import java.util.*;

public final class Block implements Iterable<Instruction> {
  private final List<Instruction> instructions = new ArrayList<>();

  public void add(Instruction instruction) {
    instructions.add(instruction);
  }

  void dump() {
    System.out.printf("%x:\n", hashCode());
    for (var instruction : instructions) instruction.dump();
  }

  public Instruction get(int i) {
    return instructions.get(i);
  }

  public void getBlocks(Set<Block> visited, List<Block> blocks) {
    if (!visited.add(this)) return;
    blocks.add(this);
    for (var block : successors()) block.getBlocks(visited, blocks);
  }

  @Override
  public Iterator<Instruction> iterator() {
    return instructions.iterator();
  }

  public Instruction last() {
    return instructions.getLast();
  }

  public Instruction pop() {
    var last = instructions.getLast();
    instructions.remove(size() - 1);
    return last;
  }

  public void remove(int i) {
    instructions.remove(i);
  }

  public void replace(List<Instruction> replacement) {
    instructions.clear();
    instructions.addAll(replacement);
  }

  public int size() {
    return instructions.size();
  }

  public List<Block> successors() {
    if (instructions.isEmpty()) return List.of();
    return switch (last()) {
      case Br br -> List.of(br.ifTrue, br.ifFalse);
      case BrUnconditional brUnconditional -> List.of(brUnconditional.dest);
      default -> List.of();
    };
  }
}
