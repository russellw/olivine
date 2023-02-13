import java.lang.reflect.InvocationTargetException;
import java.util.function.UnaryOperator;

abstract class Binary extends Term {

  Binary(Object a, Object b) {
    super(a, b);
  }

  Object mapLeaves(UnaryOperator<Object> f) {
    try {
      var ctor = getClass().getDeclaredConstructor(Object.class, Object.class);
      return ctor.newInstance(mapLeaves(f, args[0]), mapLeaves(f, args[1]));
    } catch (IllegalAccessException
        | InstantiationException
        | InvocationTargetException
        | NoSuchMethodException e) {
      throw new RuntimeException(e);
    }
  }
}
