package olivine;

import java.util.ArrayList;
import java.util.List;

public final class Flatten {
  private Flatten() {}

  private static Term flatten(Term term, List<Instruction> flat) {
    if (term.size() == 0) return term;
    var terms = new Term[term.size()];
    for (var i = 0; i < terms.length; i++) terms[i] = flatten(term.get(i), flat);
    return term.rewrite(terms);
  }

  public static void run(Module module) {
    for (var function : module.functions) {
      for (var block : function.blocks()) {
        var flat = new ArrayList<Instruction>();
        for (var instruction : block) {
          instruction =
              switch (instruction) {
                case Assign assign -> new Assign(assign.variable, flatten(assign.value, flat));
                default -> instruction;
              };
          flat.add(instruction);
        }
        block.replace(flat);
      }
    }
  }
}
