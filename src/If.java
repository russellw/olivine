import java.util.List;

public final class If extends Term {
  final List<Term> yes, no;

  If(List<Term> yes, List<Term> no, Object a) {
    super(a);
    this.yes = yes;
    this.no = no;
  }
}
