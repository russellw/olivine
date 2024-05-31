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
  static final Type I1 =
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

  public static Type struct(Type... fields) {
    return new StructType(fields);
  }

  public static Type struct(List<Type> fields) {
    return new StructType(fields.toArray(new Type[0]));
  }

  private static class Iterator0 implements Iterator<Type> {
    @Override
    public boolean hasNext() {
      return false;
    }

    @Override
    public Type next() {
      throw new UnsupportedOperationException();
    }
  }

  private abstract static class SequentialType extends Type {
    private final int count;
    private final Type element;

    private SequentialType(int count, Type element) {
      this.count = count;
      this.element = element;
    }

    @Override
    public boolean equals(Object o) {
      if (this == o) return true;
      if (o == null || getClass() != o.getClass()) return false;
      SequentialType types = (SequentialType) o;
      return count == types.count && Objects.equals(element, types.element);
    }

    @Override
    public int hashCode() {
      return Objects.hash(count, element);
    }

    @Override
    public Type get(int i) {
      if (i != 0) throw new IndexOutOfBoundsException("%s, %s".formatted(this, i));
      return element;
    }

    @Override
    public int size() {
      return 1;
    }
  }

  private abstract static class Types extends Type {
    final Type[] types;

    Types(Type[] types) {
      this.types = types;
    }

    @Override
    public Type get(int i) {
      return types[i];
    }

    @Override
    public int size() {
      return types.length;
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
      return Arrays.equals(this.types, types.types);
    }

    @Override
    public int hashCode() {
      return Arrays.hashCode(types);
    }

    @Override
    public String toString() {
      var sb = new StringBuilder();
      sb.append('{');
      var more = false;
      for (var type : types) {
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

  public static Type fn(Type rtype, List<Type> params, boolean varargs) {
    var v = new Type[1 + params.size()];
    v[0] = rtype;
    for (var i = 0; i < params.size(); i++) v[1 + i] = params.get(i);
    return new FnType(v, varargs);
  }

  public static Type fn(Type[] v, boolean varargs) {
    return new FnType(v, varargs);
  }

  private static final class FnType extends Types {
    final boolean varargs;

    FnType(Type[] v, boolean varargs) {
      super(v);
      this.varargs = varargs;
    }

    @Override
    public boolean equals(Object o) {
      if (this == o) return true;
      if (o == null || getClass() != o.getClass()) return false;
      FnType types = (FnType) o;
      return varargs == types.varargs && Arrays.equals(this.types, types.types);
    }

    @Override
    public int hashCode() {
      int result = Objects.hash(varargs);
      result = 31 * result + Arrays.hashCode(types);
      return result;
    }

    @Override
    public String toString() {
      var sb = new StringBuilder();
      sb.append(types[0]);
      sb.append(" (");
      for (int i = 1; i < types.length; i++) {
        if (i > 1) sb.append(", ");
        sb.append(types[i]);
      }
      if (varargs) sb.append(", ...");
      sb.append(')');
      return sb.toString();
    }

    @Override
    public Kind kind() {
      return Kind.FN;
    }
  }
}
