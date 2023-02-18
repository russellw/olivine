import static org.objectweb.asm.Opcodes.*;

import java.lang.reflect.InvocationTargetException;

public class ClassTypeTest {
  public static void main(String[] args) {
    // TODO
    System.exit(0);
    var classType = new ClassType();

    var x = new Variable(classType);
    var f = new Fn(VoidType.instance, "<init>", x);
    f.access = ACC_PUBLIC;
    f.initBlocks();
    f.lastBlock().add(new Call(INVOKESPECIAL, Fn.OBJECT_CTOR, x));
    f.lastBlock().add(new ReturnVoid());
    classType.methods.add(f);

    classType.write();
    var c = new ByteArrayClassLoader().findClass(classType.name());
    try {
      c.getDeclaredConstructor().newInstance();
    } catch (NoSuchMethodException
        | IllegalAccessException
        | InvocationTargetException
        | InstantiationException e) {
      throw new RuntimeException(e);
    }
  }
}
