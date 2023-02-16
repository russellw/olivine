import java.util.*;

public class CdclTest {
  private record Assignment(Object atom, boolean value, Clause reason) {
    public String toString() {
      return atom.toString();
    }
  }

  private static final List<Assignment> trail = new ArrayList<>();

  private static Assignment assignment(Object a) {
    for (var assignment : trail) if (assignment.atom == a) return assignment;
    throw new IllegalStateException(a.toString());
  }

  private static Graph<Assignment> implicationGraph() {
    var graph = new Graph<Assignment>();
    for (var assignment : trail) {
      var c = assignment.reason;
      if (c != null)
        for (var a : c.literals) if (a != assignment.atom) graph.add(assignment(a), assignment);
    }
    return graph;
  }

  private static void assertSuccessors(Graph<Assignment> graph, Object x, Object... ys) {
    var zs = new HashSet<>();
    for (var assignment : graph.successors(assignment(x))) zs.add(assignment.atom);
    assert Set.of(ys).equals(zs);
  }

  public static void main(String[] args) {
    // https://users.aalto.fi/~tjunttil/2020-DP-AUT/notes-sat/cdcl.html
    var x1 = new Fn(BooleanType.instance, "x1");
    var x2 = new Fn(BooleanType.instance, "x2");
    var x3 = new Fn(BooleanType.instance, "x3");
    var x4 = new Fn(BooleanType.instance, "x4");
    var x5 = new Fn(BooleanType.instance, "x5");
    var x6 = new Fn(BooleanType.instance, "x6");
    var x7 = new Fn(BooleanType.instance, "x7");
    var x8 = new Fn(BooleanType.instance, "x8");
    var x9 = new Fn(BooleanType.instance, "x9");
    var x10 = new Fn(BooleanType.instance, "x10");
    var x11 = new Fn(BooleanType.instance, "x11");
    var x12 = new Fn(BooleanType.instance, "x12");

    var negative = new ArrayList<>();
    var positive = new ArrayList<>();
    negative.add(x1);
    negative.add(x2);
    var c_1_2 = new Clause(negative, positive);

    negative.clear();
    positive.clear();
    negative.add(x1);
    positive.add(x3);
    var c_1_3 = new Clause(negative, positive);

    negative.clear();
    positive.clear();
    negative.add(x3);
    negative.add(x4);
    var c_3_4 = new Clause(negative, positive);

    negative.clear();
    positive.clear();
    positive.add(x2);
    positive.add(x4);
    positive.add(x5);
    var c_2_4_5 = new Clause(negative, positive);

    negative.clear();
    positive.clear();
    negative.add(x5);
    positive.add(x6);
    negative.add(x7);
    var c_5_6_7 = new Clause(negative, positive);

    negative.clear();
    positive.clear();
    positive.add(x2);
    positive.add(x7);
    positive.add(x8);
    var c_2_7_8 = new Clause(negative, positive);

    negative.clear();
    positive.clear();
    negative.add(x8);
    negative.add(x9);
    var c_8_9 = new Clause(negative, positive);

    negative.clear();
    positive.clear();
    negative.add(x8);
    positive.add(x10);
    var c_8_10 = new Clause(negative, positive);

    negative.clear();
    positive.clear();
    positive.add(x9);
    negative.add(x10);
    positive.add(x11);
    var c_9_10_11 = new Clause(negative, positive);

    negative.clear();
    positive.clear();
    negative.add(x10);
    negative.add(x12);
    var c_10_12 = new Clause(negative, positive);

    negative.clear();
    positive.clear();
    negative.add(x11);
    positive.add(x12);
    var c_11_12 = new Clause(negative, positive);

    trail.add(new Assignment(x1, true, null));
    trail.add(new Assignment(x2, false, c_1_2));
    trail.add(new Assignment(x3, true, c_1_3));
    trail.add(new Assignment(x4, false, c_3_4));
    trail.add(new Assignment(x5, true, c_2_4_5));

    var graph = implicationGraph();
    assertSuccessors(graph, x1, x2, x3);
    assertSuccessors(graph, x2, x5);
    assertSuccessors(graph, x3, x4);
    assertSuccessors(graph, x4, x5);
    assertSuccessors(graph, x5);

    trail.add(new Assignment(x6, false, null));
    trail.add(new Assignment(x7, false, c_5_6_7));
    trail.add(new Assignment(x8, true, c_2_7_8));
    trail.add(new Assignment(x9, false, c_8_9));
    trail.add(new Assignment(x10, true, c_8_10));
    trail.add(new Assignment(x11, true, c_9_10_11));
    trail.add(new Assignment(x12, false, c_10_12));

    graph = implicationGraph();
    assertSuccessors(graph, x6, x7);
    assertSuccessors(graph, x7, x8);
    assertSuccessors(graph, x8, x9, x10);
    assertSuccessors(graph, x9, x11);
    assertSuccessors(graph, x10, x11, x12);
  }
}
