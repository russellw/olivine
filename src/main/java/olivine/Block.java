package olivine;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

public final class Block implements Iterable<Instruction> {
  private final List<Instruction> instructions = new ArrayList<>();

  @Override
  public Iterator<Instruction> iterator() {
    return instructions.iterator();
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
