import java.lang.reflect.InvocationTargetException;
import org.objectweb.asm.ClassWriter;
import org.objectweb.asm.Label;
import org.objectweb.asm.MethodVisitor;
import org.objectweb.asm.Opcodes;

public class ASMTest2 implements Opcodes {
  public static void main(String[] args) {
    ClassWriter classWriter = new ClassWriter(0);
    MethodVisitor methodVisitor;

    classWriter.visit(
        ClassType.VERSION, ACC_PUBLIC | ACC_SUPER, "TestEtc", null, "java/lang/Object", null);

    classWriter.visitSource("TestEtc.java", null);

    {
      methodVisitor = classWriter.visitMethod(ACC_PUBLIC, "<init>", "()V", null, null);
      methodVisitor.visitCode();
      Label label0 = new Label();
      methodVisitor.visitLabel(label0);
      methodVisitor.visitLineNumber(1, label0);
      methodVisitor.visitVarInsn(ALOAD, 0);
      methodVisitor.visitMethodInsn(INVOKESPECIAL, "java/lang/Object", "<init>", "()V", false);
      methodVisitor.visitInsn(RETURN);
      methodVisitor.visitMaxs(1, 1);
      methodVisitor.visitEnd();
    }
    {
      methodVisitor = classWriter.visitMethod(ACC_PUBLIC | ACC_STATIC, "check", "()Z", null, null);
      methodVisitor.visitCode();
      Label label0 = new Label();
      methodVisitor.visitLabel(label0);
      methodVisitor.visitLineNumber(3, label0);
      methodVisitor.visitIntInsn(BIPUSH, 65);
      methodVisitor.visitMethodInsn(INVOKESTATIC, "Etc", "isUpper", "(I)Z", false);
      methodVisitor.visitInsn(IRETURN);
      methodVisitor.visitMaxs(1, 0);
      methodVisitor.visitEnd();
    }
    classWriter.visitEnd();

    var bytes = classWriter.toByteArray();

    ByteArrayClassLoader.map.put("TestEtc", bytes);
    var c = new ByteArrayClassLoader().findClass("TestEtc");
    try {
      assert c.getMethod("check").invoke(null) == Boolean.TRUE;
    } catch (NoSuchMethodException | IllegalAccessException | InvocationTargetException e) {
      throw new RuntimeException(e);
    }
  }
}
