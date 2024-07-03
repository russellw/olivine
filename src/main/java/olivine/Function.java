package olivine;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;

public final class Function extends Global {
  public Block entry;
  public final List<Variable> params = new ArrayList<>();
  public Type returnType;
  public boolean varargs;

  public Function(String name) {
    super(name);
  }

  public List<Block> blocks() {
    var blocks = new ArrayList<Block>();
    if (entry != null) entry.getBlocks(new HashSet<>(), blocks);
    return blocks;
  }

  public void dump() {
    System.out.printf("Function %s %s(", returnType, name);
    var more = false;
    for (var param : params) {
      if (more) System.out.print(", ");
      more = true;
      System.out.printf("%s %s", param.type(), param);
    }
    System.out.println(')');
    for (var block : blocks()) block.dump();
  }

  @Override
  public Tag tag() {
    return Tag.function;
  }

  @Override
  public Type type() {
    throw new UnsupportedOperationException(toString());
  }

  public void verifyFunction() {
    for (var block : blocks()) {
      for (var instruction : block) instruction.verify();
      switch (block.last()) {
        case Ret ret -> {
          assert returnType != Type.VOID;
          assert ret.value.type().equals(returnType);
        }
        case RetVoid _ -> {
          assert returnType == Type.VOID;
        }
        default -> {}
      }
    }
  }
}
