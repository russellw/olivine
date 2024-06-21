package olivine;

import java.util.ArrayList;
import java.util.List;

public final class Flatten {
  private final List<Instruction> replacement = new ArrayList<>();

  public static boolean flat(Term term) {
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
                case Ret ret -> new Ret(flatten(ret.value));
                case Br br -> new Br(flatten(br.cond), br.ifTrue, br.ifFalse);
                case VoidCall voidCall -> new VoidCall(flatten(voidCall.call));
                case Store store -> new Store(flatten(store.value), flatten(store.pointer));
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
