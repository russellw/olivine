package olivine;

import static org.junit.jupiter.api.Assertions.*;

import java.util.List;
import org.junit.jupiter.api.Test;

class FlattenTest {
  private static Function fn(Type returnType, List<Variable> params) {
    var function = new Function("f");
    function.returnType = returnType;
    function.params.addAll(params);
    return function;
  }

  @Test
  void testFlat() {
    assertTrue(Flatten.flat(Term.TRUE));
    assertTrue(Flatten.flat(Term.ONE.add(Term.ONE)));
    assertFalse(Flatten.flat(Term.ONE.add(Term.ONE.add(Term.ONE))));
  }

  @Test
  void testFlatten() {
    var function = fn(Type.I32, List.of());
    var block = new Block();
    block.add(new Ret(Term.ONE.add(Term.ONE.add(Term.ONE))));
    function.entry = block;
    var module = new Module();
    module.functions.add(function);

    Flatten.run(module);

    assertEquals(2, block.size());
    var assign = (Assign) block.get(0);
    assertEquals(Type.I32, assign.variable.type());
    assertEquals(Tag.add, assign.value.tag());
  }

  @Test
  void testFlattenFieldPtr1() {
    // red, green, blue
    var colorType = Type.struct(Type.FLOAT, Type.FLOAT, Type.FLOAT);

    var color = new Variable(Type.PTR);
    var function = fn(Type.PTR, List.of(color));

    // &color->blue
    var pblue = color.fieldPtr(colorType, 2);

    var block = new Block();
    block.add(new Ret(pblue));
    function.entry = block;
    var module = new Module();
    module.functions.add(function);

    module.verify();
    Flatten.run(module);
    module.verify();

    assertEquals(1, block.size());
    var ret = (Ret) block.get(0);
    assertEquals(Type.PTR, ret.value.type());
    assertEquals(Tag.fieldPtr, ret.value.tag());
  }

  @Test
  void testFlattenFieldPtr2() {
    // red, green, blue
    var colorType = Type.struct(Type.FLOAT, Type.FLOAT, Type.FLOAT);

    // foreground, background
    var colorsType = Type.struct(colorType, colorType);

    var colors = new Variable(Type.PTR);
    var function = fn(Type.PTR, List.of(colors));

    // &colors->background.blue
    var pbackground = colors.fieldPtr(colorsType, 1);
    var pblue = pbackground.fieldPtr(colorType, 2);

    var block = new Block();
    block.add(new Ret(pblue));
    function.entry = block;
    var module = new Module();
    module.functions.add(function);

    module.verify();
    Flatten.run(module);
    module.verify();

    assertEquals(2, block.size());
    var assign = (Assign) block.get(0);
    assertEquals(Type.PTR, assign.variable.type());
    assertEquals(Tag.fieldPtr, assign.value.tag());
  }
}
