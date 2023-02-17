import static org.objectweb.asm.Opcodes.*;

import java.lang.reflect.InvocationTargetException;

public class ClassTypeTest {
  public static void main(String[] args) {
    // TODO
    System.exit(0);
    var t = new ClassType();

    var x = new Variable(t);
    var f = new Fn(VoidType.instance, "<init>", x);
    f.initBlocks();
    f.lastBlock().add(new Call(INVOKESPECIAL, Fn.OBJECT_CTOR, x));
    t.methods.add(f);

    t.write();
    var c = new ByteArrayClassLoader().findClass(t.name());
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
