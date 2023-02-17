import java.util.Map;

public final class Eq extends Term {
  Type type() {
    return BooleanType.instance;
  }

  Object eval(Map<Object, Object> map) {
    var a = Etc.get(map, this.args[0]);
    var b = Etc.get(map, this.args[1]);
    return a.equals(b);
  }

  Eq(Object a, Object b) {
    super(a, b);
  }
}
