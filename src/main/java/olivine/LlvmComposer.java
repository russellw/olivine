package olivine;

import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.util.*;

public final class LlvmComposer {
  private final ByteArrayOutputStream stream = new ByteArrayOutputStream();
  private final Map<Object, String> locals = new HashMap<>();

  public static String scast(Term a) {
    var from = a.get(0).type();
    var to = a.type();
    assert !from.equals(to);
    if (from.isInt()) {
      if (to.isInt()) {
        assert from.bits() < to.bits();
        return "sext";
      }
      if (to.isFloat()) return "sitofp";
    } else if (from.isFloat()) if (to.isInt()) return "fptosi";
    throw new IllegalArgumentException(a.toString());
  }

  public static String cast(Term a) {
    var from = a.get(0).type();
    var to = a.type();
    assert !from.equals(to);
    if (from == Type.PTR) {
      if (to.isInt()) return "ptrtoint";
    } else if (from.isInt()) {
      if (to == Type.PTR) return "inttoptr";
      if (to.isInt()) {
        if (from.bits() < to.bits()) return "zext";
        assert from.bits() > to.bits();
        return "trunc";
      }
      if (to.isFloat()) return "uitofp";
    } else if (from.isFloat()) {
      if (to.isInt()) return "fptoui";
      if (to.isFloat()) {
        if (from.bits() < to.bits()) return "fpext";
        // TODO: what happens when float types are the same size?
        assert from.bits() > to.bits();
        return "fptrunc";
      }
    }
    throw new IllegalArgumentException(a.toString());
  }

  private void local(Object o) {
    print('%');
    var s = locals.get(o);
    if (s == null) {
      s = Integer.toString(locals.size());
      locals.put(o, s);
    }
    print(s);
  }

  private void print(int c) {
    stream.write(c);
  }

  private void print(Type type) {
    print(type.toString());
  }

  private void print(String s) {
    stream.writeBytes(s.getBytes(StandardCharsets.UTF_8));
  }

  private void id(String s) {
    if (isId(s)) {
      print(s);
      return;
    }
    print('"');
    for (var i = 0; i < s.length(); i++) {
      int c = s.charAt(i);
      if (Etc.isPrint(c) && c != '"' && c != '\\') {
        print(c);
        continue;
      }
      print('\\');
      print(Etc.hexDigit(c >> 4));
      print(Etc.hexDigit(c & 0xf));
    }
    print('"');
  }

  public static boolean isId(String s) {
    if (s.isEmpty()) return false;
    if (Etc.isDigit(s.charAt(0))) return false;
    for (var i = 0; i < s.length(); i++) if (!LlvmParser.isIdPart(s.charAt(i))) return false;
    return true;
  }

  private LlvmComposer(Module module) {
    for (var variable : module.variables) {
      print('@');
      id(variable.name);
      print('=');
      if (variable.value == null) print("external ");
      print("global ");
      print(variable.type());
      if (variable.value != null) {
        print(' ');
        // TODO: could be gep
        atom(variable.value);
      }
      print('\n');
    }
    for (var function : module.functions) {
      print(function.entry == null ? "declare " : "define ");
      print(function.returnType);
      print(" @");
      id(function.name);
      print('(');
      locals.clear();
      var more = false;
      for (var a : function.params) {
        if (more) print(',');
        more = true;
        typeAtom(a);
      }
      if (function.varargs) print(",...");
      print(')');

      // Empty function is only declared, not defined
      if (function.entry == null) {
        print('\n');
        continue;
      }

      var blocks = function.blocks();

      // Count how many times each local variable is assigned
      var assignCounts = new LinkedHashMap<Variable, Integer>();
      for (var block : blocks)
        for (var instruction : block)
          if (instruction instanceof Assign assign) {
            var variable = assign.variable;
            assignCounts.put(variable, assignCounts.getOrDefault(variable, 0) + 1);
          }

      // Look at the ones that are assigned more than once
      var vars = new HashSet<Variable>();
      for (var kv : assignCounts.entrySet()) if (kv.getValue() > 1) vars.add(kv.getKey());

      // They need to be converted to alloca
      var allocas = new ArrayList<Assign>();
      for (var x : vars)
        allocas.add(new Assign(x, Term.alloca(x.type(), Term.intConstant(Type.I32, 1))));
      function.entry.addAll(0, allocas);

      // Convert assignment to store
      for (var block : blocks) {
        @SuppressWarnings("unchecked")
        var replacements = (List<Val>[]) new List[block.size()];
        for (int i = 0, instructionsSize = block.size(); i < instructionsSize; i++) {
          var a = block.get(i);
          if (a.tag() == Tag.ASSIGN && a.get(0) instanceof Var x) {
            if (!vars.contains(x)) continue;
            var y = new Var(x.type());
            var calc = Val.of(Tag.ASSIGN, y, a.get(1));
            var store = Val.of(Tag.ASSIGN, Val.of(Tag.LOAD, y), x);
            replacements[i] = List.of(calc, store);
          }
        }
        block.replace(replacements);
      }

      // Convert reference to load
      for (var block : blocks) {
        var instructions = block.instructions;
        @SuppressWarnings("unchecked")
        var replacements = (List<Val>[]) new List[instructions.size()];
        for (int i = 0, instructionsSize = instructions.size(); i < instructionsSize; i++) {
          var a = instructions.get(i);
          var loads = new ArrayList<Val>();
          for (var x : vars)
            if (a.containsLeaf(x)) {
              var y = new Var(x.type());
              loads.add(Val.of(Tag.ASSIGN, y, new Alloca(x.type(), x)));
            }
        }
        block.replace(replacements);
      }

      // Print body
      print("{\n");
      for (var block : blocks) {
        nameLocal(block);
        for (var a : block.instructions) if (a.tag() == Tag.ASSIGN) nameLocal(a.get(0));
      }
      for (var block : blocks) {
        print(locals.get(block));
        print(":\n");
        for (var a : block.instructions) {
          print(a, false);
          print('\n');
        }
      }
      print("}\n");
    }
  }

