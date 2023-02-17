import java.lang.reflect.InvocationTargetException;
import org.objectweb.asm.ClassWriter;
import org.objectweb.asm.Label;
import org.objectweb.asm.MethodVisitor;
import org.objectweb.asm.Opcodes;

public class ASMTest implements Opcodes {
  public static void main(String[] args) {
    ClassWriter classWriter = new ClassWriter(0);
    MethodVisitor methodVisitor;

    classWriter.visit(
        ClassType.VERSION, ACC_PUBLIC | ACC_SUPER, "Test", null, "java/lang/Object", null);

    classWriter.visitSource("Test.java", null);

    {
      methodVisitor = classWriter.visitMethod(ACC_PUBLIC, "<init>", "()V", null, null);
      methodVisitor.visitCode();
      Label label0 = new Label();
      methodVisitor.visitLabel(label0);
      methodVisitor.visitLineNumber(2, label0);
      methodVisitor.visitVarInsn(ALOAD, 0);
      methodVisitor.visitMethodInsn(INVOKESPECIAL, "java/lang/Object", "<init>", "()V", false);
      methodVisitor.visitInsn(RETURN);
      methodVisitor.visitMaxs(1, 1);
      methodVisitor.visitEnd();
    }
    {
      methodVisitor = classWriter.visitMethod(ACC_PUBLIC, "pass", "()V", null, null);
      methodVisitor.visitCode();
      Label label0 = new Label();
      methodVisitor.visitLabel(label0);
      methodVisitor.visitLineNumber(3, label0);
      methodVisitor.visitInsn(RETURN);
      methodVisitor.visitMaxs(0, 1);
      methodVisitor.visitEnd();
    }
    classWriter.visitEnd();

    var bytes = classWriter.toByteArray();

    ByteArrayClassLoader.map.put("Test", bytes);
    var c = new ByteArrayClassLoader().findClass("Test");
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
