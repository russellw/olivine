@SuppressWarnings("ClassCanBeRecord")
public final class DistinctObject {
  final String name;

  public String toString() {
    return name;
  }

  DistinctObject(String name) {
    assert name != null;
    this.name = name;
  }
}
