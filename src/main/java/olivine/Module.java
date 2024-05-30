package olivine;

import java.util.ArrayList;
import java.util.List;

public final class Module {
  public final List<GlobalVar> vars = new ArrayList<>();
  public final List<Fn> fns = new ArrayList<>();
}
