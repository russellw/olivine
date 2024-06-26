package olivine;

import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.util.*;

public final class LlvmComposer {
  private final Map<Object, String> locals = new HashMap<>();
  private List<Variable> params;
  private final ByteArrayOutputStream stream = new ByteArrayOutputStream();

  private LlvmComposer(Module module) {
    // Global variables
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

    // Functions
    for (var function : module.functions) {
      locals.clear();
      params = function.params;

      // Declaration
      print('\n');
      print(function.entry == null ? "declare " : "define ");
      print(function.returnType);
      print(" @");
      id(function.name);

      // Parameters
      print('(');
      var more = false;
      for (var a : function.params) {
        if (more) print(',');
        more = true;
        typeAtom(a);
      }
      if (function.varargs) print(",...");
      print(')');

      // End of declaration
      if (function.entry != null) print('{');
      print('\n');

      // Empty function is only declared, not defined
      if (function.entry == null) continue;

      // Local variables
      var blocks = function.blocks();
      var assigned = new LinkedHashSet<Variable>();
      for (var block : blocks)
        for (var instruction : block)
          if (instruction instanceof Assign assign) assigned.add(assign.variable);

      // Must be converted to alloca
      locals.put(new Variable(Type.I32), null);
      for (var variable : assigned) {
        print('%');
        local(variable);
        print("=alloca ");
        print(variable.type());
        print('\n');
      }
      print("br label %");
      local(function.entry);
      print('\n');

      // Print body
      for (var block : blocks) {
        local(block);
        print(":\n");
        for (var instruction : block) {
          print(instruction);
        }
      }
      print("}\n");
    }
  }

  private void args(Term[] terms) {
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
      case ADDR -> atom(term.get(0));
      case GLOBAL_VARIABLE -> {
        print('@');
        id(term.toString());
      }
      case NULL -> print("null");
      case VARIABLE -> {
        print('%');
        local(term);
      }
      default -> print(term.toString());
    }
  }

  private void call(Term call) {
    assert call.tag() == Tag.CALL;
    print("call ");
    var function = (Function) call.get(0);
    print(function.returnType);
    print(" @");
    id(function.name);
    print('(');
    for (var i = 1; i < call.size(); i++) {
      if (i > 1) print(',');
      typeAtom(call.get(i));
    }
    print(')');
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

  public static byte[] compose(Module module) {
    return new LlvmComposer(module).stream.toByteArray();
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

  private Term load(Term term) {
    var args = new Term[term.size()];
    for (var i = 0; i < args.length; i++) args[i] = load(term.get(i));
    Term ssa;
    switch (term.tag()) {
      case ADD -> {
        ssa = ssa(term);
        print("add");
        args(args);
      }
      case ALLOCA -> {
        ssa = ssa(term);
        print("alloca ");
        print(term.type());
      }
      case ARRAY -> {
        ssa = ssa(term);
        print('[');
        var more = false;
        for (var element : args) {
          if (more) print(',');
          more = true;
          typeAtom(element);
        }
        print(']');
      }
      case CALL -> {
        ssa = ssa(term);
        call(term);
      }
      case CAST -> {
        ssa = ssa(term);
        print(cast(term));
        print(' ');
        typeAtom(args[0]);
        print(" to ");
        print(term.type());
      }
      case ELEMENT_PTR -> {
        ssa = ssa(term);
        print("getelementptr ptr,");
        typeAtom(args[0]);
        print(',');
        typeAtom(args[1]);
      }
      case EQ -> {
        ssa = ssa(term);
        print("icmp eq");
        args(args);
      }
      case FIELD_PTR -> {
        ssa = ssa(term);
        print("getelementptr ");
        print(term.struct());
        print(',');
        typeAtom(args[0]);
        print(",i32 0,i32 ");
        print(Integer.toString(term.intValueExact()));
      }
      case FMUL -> {
        ssa = ssa(term);
        print("fmul");
        args(args);
      }
      case GLOBAL_VARIABLE, VARIABLE -> {
        //noinspection SuspiciousMethodCalls
        if (params.contains(term)) return term;
        ssa = ssa(term);
        print("load ");
        print(term.type());
        print(",ptr ");
        atom(term);
      }
      case LOAD -> {
        ssa = ssa(term);
        print("load ");
        print(term.type());
        print(',');
        typeAtom(args[0]);
      }
      case MUL -> {
        ssa = ssa(term);
        print("mul");
        args(args);
      }
      case NE -> {
        ssa = ssa(term);
        print("icmp ne");
        args(args);
      }
      case OR -> {
        ssa = ssa(term);
        print("or");
        args(args);
      }
      case SCAST -> {
        ssa = ssa(term);
        print(scast(term));
        print(' ');
        typeAtom(args[0]);
        print(" to ");
        print(term.type());
      }
      case SLT -> {
        ssa = ssa(term);
        print("icmp slt");
        args(args);
      }
      default -> {
        return term;
      }
    }
    print("; ");
    print(term.toString());
    print('\n');
    return ssa;
  }

  private void local(Object o) {
    var s = locals.get(o);
    if (s == null) {
      s = Integer.toString(locals.size());
      locals.put(o, s);
    }
    print(s);
  }

  private void print(Instruction instruction) {
    switch (instruction) {
      case Assign assign -> {
        var value = load(assign.value);
        print("store ");
        typeAtom(value);
        print(",ptr %");
        local(assign.variable);
        print("; Assign");
      }
      case Br br -> {
        var cond = load(br.cond);
        print("br i1 ");
        atom(cond);
        print(",label %");
        local(br.ifTrue);
        print(",label %");
        local(br.ifFalse);
      }
      case BrUnconditional brUnconditional -> {
        print("br %");
        local(brUnconditional.dest);
      }
      case Ret ret -> {
        var value = load(ret.value);
        print("ret ");
        typeAtom(value);
      }
      case RetVoid _ -> print("ret void");
      case Store store -> {
        var value = load(store.value);
        var pointer = load(store.pointer);
        print("store ");
        typeAtom(value);
        print(',');
        typeAtom(pointer);
        print("; Store");
      }
      case VoidCall voidCall -> call(voidCall.call);
      default -> throw new IllegalArgumentException(instruction.toString());
    }
    print('\n');
  }

  private void print(String s) {
    stream.writeBytes(s.getBytes(StandardCharsets.UTF_8));
  }

  private void print(Type type) {
    print(type.toString());
  }

  private void print(int c) {
    stream.write(c);
  }

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

  private Term ssa(Term term) {
    print('%');
    var variable = new Variable(term.type());
    local(variable);
    print('=');
    return variable;
  }

  private void typeAtom(Term term) {
    print(term.type());
    print(' ');
    atom(term);
  }
}
