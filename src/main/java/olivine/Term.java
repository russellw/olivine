package olivine;

public class Term {
  static final Term NULL = new Term(Tag.NULL);

  private final Tag tag;

  private Term(Tag tag) {
    this.tag = tag;
  }

  Tag tag() {
    return tag;
  }
}
