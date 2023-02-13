import java.util.Map;
import java.util.function.UnaryOperator;

final class Call extends Term {
  final Fn fn;

  Term mapLeaves(UnaryOperator<Object> f) {
    var v = new Object[args.length];
    for (var i = 0; i < v.length; i++) v[i] = mapLeaves(f, args[i]);
    return new Call(fn, v);
  }

  Type type() {
    return fn.rtype;
  }

  public String toString() {
    var sb = new StringBuilder(fn.toString());
    sb.append('(');
    for (var i = 0; i < size(); i++) {
      if (i > 0) sb.append(',');
      sb.append(get(i));
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
    this.fn = fn;
  }
}
