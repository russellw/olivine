import java.util.Map;

public final class Store extends Term {
  final Variable to;

  Object eval(Map<Object, Object> map) {
    map.put(to, Etc.get(map, args[0]));
    return null;
  }

  Store(Variable to, Object a) {
    super(a);
    this.to = to;
  }
}
