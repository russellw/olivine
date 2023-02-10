import java.util.List;

final class Goto extends Instruction {
  final List<Instruction> target;

  Goto(List<Instruction> target) {
    this.target = target;
  }
}
