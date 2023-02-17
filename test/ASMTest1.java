import java.lang.reflect.InvocationTargetException;
import org.objectweb.asm.ClassWriter;
import org.objectweb.asm.Label;
import org.objectweb.asm.MethodVisitor;
import org.objectweb.asm.Opcodes;

public class ASMTest1 implements Opcodes {
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
      methodVisitor.visitLineNumber(1, label0);
      methodVisitor.visitVarInsn(ALOAD, 0);
      methodVisitor.visitMethodInsn(INVOKESPECIAL, "java/lang/Object", "<init>", "()V", false);
      methodVisitor.visitInsn(RETURN);
      methodVisitor.visitMaxs(1, 1);
      methodVisitor.visitEnd();
    }
    {
      methodVisitor = classWriter.visitMethod(0, "square", "(I)I", null, null);
      methodVisitor.visitCode();
      Label label0 = new Label();
      methodVisitor.visitLabel(label0);
      methodVisitor.visitLineNumber(3, label0);
      methodVisitor.visitVarInsn(ILOAD, 1);
      methodVisitor.visitVarInsn(ILOAD, 1);
      methodVisitor.visitInsn(IMUL);
      methodVisitor.visitInsn(IRETURN);
      methodVisitor.visitMaxs(2, 2);
      methodVisitor.visitEnd();
    }
    {
      methodVisitor = classWriter.visitMethod(ACC_PUBLIC, "entry", "()I", null, null);
      methodVisitor.visitCode();
      Label label0 = new Label();
      methodVisitor.visitLabel(label0);
      methodVisitor.visitLineNumber(6, label0);
      methodVisitor.visitVarInsn(ALOAD, 0);
      methodVisitor.visitIntInsn(BIPUSH, 9);
      methodVisitor.visitMethodInsn(INVOKEVIRTUAL, "Test", "square", "(I)I", false);
      methodVisitor.visitInsn(IRETURN);
      methodVisitor.visitMaxs(2, 1);
      methodVisitor.visitEnd();
    }
    classWriter.visitEnd();
    var bytes = classWriter.toByteArray();

    ByteArrayClassLoader.map.put("Test", bytes);
    var c = new ByteArrayClassLoader().findClass("Test");
    try {
      var x = c.getConstructor().newInstance();
      assert c.getMethod("entry").invoke(x).equals(81);
    } catch (NoSuchMethodException
        | IllegalAccessException
        | InvocationTargetException
        | InstantiationException e) {
      throw new RuntimeException(e);
    }
  }
}
