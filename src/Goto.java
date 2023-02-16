import java.util.List;

public final class Goto extends Term {
  final List<Term> target;

  Goto(List<Term> target) {
    this.target = target;
  }
}
