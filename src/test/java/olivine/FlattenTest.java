package olivine;

import static org.junit.jupiter.api.Assertions.*;

import java.util.List;
import org.junit.jupiter.api.Test;

class FlattenTest {
  @Test
  void testFlat() {
    assertTrue(Flatten.flat(Term.TRUE));
    assertTrue(Flatten.flat(Term.ONE.add(Term.ONE)));
    assertFalse(Flatten.flat(Term.ONE.add(Term.ONE.add(Term.ONE))));
  }

  @Test
  void testFlatten() {
    var function = new Function("f", Type.I32, List.of(), false);
    var block = new Block();
    block.add(new Ret(Term.ONE.add(Term.ONE.add(Term.ONE))));
    function.entry = block;
    var module = new Module();
    module.functions.add(function);

    Flatten.run(module);

    assertEquals(2, block.size());
    var assign = (Assign) block.get(0);
    assertEquals(Type.I32, assign.variable.type());
    assertEquals(Tag.ADD, assign.value.tag());
  }

  @Test
  void testFlattenFieldPtr() {
    // red, green, blue
    var colorType = Type.struct(Type.FLOAT, Type.FLOAT, Type.FLOAT);

    // foreground, background
    var colorsType = Type.struct(colorType, colorType);

    var colors = new Variable(colorsType);
    var function = new Function("f", Type.FLOAT, List.of(colors), false);

    // colors->background->blue
    var background = colors.fieldPtr(colorsType, 1);
    var blue = background.fieldPtr(colorType, 2);

    var block = new Block();
    block.add(new Ret(blue));
    function.entry = block;
    var module = new Module();
    module.functions.add(function);

    Flatten.run(module);

    assertEquals(2, block.size());
    var assign = (Assign) block.get(0);
    assertEquals(Type.PTR, assign.variable.type());
    assertEquals(Tag.FIELD_PTR, assign.value.tag());
  }
}
