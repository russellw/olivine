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

  void add(Instruction instruction) {
    instructions.add(instruction);
  }
}
