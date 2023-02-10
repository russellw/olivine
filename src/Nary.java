import java.util.Iterator;

abstract class Nary extends Instruction {
  final Object[] args;

  Nary(Object[] args) {
    this.args = args;
  }

  void set(int i, Object a) {
    args[i] = a;
  }

  public int size() {
    return args.length;
  }

  Object get(int i) {
    return args[i];
  }

  public final Iterator<Object> iterator() {
    return new Iterator<>() {
      private int i;

      public boolean hasNext() {
        return i < args.length;
      }

      public Object next() {
        return args[i++];
      }
    };
  }
}