  public static byte[] compose(Module module) {
    return new LlvmComposer(module).stream.toByteArray();
  }

  private void args(Iterable<Term> terms) {
    print(' ');
    var more = false;
    for (var term : terms) {
      if (more) print(',');
      else {
        print(term.type());
        print(' ');
      }
      more = true;
      atom(term);
    }
  }

  private void atom(Term term) {
    switch (term.tag()) {
      case VARIABLE -> local(term);
      default -> print(term.toString());
    }
  }

  private void print(Instruction instruction) {
    switch (instruction) {
      case Assign assign -> {
        local(assign.variable);
        print('=');
        var value = assign.value;
        switch (value.tag()) {
          case SCAST -> {
            print(scast(value));
            print(' ');
            typeAtom(value.get(0));
            print(" to ");
            print(value.type());
          }
          case CAST -> {
            print(cast(value));
            print(' ');
            typeAtom(value.get(0));
            print(" to ");
            print(value.type());
          }
          case NE -> {
            print("icmp ne");
            args(value);
          }
          case SLT -> {
            print("icmp slt");
            args(value);
          }
          case FMUL -> {
            print("fmul");
            args(value);
          }
          case OR -> {
            print("or");
            args(value);
          }
          case ADDR -> {
            print('@');
            var variable = (GlobalVariable) value.get(0);
            id(variable.name);
          }
          case ARRAY -> {
            print('[');
            var more = false;
            for (var b : value) {
              if (more) print(',');
              more = true;
              typeAtom(b);
            }
            print(']');
          }
          case CALL -> {
            print("call ");
            var function = (Function) value.get(0);
            print(function.returnType);
            print(" @");
            id(function.name);
            print('(');
            for (var i = 1; i < value.size(); i++) {
              if (i > 1) print(',');
              typeAtom(value.get(i));
            }
            print(')');
          }
          case LOAD -> {
            print("load ");
            print(value.type());
            print(',');
            typeAtom(value.get(0));
          }
          case ELEMENT_PTR -> {
            print("getelementptr ptr,");
            typeAtom(value.get(0));
            print(',');
            typeAtom(value.get(1));
          }
          case ALLOCA -> {
            print("alloca ");
            print(value.type());
          }
          default -> throw new IllegalArgumentException(value.toString());
        }
      }
      case RetVoid _ -> print("ret void");
      case Ret ret -> {
        print("ret ");
        atom(ret.value);
      }
      case BrUnconditional brUnconditional -> {
        print("br ");
        local(brUnconditional.dest);
      }
      default -> throw new IllegalArgumentException(instruction.toString());
    }
    print('\n');
  }

  private void typeAtom(Term term) {
    print(term.type());
    print(' ');
    atom(term);
  }
}
