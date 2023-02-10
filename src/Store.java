import java.util.Map;

final class Store extends Unary {
  final Var to;

  Object eval(Map<Object, Object> map) {
    map.put(to, Etc.get(map, arg));
    return null;
  }

  Store(Var to, Object arg) {
    super(arg);
    this.to = to;
  }
}
