package olivine;

import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public final class LlvmParser {
  private static final int EOF = 128;
  private static final int LOCAL_ID = 129;
  private static final int GLOBAL_ID = 130;
  private static final int COMDAT_ID = 131;
  private static final int LABEL = 132;
  private static final int WORD = 133;
  private static final int INT = 134;
  private static final int STRING = 135;
  private static final int DOTS = 136;
  private static final int FLOAT = 137;
  private static final int HEX_FLOAT = 138;

  private final String file;
  private final byte[] text;
  private int ti;
  private int tok;
  private String tokString;
  private boolean newline;
  private final Map<String, Type> types = new HashMap<>();
  private final Map<String, Global> globals = new HashMap<>();
  private final Map<String, Term> locals = new HashMap<>();
  private final Map<Block, List<Term>> phis = new LinkedHashMap<>();

  public static String datalayout;
  public static String triple;

  public LlvmParser(String file, byte[] text) {
    this.file = file;
    this.text = text;
  }
}
