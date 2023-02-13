import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

final class Fn {
  Type rtype;
  String name;
  Variable[] params;
  List<List<Term>> blocks;

  Fn(Type rtype, String name, Variable... params) {
    this.rtype = rtype;
    this.name = name;
    this.params = params;
  }

  Type type() {
    return rtype;
  }

  public String toString() {
    if (name != null) return name;
    return "Fn@" + Integer.toHexString(hashCode());
  }

  void initBlocks() {
    blocks = new ArrayList<>(List.of(new ArrayList<>()));
  }

  Object interpret(Object[] args) {
    assert args.length == params.length;
    var map = new HashMap<>();
    for (var i = 0; i < args.length; i++) map.put(params[i], args[i]);

    var block = blocks.get(0);
    var i = 0;
    for (; ; ) {
      var a0 = block.get(i++);
      switch (a0) {
        case Return a -> {
          return Etc.get(map, a.args[0]);
        }
        case Goto a -> {
          block = a.target;
          i = 0;
        }
        case If a -> {
          block = ((boolean) Etc.get(map, a.args[0])) ? a.yes : a.no;
          i = 0;
        }
        default -> map.put(a0, a0.eval(map));
      }
    }
  }
}
