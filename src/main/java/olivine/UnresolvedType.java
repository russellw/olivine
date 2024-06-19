package olivine;

import java.util.Map;

public final class UnresolvedType extends Type {
  final String name;

  @Override
  Type resolve(Map<String, Type> typeMap) {
    return typeMap.get(name).resolve(typeMap);
  }

  UnresolvedType(String name) {
    this.name = name;
  }

  @Override
  public String toString() {
    return name;
  }

  @Override
  public Kind kind() {
    return Kind.UNRESOLVED;
  }
}
