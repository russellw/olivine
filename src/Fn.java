import static org.objectweb.asm.Opcodes.*;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import org.objectweb.asm.ClassWriter;
import org.objectweb.asm.Label;

public final class Fn {
  static final Fn OBJECT_CTOR =
      new Fn(VoidType.instance, "<init>", new Variable(ObjectType.instance));

  int access = ACC_PUBLIC | ACC_STATIC;

  Type rtype;
  String name;
  Variable[] params;
  List<List<Term>> blocks;

  Fn(Type rtype, String name, Variable... params) {
    this.rtype = rtype;
    this.name = name;
    this.params = params;
  }

  String descriptor() {
    var sb = new StringBuilder("(");
    var i = 0;
    if ((access & ACC_STATIC) == 0) i++;
    for (; i < params.length; i++) sb.append(params[i].type.descriptor());
    sb.append(')');
    sb.append(rtype);
    return sb.toString();
  }

  Type type() {
    // TODO is this method needed?
    return rtype;
  }

  List<Term> lastBlock() {
    return blocks.get(blocks.size() - 1);
  }

  void write(ClassType classType, ClassWriter classWriter) {
    var methodVisitor = classWriter.visitMethod(access, name, descriptor(), null, null);
    methodVisitor.visitCode();

    var labels = new HashMap<List<Term>, Label>();
    for (var block : blocks) labels.put(block, new Label());

    for (var block : blocks) {
      methodVisitor.visitLabel(labels.get(block));
      for (var a : block) a.write(methodVisitor);
    }

    methodVisitor.visitMaxs(0, 0);
    methodVisitor.visitEnd();
  }

  public String toString() {
    if (name != null) return name;
    return "Fn@" + Integer.toHexString(hashCode());
  }

  void initBlocks() {
    blocks = new ArrayList<>(List.of(new ArrayList<>()));
  }

  Object interpret(Object[] args) {
    assert args.length == params.length;
    var map = new HashMap<>();
    for (var i = 0; i < args.length; i++) map.put(params[i], args[i]);

    var block = blocks.get(0);
    var i = 0;
    for (; ; ) {
      var a = block.get(i++);
      switch (a) {
        case ReturnVoid ignored -> {
          return null;
        }
        case Return ignored -> {
          return Etc.get(map, a.args[0]);
        }
        case Goto a1 -> {
          block = a1.target;
          i = 0;
        }
        case If a1 -> {
          block = ((boolean) Etc.get(map, a1.args[0])) ? a1.yes : a1.no;
          i = 0;
        }
        default -> map.put(a, a.eval(map));
      }
    }
  }
}
