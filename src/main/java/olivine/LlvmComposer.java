package olivine;

import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.util.*;

public final class LlvmComposer {
  private final Map<Object, String> locals = new HashMap<>();
  private List<Variable> params;
  private final ByteArrayOutputStream stream = new ByteArrayOutputStream();

  private LlvmComposer(Module module) {
    // Target
    if (LlvmParser.triple != null) {
      print("target triple=\"");
      print(LlvmParser.triple);
      print("\"\n");
    }

    // Comdats
    var comdats = new LinkedHashSet<String>();
    for (var variable : module.variables) if (variable.comdat) comdats.add(variable.name);
    for (var function : module.functions) if (function.comdat) comdats.add(function.name);
    for (var s : comdats) {
      print('$');
      id(s);
      print("=comdat any\n");
    }

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
        expr(variable.value);
      }
      if (variable.comdat) print(",comdat");
      print('\n');
    }

    // Functions
    for (var function : module.functions) {
      locals.clear();
      params = function.params;

      // Declaration
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
        typeExpr(a);
      }
      if (function.varargs) print(",...");
      print(')');

      // End of declaration
      if (function.comdat) print("comdat");
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
        for (var instruction : block) print(instruction);
      }
      print("}\n");
    }
  }

  private void call(Term call, Term[] args) {
    print("call ");

    // Function
    var function = (Function) call.get(0);
    print(function.returnType);
    print('(');
    var more = false;
    for (var param : function.params) {
      if (more) print(',');
      more = true;
      print(param.type());
    }
    if (function.varargs) print(",...");
    print(")@");
    id(function.name);

    // Args
    print('(');
    more = false;
    for (var arg : args) {
      if (more) print(',');
      more = true;
      typeExpr(arg);
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

  private void expr(Term term) {
    switch (term.tag()) {
      case addr -> expr(term.get(0));
      case elementPtr -> {
        print("getelementptr(");
        print(term.targetType());
        print(',');
        typeExpr(term.get(0));
        print(',');
        typeExpr(term.get(1));
        print(')');
      }
      case globalVariable -> {
        print('@');
        id(term.toString());
      }
      case nullConstant -> print("null");
      case undef -> print("undef");
      case variable -> {
        print('%');
        local(term);
      }
      default -> print(term.toString());
    }
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
    Term ssa;
    switch (term.tag()) {
      case add, and, ashr, fadd, fdiv, fmul, fsub, lshr, mul, or, sub, udiv, urem, xor -> {
        var a = load(term.get(0));
        var b = load(term.get(1));
        ssa = ssa(term);
        printSpace(term.tag());
        typeExpr(a);
        print(',');
        expr(b);
      }
      case alloca -> {
        ssa = ssa(term);
        printSpace(term.tag());
        print(term.type());
      }
      case array -> {
        var elements = new Term[term.size()];
        for (var i = 0; i < elements.length; i++) elements[i] = load(term.get(i));
        ssa = ssa(term);
        print('[');
        var more = false;
        for (var element : elements) {
          if (more) print(',');
          more = true;
          typeExpr(element);
        }
        print(']');
      }
      case call -> {
        var args = new Term[term.size() - 1];
        for (var i = 0; i < args.length; i++) args[i] = load(term.get(1 + i));
        ssa = ssa(term);
        call(term, args);
      }
      case cast -> {
        var a = load(term.get(0));
        ssa = ssa(term);
        print(cast(term));
        print(' ');
        typeExpr(a);
        print(" to ");
        print(term.type());
      }
      case elementPtr -> {
        var a = load(term.get(0));
        var b = load(term.get(1));
        ssa = ssa(term);
        print("getelementptr ptr,");
        typeExpr(a);
        print(',');
        typeExpr(b);
      }
      case eq -> {
        var a = load(term.get(0));
        var b = load(term.get(1));
        ssa = ssa(term);
        print("icmp eq ");
        typeExpr(a);
        print(',');
        expr(b);
      }
      case feq -> {
        var a = load(term.get(0));
        var b = load(term.get(1));
        ssa = ssa(term);
        print("fcmp oeq ");
        typeExpr(a);
        print(',');
        expr(b);
      }
      case fieldPtr -> {
        var a = load(term.get(0));
        ssa = ssa(term);
        print("getelementptr ");
        print(term.targetType());
        print(',');
        typeExpr(a);
        print(",i32 0,i32 ");
        print(Integer.toString(term.intValueExact()));
      }
      case fle -> {
        var a = load(term.get(0));
        var b = load(term.get(1));
        ssa = ssa(term);
        print("fcmp ole ");
        typeExpr(a);
        print(',');
        expr(b);
      }
      case flt -> {
        var a = load(term.get(0));
        var b = load(term.get(1));
        ssa = ssa(term);
        print("fcmp olt ");
        typeExpr(a);
        print(',');
        expr(b);
      }
      case fne -> {
        var a = load(term.get(0));
        var b = load(term.get(1));
        ssa = ssa(term);
        print("fcmp une ");
        typeExpr(a);
        print(',');
        expr(b);
      }
      case fneg -> {
        var a = load(term.get(0));
        ssa = ssa(term);
        printSpace(term.tag());
        typeExpr(a);
      }
      case globalVariable, variable -> {
        //noinspection SuspiciousMethodCalls
        if (params.contains(term)) return term;
        ssa = ssa(term);
        print("load ");
        print(term.type());
        print(",ptr ");
        expr(term);
      }
      case load -> {
        var a = load(term.get(0));
        ssa = ssa(term);
        printSpace(term.tag());
        print(term.type());
        print(',');
        typeExpr(a);
      }
      case ne -> {
        var a = load(term.get(0));
        var b = load(term.get(1));
        ssa = ssa(term);
        print("icmp ne ");
        typeExpr(a);
        print(',');
        expr(b);
      }
      case scast -> {
        var a = load(term.get(0));
        ssa = ssa(term);
        print(scast(term));
        print(' ');
        typeExpr(a);
        print(" to ");
        print(term.type());
      }
      case select -> {
        var cond = load(term.get(0));
        var ifTrue = load(term.get(1));
        var ifFalse = load(term.get(2));
        ssa = ssa(term);
        printSpace(term.tag());
        typeExpr(cond);
        print(',');
        typeExpr(ifTrue);
        print(',');
        typeExpr(ifFalse);
      }
      case slt -> {
        var a = load(term.get(0));
        var b = load(term.get(1));
        ssa = ssa(term);
        print("icmp slt ");
        typeExpr(a);
        print(',');
        expr(b);
      }
      case ult -> {
        var a = load(term.get(0));
        var b = load(term.get(1));
        ssa = ssa(term);
        print("icmp ult ");
        typeExpr(a);
        print(',');
        expr(b);
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
      s = Integer.toHexString(locals.size());
      locals.put(o, s);
    }
    print('_');
    print(s);
  }

  private void print(Instruction instruction) {
    switch (instruction) {
      case Assign assign -> {
        var value = load(assign.value);
        print("store ");
        typeExpr(value);
        print(",ptr %");
        local(assign.variable);
        print("; Assign");
      }
      case Br br -> {
        var cond = load(br.cond);
        print("br i1 ");
        expr(cond);
        print(",label %");
        local(br.ifTrue);
        print(",label %");
        local(br.ifFalse);
      }
      case BrUnconditional brUnconditional -> {
        print("br label %");
        local(brUnconditional.dest);
      }
      case Ret ret -> {
        var value = load(ret.value);
        print("ret ");
        typeExpr(value);
      }
      case RetVoid _ -> print("ret void");
      case Store store -> {
        var value = load(store.value);
        var pointer = load(store.pointer);
        print("store ");
        typeExpr(value);
        print(',');
        typeExpr(pointer);
        print("; Store");
      }
      case Unreachable _ -> print("unreachable");
      case VoidCall voidCall -> {
        var call = voidCall.call;
        var args = new Term[call.size() - 1];
        for (var i = 0; i < args.length; i++) args[i] = load(call.get(1 + i));
        call(call, args);
      }
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

  private void printSpace(Tag tag) {
    print(tag.toString());
    print(' ');
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

  private void typeExpr(Term term) {
    print(term.type());
    print(' ');
    expr(term);
  }
}
