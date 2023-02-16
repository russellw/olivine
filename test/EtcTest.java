import java.math.BigInteger;
import java.util.ArrayList;
import java.util.List;

public class EtcTest {
  public static void main(String[] args) {
    assert Etc.divEuclidean(BigInteger.valueOf(0), BigInteger.valueOf(1))
        .equals(BigInteger.valueOf(0));
    assert Etc.divEuclidean(BigInteger.valueOf(0), BigInteger.valueOf(10))
        .equals(BigInteger.valueOf(0));
    assert Etc.divEuclidean(BigInteger.valueOf(0), BigInteger.valueOf(-1))
        .equals(BigInteger.valueOf(0));
    assert Etc.divEuclidean(BigInteger.valueOf(0), BigInteger.valueOf(-10))
        .equals(BigInteger.valueOf(0));

    assert Etc.divEuclidean(BigInteger.valueOf(1), BigInteger.valueOf(1))
        .equals(BigInteger.valueOf(1));
    assert Etc.divEuclidean(BigInteger.valueOf(10), BigInteger.valueOf(10))
        .equals(BigInteger.valueOf(1));
    assert Etc.divEuclidean(BigInteger.valueOf(-1), BigInteger.valueOf(1))
        .equals(BigInteger.valueOf(-1));
    assert Etc.divEuclidean(BigInteger.valueOf(-10), BigInteger.valueOf(10))
        .equals(BigInteger.valueOf(-1));
    assert Etc.divEuclidean(BigInteger.valueOf(1), BigInteger.valueOf(-1))
        .equals(BigInteger.valueOf(-1));
    assert Etc.divEuclidean(BigInteger.valueOf(10), BigInteger.valueOf(-10))
        .equals(BigInteger.valueOf(-1));
    assert Etc.divEuclidean(BigInteger.valueOf(-1), BigInteger.valueOf(-1))
        .equals(BigInteger.valueOf(1));
    assert Etc.divEuclidean(BigInteger.valueOf(-10), BigInteger.valueOf(-10))
        .equals(BigInteger.valueOf(1));

    assert Etc.divEuclidean(BigInteger.valueOf(7), BigInteger.valueOf(3))
        .equals(BigInteger.valueOf(2));
    assert Etc.divEuclidean(BigInteger.valueOf(7), BigInteger.valueOf(-3))
        .equals(BigInteger.valueOf(-2));
    assert Etc.divEuclidean(BigInteger.valueOf(-7), BigInteger.valueOf(3))
        .equals(BigInteger.valueOf(-3));
    assert Etc.divEuclidean(BigInteger.valueOf(-7), BigInteger.valueOf(-3))
        .equals(BigInteger.valueOf(3));

    assert Etc.remEuclidean(BigInteger.valueOf(1), BigInteger.valueOf(1))
        .equals(BigInteger.valueOf(0));
    assert Etc.remEuclidean(BigInteger.valueOf(10), BigInteger.valueOf(10))
        .equals(BigInteger.valueOf(0));

    assert Etc.remEuclidean(BigInteger.valueOf(7), BigInteger.valueOf(3))
        .equals(BigInteger.valueOf(1));
    assert Etc.remEuclidean(BigInteger.valueOf(7), BigInteger.valueOf(-3))
        .equals(BigInteger.valueOf(1));
    assert Etc.remEuclidean(BigInteger.valueOf(-7), BigInteger.valueOf(3))
        .equals(BigInteger.valueOf(2));
    assert Etc.remEuclidean(BigInteger.valueOf(-7), BigInteger.valueOf(-3))
        .equals(BigInteger.valueOf(2));

    assert Etc.divFloor(BigInteger.valueOf(0), BigInteger.valueOf(1)).equals(BigInteger.valueOf(0));
    assert Etc.divFloor(BigInteger.valueOf(0), BigInteger.valueOf(10))
        .equals(BigInteger.valueOf(0));
    assert Etc.divFloor(BigInteger.valueOf(0), BigInteger.valueOf(-1))
        .equals(BigInteger.valueOf(0));
    assert Etc.divFloor(BigInteger.valueOf(0), BigInteger.valueOf(-10))
        .equals(BigInteger.valueOf(0));

    assert Etc.divFloor(BigInteger.valueOf(1), BigInteger.valueOf(1)).equals(BigInteger.valueOf(1));
    assert Etc.divFloor(BigInteger.valueOf(10), BigInteger.valueOf(10))
        .equals(BigInteger.valueOf(1));
    assert Etc.divFloor(BigInteger.valueOf(-1), BigInteger.valueOf(1))
        .equals(BigInteger.valueOf(-1));
    assert Etc.divFloor(BigInteger.valueOf(-10), BigInteger.valueOf(10))
        .equals(BigInteger.valueOf(-1));
    assert Etc.divFloor(BigInteger.valueOf(1), BigInteger.valueOf(-1))
        .equals(BigInteger.valueOf(-1));
    assert Etc.divFloor(BigInteger.valueOf(10), BigInteger.valueOf(-10))
        .equals(BigInteger.valueOf(-1));
    assert Etc.divFloor(BigInteger.valueOf(-1), BigInteger.valueOf(-1))
        .equals(BigInteger.valueOf(1));
    assert Etc.divFloor(BigInteger.valueOf(-10), BigInteger.valueOf(-10))
        .equals(BigInteger.valueOf(1));

    // Compare with expected values
    assert Etc.divFloor(BigInteger.valueOf(5), BigInteger.valueOf(3)).equals(BigInteger.valueOf(1));
    assert Etc.divFloor(BigInteger.valueOf(5), BigInteger.valueOf(-3))
        .equals(BigInteger.valueOf(-2));
    assert Etc.divFloor(BigInteger.valueOf(-5), BigInteger.valueOf(3))
        .equals(BigInteger.valueOf(-2));
    assert Etc.divFloor(BigInteger.valueOf(-5), BigInteger.valueOf(-3))
        .equals(BigInteger.valueOf(1));

    // Compare with standard library int function
    assert Etc.divFloor(BigInteger.valueOf(5), BigInteger.valueOf(3))
        .equals(BigInteger.valueOf(Math.floorDiv(5, 3)));
    assert Etc.divFloor(BigInteger.valueOf(5), BigInteger.valueOf(-3))
        .equals(BigInteger.valueOf(Math.floorDiv(5, -3)));
    assert Etc.divFloor(BigInteger.valueOf(-5), BigInteger.valueOf(3))
        .equals(BigInteger.valueOf(Math.floorDiv(-5, 3)));
    assert Etc.divFloor(BigInteger.valueOf(-5), BigInteger.valueOf(-3))
        .equals(BigInteger.valueOf(Math.floorDiv(-5, -3)));

    assert Etc.remFloor(BigInteger.valueOf(1), BigInteger.valueOf(1)).equals(BigInteger.valueOf(0));
    assert Etc.remFloor(BigInteger.valueOf(10), BigInteger.valueOf(10))
        .equals(BigInteger.valueOf(0));

    // Compare with expected values
    assert Etc.remFloor(BigInteger.valueOf(5), BigInteger.valueOf(3)).equals(BigInteger.valueOf(2));
    assert Etc.remFloor(BigInteger.valueOf(5), BigInteger.valueOf(-3))
        .equals(BigInteger.valueOf(-1));
    assert Etc.remFloor(BigInteger.valueOf(-5), BigInteger.valueOf(3))
        .equals(BigInteger.valueOf(1));
    assert Etc.remFloor(BigInteger.valueOf(-5), BigInteger.valueOf(-3))
        .equals(BigInteger.valueOf(-2));

    // Compare with standard library int function
    assert Etc.remFloor(BigInteger.valueOf(5), BigInteger.valueOf(3))
        .equals(BigInteger.valueOf(Math.floorMod(5, 3)));
    assert Etc.remFloor(BigInteger.valueOf(5), BigInteger.valueOf(-3))
        .equals(BigInteger.valueOf(Math.floorMod(5, -3)));
    assert Etc.remFloor(BigInteger.valueOf(-5), BigInteger.valueOf(3))
        .equals(BigInteger.valueOf(Math.floorMod(-5, 3)));
    assert Etc.remFloor(BigInteger.valueOf(-5), BigInteger.valueOf(-3))
        .equals(BigInteger.valueOf(Math.floorMod(-5, -3)));

    // arrays
    var v = new Object[] {10, 20, 30};
    var r = Etc.remove(v, 1);
    assert r.length == 2;
    assert r[0].equals(10);
    assert r[1].equals(30);

    // cartesian product
    List<List<String>> qs = new ArrayList<>();
    List<String> q;
    q = new ArrayList<>();
    q.add("a0");
    q.add("a1");
    qs.add(q);
    q = new ArrayList<>();
    q.add("b0");
    q.add("b1");
    q.add("b2");
    qs.add(q);
    q = new ArrayList<>();
    q.add("c0");
    q.add("c1");
    q.add("c2");
    q.add("c3");
    qs.add(q);
    var rs = Etc.cartesianProduct(qs);
    var i = 0;
    assert rs.get(i++).equals(List.of("a0", "b0", "c0"));
    assert rs.get(i++).equals(List.of("a0", "b0", "c1"));
    assert rs.get(i++).equals(List.of("a0", "b0", "c2"));
    assert rs.get(i++).equals(List.of("a0", "b0", "c3"));
    assert rs.get(i++).equals(List.of("a0", "b1", "c0"));
    assert rs.get(i++).equals(List.of("a0", "b1", "c1"));
    assert rs.get(i++).equals(List.of("a0", "b1", "c2"));
    assert rs.get(i++).equals(List.of("a0", "b1", "c3"));
    assert rs.get(i++).equals(List.of("a0", "b2", "c0"));
    assert rs.get(i++).equals(List.of("a0", "b2", "c1"));
    assert rs.get(i++).equals(List.of("a0", "b2", "c2"));
    assert rs.get(i++).equals(List.of("a0", "b2", "c3"));
    assert rs.get(i++).equals(List.of("a1", "b0", "c0"));
    assert rs.get(i++).equals(List.of("a1", "b0", "c1"));
    assert rs.get(i++).equals(List.of("a1", "b0", "c2"));
    assert rs.get(i++).equals(List.of("a1", "b0", "c3"));
    assert rs.get(i++).equals(List.of("a1", "b1", "c0"));
    assert rs.get(i++).equals(List.of("a1", "b1", "c1"));
    assert rs.get(i++).equals(List.of("a1", "b1", "c2"));
    assert rs.get(i++).equals(List.of("a1", "b1", "c3"));
    assert rs.get(i++).equals(List.of("a1", "b2", "c0"));
    assert rs.get(i++).equals(List.of("a1", "b2", "c1"));
    assert rs.get(i++).equals(List.of("a1", "b2", "c2"));
    assert rs.get(i).equals(List.of("a1", "b2", "c3"));
  }
}
