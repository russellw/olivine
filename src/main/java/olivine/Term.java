package olivine;

public abstract class Term {
  static final Term NULL = new Null();

  abstract Tag tag();

  private static final class Null extends Term {
    @Override
    Tag tag() {
      return Tag.NULL;
    }
  }

  private static final class IntegerConstant extends Term {
    @Override
    Tag tag() {
      return Tag.INTEGER;
    }
  }

  private static final class UnaryTerm extends Term {
    private final Tag tag;

    private UnaryTerm(Tag tag) {
      this.tag = tag;
    }

    @Override
    Tag tag() {
      return tag;
    }
  }
}
