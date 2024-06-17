package olivine;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;

public final class Function extends Global {
  public final Type returnType;
  public final List<Variable> params;
  public final boolean varargs;
  public Block entry;

  void verifyFunction() {
    for (var block : blocks()) {
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
      for (var instruction : block) instruction.verify();
    }
  }

  public Function(String name, Type returnType, List<Variable> params, boolean varargs) {
    super(name);
    this.returnType = returnType;
    this.params = params;
    this.varargs = varargs;
  }

  @Override
  public Type type() {
    throw new UnsupportedOperationException(toString());
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
}
