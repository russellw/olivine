import java.lang.reflect.InvocationTargetException;
import java.math.BigInteger;
import java.util.Iterator;
import java.util.Map;
import java.util.function.UnaryOperator;

abstract class Binary extends Term {
  Object arg0, arg1;

  Binary(Object arg0, Object arg1) {
    this.arg0 = arg0;
    this.arg1 = arg1;
  }

  void set(int i, Object a) {
    assert i >= 0;
    assert i < 2;
    if (i == 0) {
      arg0 = a;
      return;
    }
    arg1 = a;
  }

  Object get(int i) {
    assert i >= 0;
    assert i < 2;
    if (i == 0) return arg0;
    return arg1;
  }

  public int size() {
    return 2;
  }

  Object apply(int a, int b) {
    throw new UnsupportedOperationException(toString());
  }

  Object apply(BigInteger a, BigInteger b) {
    throw new UnsupportedOperationException(toString());
  }

  Object apply(BigRational a, BigRational b) {
    throw new UnsupportedOperationException(toString());
  }

  Type type() {
    return Type.of(arg0);
  }

  Object mapLeaves(UnaryOperator<Object> f) {
    try {
      var ctor = getClass().getDeclaredConstructor(Object.class, Object.class);
      return ctor.newInstance(mapLeaves(f, arg0), mapLeaves(f, arg1));
    } catch (IllegalAccessException
        | InstantiationException
        | InvocationTargetException
        | NoSuchMethodException e) {
      throw new RuntimeException(e);
    }
  }

  Object eval(Map<Object, Object> map) {
    var a0 = Etc.get(map, this.arg0);
    var b = Etc.get(map, this.arg1);
    return switch (a0) {
      case Integer a -> apply(a, (Integer) b);
      case BigInteger a -> apply(a, (BigInteger) b);
      case BigRational a -> apply(a, (BigRational) b);
      case Real a -> {
        var r0 = apply(a.val(), ((Real) b).val());
        if (r0 instanceof BigRational r) yield new Real(r);
        yield r0;
      }
      default -> throw new IllegalArgumentException(toString());
    };
  }

  public final Iterator<Object> iterator() {
    return new Iterator<>() {
      private int i;

      public boolean hasNext() {
        assert i >= 0;
        return i < 2;
      }

      public Object next() {
        return get(i++);
      }
    };
  }
}
