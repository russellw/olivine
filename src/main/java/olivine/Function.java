package olivine;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;

public final class Function extends Global {
  public boolean comdat;
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

  void dump() {
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
