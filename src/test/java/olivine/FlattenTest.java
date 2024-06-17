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
    assertEquals(Tag.ADD, assign.value.tag());
  }
}
