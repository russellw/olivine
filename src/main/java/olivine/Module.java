package olivine;

import java.util.ArrayList;
import java.util.List;

public final class Module {
  public final List<Function> functions = new ArrayList<>();
  public final List<GlobalVariable> variables = new ArrayList<>();

  void dump() {
    for (var function : functions) {
      System.out.println();
      function.dump();
    }
  }

  public void verify() {
    for (var function : functions) function.verifyFunction();
  }
}
