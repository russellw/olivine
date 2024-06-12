package olivine;

import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;

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

  private void print(Term a) {
    // TODO: name?
    switch (a.tag()) {
      case SCAST -> {
        print(scast(a));
        print(' ');
        typeAtom(a.get(0));
        print(" to ");
        print(a.type());
      }
      case CAST -> {
        print(cast(a));
        print(' ');
        typeAtom(a.get(0));
        print(" to ");
        print(a.type());
      }
      case NE -> {
        print("icmp ne");
        args(a);
      }
      case SLT -> {
        print("icmp slt");
        args(a);
      }
      case FMUL -> {
        print("fmul");
        args(a);
      }
      case OR -> {
        print("or");
        args(a);
      }
      case ADDR -> {
        print('@');
        var variable = (GlobalVariable) a.get(0);
        id(variable.name);
      }
      case ARRAY -> {
        print('[');
        var more = false;
        for (var b : a) {
          if (more) print(',');
          more = true;
          typeAtom(b);
        }
        print(']');
      }
      case CALL -> {
        print("call ");
        var function = (Function) a.get(0);
        print(function.returnType);
        print(" @");
        id(function.name);
        print('(');
        for (var i = 1; i < a.size(); i++) {
          if (i > 1) print(',');
          typeAtom(a.get(i));
        }
        print(')');
      }
      case LOAD -> {
        print("load ");
        print(a.type());
        print(',');
        typeAtom(a.get(0));
      }
      case ELEMENT_PTR -> {
        print("getelementptr ptr,");
        typeAtom(a.get(0));
        print(',');
        typeAtom(a.get(1));
      }
      case ALLOCA -> {
        print("alloca ");
        print(a.type());
      }
      default -> throw new IllegalArgumentException(a.toString());
    }
  }

  private void print(Instruction instruction) {
    switch (instruction) {
      case Assign assign -> {
        local(assign.variable);
        print('=');
        print(assign.value);
      }
      case RetVoid _ -> print("ret void");
      case Ret ret -> {
        print("ret");
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
