package olivine;

import java.util.*;

public abstract class Type implements Iterable<Type> {
  static final Type PTR =
      new Type() {
        @Override
        Kind kind() {
          return Kind.PTR;
        }

        @Override
        public String toString() {
          return "ptr";
        }
      };
  static final Type OPAQUE =
      new Type() {
        @Override
        Kind kind() {
          return Kind.OPAQUE;
        }

        @Override
        public String toString() {
          return "opaque";
        }
      };
  static final Type VOID =
      new Type() {
        @Override
        Kind kind() {
          return Kind.VOID;
        }

        @Override
        public String toString() {
          return "void";
        }
      };
  static final Type HALF =
      new Type() {
        @Override
        Kind kind() {
          return Kind.HALF;
        }

        @Override
        public String toString() {
          return "half";
        }
      };
  static final Type BFLOAT =
      new Type() {
        @Override
        Kind kind() {
          return Kind.BFLOAT;
        }

        @Override
        public String toString() {
          return "bfloat";
        }
      };
  static final Type FLOAT =
      new Type() {
        @Override
        Kind kind() {
          return Kind.FLOAT;
        }

        @Override
        public String toString() {
          return "float";
        }
      };
  static final Type DOUBLE =
      new Type() {
        @Override
        Kind kind() {
          return Kind.DOUBLE;
        }

        @Override
        public String toString() {
          return "double";
        }
      };
  static final Type FP128 =
      new Type() {
        @Override
        Kind kind() {
          return Kind.FP128;
        }

        @Override
        public String toString() {
          return "fp128";
        }
      };
  static final Type X86_FP80 =
      new Type() {
        @Override
        Kind kind() {
          return Kind.X86_FP80;
        }

        @Override
        public String toString() {
          return "x86_fp80";
        }
      };
  static final Type PPC_FP128 =
      new Type() {
        @Override
        Kind kind() {
          return Kind.PPC_FP128;
        }

        @Override
        public String toString() {
          return "ppc_fp128";
        }
      };
  static final Type BOOL =
      new Type() {
        @Override
        Kind kind() {
          return Kind.INT;
        }

        @Override
        int bits() {
          return 1;
        }

        @Override
        public String toString() {
          return "i1";
        }
      };
  static final Type I8 =
      new Type() {
        @Override
        Kind kind() {
          return Kind.INT;
        }

        @Override
        int bits() {
          return 8;
        }

        @Override
        public String toString() {
          return "i8";
        }
      };
  static final Type I16 =
      new Type() {
        @Override
        Kind kind() {
          return Kind.INT;
        }

        @Override
        int bits() {
          return 16;
        }

        @Override
        public String toString() {
          return "i16";
        }
      };
  static final Type I32 =
      new Type() {
        @Override
        Kind kind() {
          return Kind.INT;
        }

        @Override
        int bits() {
          return 32;
        }

        @Override
        public String toString() {
          return "i32";
        }
      };
  static final Type I64 =
      new Type() {
        @Override
        Kind kind() {
          return Kind.INT;
        }

        @Override
        int bits() {
          return 64;
        }

        @Override
        public String toString() {
          return "i64";
        }
      };
  static final Type I128 =
      new Type() {
        @Override
        Kind kind() {
          return Kind.INT;
        }

        @Override
        int bits() {
          return 128;
        }

        @Override
        public String toString() {
          return "i128";
        }
      };

  int bits() {
    throw new UnsupportedOperationException(toString());
  }

  public int size() {
    return 0;
  }

  @Override
  public Iterator<Type> iterator() {
    return new Iterator0();
  }

  abstract Kind kind();

  public Type get(int i) {
    throw new IndexOutOfBoundsException(toString());
  }

  public static Type struct(Type... v) {
    return new StructType(v);
  }

  private static class Iterator0 implements Iterator<Type> {
    @Override
    public boolean hasNext() {
      return false;
    }

    @Override
    public Type next() {
      throw new NoSuchElementException();
    }
  }

  private abstract static class Types extends Type {
    final Type[] v;

    Types(Type[] v) {
      this.v = v;
    }

    @Override
    public Type get(int i) {
      return v[i];
    }

    @Override
    public int size() {
      return v.length;
    }
  }

  private static final class StructType extends Types {
    StructType(Type[] v) {
      super(v);
    }

    @Override
    public boolean equals(Object o) {
      if (this == o) return true;
      if (o == null || getClass() != o.getClass()) return false;
      StructType types = (StructType) o;
      return Arrays.equals(v, types.v);
    }

    @Override
    public int hashCode() {
      return Arrays.hashCode(v);
    }

    @Override
    public String toString() {
      var sb = new StringBuilder();
      sb.append('{');
      var more = false;
      for (var type : v) {
        if (more) sb.append(',');
        more = true;
        sb.append(type);
      }
      sb.append('}');
      return sb.toString();
    }

    @Override
    public Kind kind() {
      return Kind.STRUCT;
    }
  }
}
