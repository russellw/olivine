import java.util.HashMap;
import java.util.Map;

final class ByteArrayClassLoader extends ClassLoader {
  static final Map<String, byte[]> map = new HashMap<>();

  public Class<?> findClass(String name) {
    byte[] bytes = map.get(name);
    return defineClass(name, bytes, 0, bytes.length);
  }
}
