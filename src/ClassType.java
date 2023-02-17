import static org.objectweb.asm.Opcodes.*;

import java.util.ArrayList;
import java.util.List;
import org.objectweb.asm.ClassWriter;

public final class ClassType extends Type {
  static final int VERSION = V18;

  private static int nameCount;
  private String name;

  List<Variable> fields = new ArrayList<>();
  List<Fn> methods = new ArrayList<>();

  String name() {
    if (name == null) name = "_" + nameCount++;
    return name;
  }

  void write() {
    var classWriter = new ClassWriter(ClassWriter.COMPUTE_FRAMES);
    classWriter.visit(VERSION, ACC_PUBLIC | ACC_SUPER, name(), null, "java/lang/Object", null);
    for (var f : methods) f.write(this, classWriter);
    ByteArrayClassLoader.map.put(name, classWriter.toByteArray());
  }
}
