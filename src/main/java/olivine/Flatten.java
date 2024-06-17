package olivine;

import java.util.ArrayList;
import java.util.List;

public final class Flatten {
  private final List<Instruction> replacement = new ArrayList<>();

  static boolean flat(Term term) {
    for (var arg : term) if (arg.size() != 0) return false;
    return true;
  }

  private Term flatten(Term term) {
    if (flat(term)) return term;
    var args = new Term[term.size()];
    for (var i = 0; i < args.length; i++) {
      var arg = term.get(i);
      if (arg.size() != 0) {
        var variable = new Variable(arg.type());
        replacement.add(new Assign(variable, flatten(arg)));
        arg = variable;
      }
      args[i] = arg;
    }
    return term.rewrite(args);
  }

  private Flatten(Module module) {
    for (var function : module.functions) {
      for (var block : function.blocks()) {
        replacement.clear();
        for (var instruction : block) {
          instruction =
              switch (instruction) {
                case Assign assign -> new Assign(assign.variable, flatten(assign.value));
                default -> instruction;
              };
          replacement.add(instruction);
        }
        block.replace(replacement);
      }
    }
  }

  public static void run(Module module) {
    new Flatten(module);
  }
}
