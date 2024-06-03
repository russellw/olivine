package olivine;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public final class Module {
  public final Set<String> comdats = new HashSet<>();
  public final List<GlobalVariable> vars = new ArrayList<>();
  public final List<Function> functions = new ArrayList<>();
}
