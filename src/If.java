import java.util.List;

final class If extends Unary {
  final List<Term> yes, no;

  If(List<Term> yes, List<Term> no, Object a) {
    super(a);
    this.yes = yes;
    this.no = no;
  }
}
