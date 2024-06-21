package olivine;

import java.util.Map;

public final class UnresolvedType extends Type {
  private final String name;

  public UnresolvedType(String name) {
    this.name = name;
  }

  @Override
  public Kind kind() {
    return Kind.UNRESOLVED;
  }

  @Override
  public Type resolve(Map<String, Type> typeMap) {
    return typeMap.get(name).resolve(typeMap);
  }

  @Override
  public String toString() {
    return name;
  }
}
