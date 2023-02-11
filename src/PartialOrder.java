enum PartialOrder {
  LT,
  EQ,
  GT,
  UNORDERED;

  static PartialOrder of(int c) {
    if (c < 0) return LT;
    if (c == 0) return EQ;
    return GT;
  }

  PartialOrder flip() {
    return switch (this) {
      case GT -> LT;
      case LT -> GT;
      default -> this;
    };
  }
}
