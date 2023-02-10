import java.util.List;

final class If extends Unary {
  final List<Instruction> yes, no;

  If(List<Instruction> yes, List<Instruction> no, Object arg) {
    super(arg);
    this.yes = yes;
    this.no = no;
  }
}
