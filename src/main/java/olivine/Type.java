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
        public boolean isFloat() {
          return true;
        }

        @Override
        int bits() {
          return 16;
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
        int bits() {
          return 16;
        }

        @Override
        public boolean isFloat() {
          return true;
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
        public boolean isFloat() {
          return true;
        }

        @Override
        int bits() {
          return 32;
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
        int bits() {
          return 64;
        }

        @Override
        public boolean isFloat() {
          return true;
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
        public boolean isFloat() {
          return true;
        }

        @Override
        int bits() {
          return 128;
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
        int bits() {
          return 80;
        }

        @Override
        public boolean isFloat() {
          return true;
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
        public boolean isFloat() {
          return true;
        }

        @Override
        int bits() {
          return 128;
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

  Type rewrite(Type[] types) {
    assert types.length == 0;
    return this;
  }

  public final boolean isInt() {
    return kind() == Kind.INT;
  }

  public boolean isFloat() {
    return false;
  }

  public Type vector(int count) {
    return new Vector(count, this);
  }

  public Type array(int count) {
    return new Array(count, this);
  }

  int bits() {
    throw new UnsupportedOperationException(toString());
  }

  public int size() {
    return 0;
  }

  @Override
  public Iterator<Type> iterator() {
    return Collections.emptyIterator();
  }

  abstract Kind kind();

  public Type get(int i) {
    throw new IndexOutOfBoundsException(toString());
  }

  public static Type struct(Type... fields) {
    return new Struct(fields);
  }

  public static Type struct(List<Type> fields) {
    return new Struct(fields.toArray(new Type[0]));
  }

  int count() {
    throw new UnsupportedOperationException(toString());
  }

  private abstract static class Sequential extends Type {
    final int count;
    final Type element;

    private Sequential(int count, Type element) {
      this.count = count;
      this.element = element;
    }

    @Override
    int count() {
      return count;
    }

    @Override
    public boolean equals(Object o) {
      if (this == o) return true;
      if (o == null || getClass() != o.getClass()) return false;
      Sequential types = (Sequential) o;
      return count == types.count && Objects.equals(element, types.element);
    }

    @Override
    public int hashCode() {
      return Objects.hash(count, element);
    }

    @Override
    public Iterator<Type> iterator() {
      return Collections.singletonList(element).iterator();
    }

    @Override
    public Type get(int i) {
      assert i == 0;
      return element;
    }

    @Override
    public int size() {
      return 1;
    }
  }

  private static final class Array extends Sequential {
    Array(int count, Type element) {
      super(count, element);
    }

    @Override
    Type rewrite(Type[] types) {
      assert types.length == 1;
      return new Array(count, types[0]);
    }

    @Override
    public String toString() {
      return "[" + count + " x " + element + ']';
    }

    @Override
    Kind kind() {
      return Kind.ARRAY;
    }
  }

  private static final class Vector extends Sequential {
    Vector(int count, Type element) {
      super(count, element);
    }

    @Override
    Type rewrite(Type[] types) {
      assert types.length == 1;
      return new Vector(count, types[0]);
    }

    @Override
    public String toString() {
      return "<" + count + " x " + element + '>';
    }

    @Override
    Kind kind() {
      return Kind.VECTOR;
    }
  }

  private abstract static class Compound extends Type {
    final Type[] elements;

    Compound(Type[] elements) {
      this.elements = elements;
    }

    @Override
    public boolean equals(Object o) {
      if (this == o) return true;
      if (o == null || getClass() != o.getClass()) return false;
      Compound types = (Compound) o;
      return Objects.deepEquals(elements, types.elements);
    }

    @Override
    public int hashCode() {
      return Arrays.hashCode(elements);
    }

    @Override
    public Iterator<Type> iterator() {
      return Arrays.asList(elements).iterator();
    }

    @Override
    public Type get(int i) {
      return elements[i];
    }

    @Override
    public int size() {
      return elements.length;
    }
  }

  private static final class Struct extends Compound {
    Struct(Type[] fields) {
      super(fields);
    }

    @Override
    Type rewrite(Type[] types) {
      return new Struct(types);
    }

    @Override
    public String toString() {
      var sb = new StringBuilder();
      sb.append('{');
      var more = false;
      for (var field : elements) {
        if (more) sb.append(',');
        more = true;
        sb.append(field);
      }
      sb.append('}');
      return sb.toString();
    }

    @Override
    public Kind kind() {
      return Kind.STRUCT;
    }
  }

  public static Type function(Type returnType, List<Type> params, boolean varargs) {
    var elements = new Type[1 + params.size()];
    elements[0] = returnType;
    for (var i = 0; i < params.size(); i++) elements[1 + i] = params.get(i);
    return new FunctionType(elements, varargs);
  }

  public static Type function(Type[] elements, boolean varargs) {
    return new FunctionType(elements, varargs);
  }

  private static final class FunctionType extends Compound {
    final boolean varargs;

    @Override
    Type rewrite(Type[] types) {
      return new FunctionType(types, varargs);
    }

    FunctionType(Type[] elements, boolean varargs) {
      super(elements);
      this.varargs = varargs;
    }

    @Override
    public boolean equals(Object o) {
      if (this == o) return true;
      if (o == null || getClass() != o.getClass()) return false;
      FunctionType types = (FunctionType) o;
      return varargs == types.varargs && Arrays.equals(elements, types.elements);
    }

    @Override
    public int hashCode() {
      int result = Objects.hash(varargs);
      result = 31 * result + Arrays.hashCode(elements);
      return result;
    }

    @Override
    public String toString() {
      var sb = new StringBuilder();
      sb.append(elements[0]);
      sb.append(" (");
      for (int i = 1; i < elements.length; i++) {
        if (i > 1) sb.append(", ");
        sb.append(elements[i]);
      }
      if (varargs) sb.append(", ...");
      sb.append(')');
      return sb.toString();
    }

    @Override
    public Kind kind() {
      return Kind.FUNCTION;
    }
  }
}
