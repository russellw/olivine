package olivine;

import java.util.ArrayList;
import java.util.List;

public final class Switch extends Instruction {
  public List<Case> cases = new ArrayList<>();
  public Block defaultDest;
  public Term value;

  public Switch(Term value, Block defaultDest) {
    this.value = value;
    this.defaultDest = defaultDest;
  }
}
