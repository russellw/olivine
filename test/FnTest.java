import java.math.BigInteger;
import java.util.ArrayList;

public class FnTest {
  public static void main(String[] args) {
    var f = new Fn(null, "f");
    f.initBlocks();
    var block = f.blocks.get(0);

    block.add(new Return(10));
    assert f.interpret(new Object[0]).equals(10);

    block.clear();
    Term a = new Add(10, 20);
    block.add(a);
    block.add(new Return(a));
    assert f.interpret(new Object[0]).equals(30);

    // square
    var x = new Variable(null);
    var square = new Fn(null, "square", x);
    square.initBlocks();
    block = square.blocks.get(0);

    a = new Mul(x, x);
    block.add(a);
    block.add(new Return(a));

    assert square.interpret(new Object[] {3}).equals(9);
    assert square.interpret(new Object[] {BigInteger.valueOf(20)}).equals(BigInteger.valueOf(400));

    // invoke square
    block = f.blocks.get(0);
    block.clear();
    a = new Call(square, 5);
    block.add(a);
    block.add(new Return(a));
    assert f.interpret(new Object[0]).equals(25);

    // goto
    block = f.blocks.get(0);
    block.clear();

    var block1 = new ArrayList<Term>();
    f.blocks.add(block1);

    block.add(new Goto(block1));

    a = new Call(square, 7);
    block1.add(a);
    block1.add(new Return(a));
    assert f.interpret(new Object[0]).equals(49);

    // store
    block.clear();
    var r = new Variable(null);
    a = new Store(r, 123);
    block.add(a);
    block.add(new Return(r));
    assert f.interpret(new Object[0]).equals(123);
  }
}
