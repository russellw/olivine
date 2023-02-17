import static org.objectweb.asm.Opcodes.*;

import java.util.Map;

public final class Call extends Term {
  final int opcode;
  final Fn fn;

  @Override
  Term remake(Object[] v) {
    return new Call(opcode, fn, v);
  }

  Object simplify() {
    var v = new Object[args.length];
    for (var i = 0; i < v.length; i++) v[i] = simplify(args[i]);
    return remake(v);
  }

  Type type() {
    return fn.rtype;
  }

  public String toString() {
    var sb = new StringBuilder(fn.toString());
    sb.append('(');
    for (var i = 0; i < args.length; i++) {
      if (i > 0) sb.append(',');
      sb.append(args[i]);
    }
    sb.append(')');
    return sb.toString();
  }

  Object eval(Map<Object, Object> map) {
    var v = new Object[args.length];
    for (var i = 0; i < v.length; i++) v[i] = Etc.get(map, args[i]);
    return fn.interpret(v);
  }

  Call(Fn fn, Object... args) {
    super(args);
    opcode = INVOKESTATIC;
    this.fn = fn;
  }

  Call(int opcode, Fn fn, Object... args) {
    super(args);
    this.opcode = opcode;
    this.fn = fn;
  }
}
