import java.lang.reflect.InvocationTargetException;
import java.math.BigInteger;
import java.util.Iterator;
import java.util.Map;
import java.util.function.UnaryOperator;

abstract class Unary extends Instruction {
  Object arg;

  Unary(Object arg) {
    this.arg = arg;
  }

  Object mapLeaves(UnaryOperator<Object> f) {
    try {
      var ctor = getClass().getDeclaredConstructor(Object.class);
      return ctor.newInstance(mapLeaves(f, arg));
    } catch (IllegalAccessException
        | InstantiationException
        | InvocationTargetException
        | NoSuchMethodException e) {
      throw new RuntimeException(e);
    }
  }

  Type type() {
    return Type.of(arg);
  }

  public int size() {
    return 1;
  }

  void set(int i, Object a) {
    assert i == 0;
    arg = a;
  }

  Object get(int i) {
    assert i == 0;
    return arg;
  }

  Object eval(Map<Object, Object> map) {
    var a0 = Etc.get(map, this.arg);
    return switch (a0) {
      case Integer a -> apply(a);
      case BigInteger a -> apply(a);
      case BigRational a -> apply(a);
      case Real a -> {
        var r0 = apply(a.val());
        if (r0 instanceof BigRational r) yield new Real(r);
        yield r0;
      }
      default -> throw new IllegalArgumentException(toString());
    };
  }

  int apply(int a) {
    throw new UnsupportedOperationException(toString());
  }

  Object apply(BigInteger a) {
    throw new UnsupportedOperationException(toString());
  }

  Object apply(BigRational a) {
    throw new UnsupportedOperationException(toString());
  }

  public final Iterator<Object> iterator() {
    return new Iterator<>() {
      private int i;

      public boolean hasNext() {
        return i == 0;
      }

      public Object next() {
        assert i == 0;
        i++;
        return arg;
      }
    };
  }
}
