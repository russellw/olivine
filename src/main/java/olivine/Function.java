package olivine;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;

public final class Function extends Global {
  public Block entry;
  public final List<Variable> params;
  public final Type returnType;
  public final boolean varargs;

  public Function(String name, Type returnType, List<Variable> params, boolean varargs) {
    super(name);
    this.returnType = returnType;
    this.params = params;
    this.varargs = varargs;
  }

  public List<Block> blocks() {
    var blocks = new ArrayList<Block>();
    if (entry != null) entry.getBlocks(new HashSet<>(), blocks);
    return blocks;
  }

  @Override
  public Tag tag() {
    return Tag.FUNCTION;
  }

  @Override
  public Type type() {
    throw new UnsupportedOperationException(toString());
  }

  public void verifyFunction() {
    for (var block : blocks()) {
      for (var instruction : block) instruction.verify();
      switch (block.last()) {
        case RetVoid _ -> {
          assert returnType == Type.VOID;
        }
        case Ret ret -> {
          assert returnType != Type.VOID;
          assert ret.value.type().equals(returnType);
        }
        default -> {}
      }
    }
  }
}
