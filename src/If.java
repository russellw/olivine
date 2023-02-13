import java.util.List;

final class If extends Unary {
  final List<Term> yes, no;

  If(List<Term> yes, List<Term> no, Object arg) {
    super(arg);
    this.yes = yes;
    this.no = no;
  }
}
