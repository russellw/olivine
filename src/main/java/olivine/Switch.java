package olivine;

import java.util.ArrayList;
import java.util.List;

public final class Switch extends Instruction {
  Term value;
  Block defaultDest;
  List<Case> cases = new ArrayList<>();

  public Switch(Term value, Block defaultDest) {
    this.value = value;
    this.defaultDest = defaultDest;
  }
}