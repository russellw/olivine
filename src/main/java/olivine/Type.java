package olivine;

import java.util.*;

public abstract class Type implements Iterable<Type> {
  private static final class Array extends Sequential {
    public Array(int count, Type element) {
      super(count, element);
    }

    @Override
    public Kind kind() {
      return Kind.ARRAY;
    }

    @Override
    public Type rewrite(Type[] types) {
      assert types.length == 1;
      return new Array(count, types[0]);
    }

    @Override
    public String toString() {
      return "[" + count + " x " + element + ']';
    }
  }

  private abstract static class Compound extends Type {
    public final Type[] elements;

    public Compound(Type[] elements) {
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
    public Type get(int i) {
      return elements[i];
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
    public int size() {
      return elements.length;
    }
  }

  private static final class FunctionType extends Compound {
    public final boolean varargs;

    public FunctionType(Type[] elements, boolean varargs) {
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
    public Kind kind() {
      return Kind.FUNCTION;
    }

    @Override
    public Type rewrite(Type[] types) {
      return new FunctionType(types, varargs);
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
  }

  private abstract static class Sequential extends Type {
    public final int count;
    public final Type element;

    private Sequential(int count, Type element) {
      this.count = count;
      this.element = element;
    }

    @Override
    public int count() {
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
    public Type get(int i) {
      assert i == 0;
      return element;
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
    public int size() {
      return 1;
    }
  }

  private static final class Struct extends Compound {
    public Struct(Type[] fields) {
      super(fields);
    }

    @Override
    public Kind kind() {
      return Kind.STRUCT;
    }

    @Override
    public Type rewrite(Type[] types) {
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
  }

  private static final class Vector extends Sequential {
    public Vector(int count, Type element) {
      super(count, element);
    }

    @Override
    public Kind kind() {
      return Kind.VECTOR;
    }

    @Override
    public Type rewrite(Type[] types) {
      assert types.length == 1;
      return new Vector(count, types[0]);
    }

    @Override
    public String toString() {
      return "<" + count + " x " + element + '>';
    }
  }

  public static final Type BFLOAT =
      new Type() {
        @Override
        public int bits() {
          return 16;
        }

        @Override
        public boolean isFloat() {
          return true;
        }

        @Override
        public Kind kind() {
          return Kind.BFLOAT;
        }

        @Override
        public String toString() {
          return "bfloat";
        }
      };

  public static final Type DOUBLE =
      new Type() {
        @Override
        public int bits() {
          return 64;
        }

        @Override
        public boolean isFloat() {
          return true;
        }

        @Override
        public Kind kind() {
          return Kind.DOUBLE;
        }

        @Override
        public String toString() {
          return "double";
        }
      };

  public static final Type FLOAT =
      new Type() {
        @Override
        public int bits() {
          return 32;
        }

        @Override
        public boolean isFloat() {
          return true;
        }

        @Override
        public Kind kind() {
          return Kind.FLOAT;
        }

        @Override
        public String toString() {
          return "float";
        }
      };

  public static final Type FP128 =
      new Type() {
        @Override
        public int bits() {
          return 128;
        }

        @Override
        public boolean isFloat() {
          return true;
        }

        @Override
        public Kind kind() {
          return Kind.FP128;
        }

        @Override
        public String toString() {
          return "fp128";
        }
      };

  public static final Type HALF =
      new Type() {
        @Override
        public int bits() {
          return 16;
        }

        @Override
        public boolean isFloat() {
          return true;
        }

        @Override
        public Kind kind() {
          return Kind.HALF;
        }

        @Override
        public String toString() {
          return "half";
        }
      };

  public static final Type I1 =
      new Type() {
        @Override
        public int bits() {
          return 1;
        }

        @Override
        public Kind kind() {
          return Kind.INT;
        }

        @Override
        public String toString() {
          return "i1";
        }
      };

  public static final Type I128 =
      new Type() {
        @Override
        public int bits() {
          return 128;
        }

        @Override
        public Kind kind() {
          return Kind.INT;
        }

        @Override
        public String toString() {
          return "i128";
        }
      };

  public static final Type I16 =
      new Type() {
        @Override
        public int bits() {
          return 16;
        }

        @Override
        public Kind kind() {
          return Kind.INT;
        }

        @Override
        public String toString() {
          return "i16";
        }
      };

  public static final Type I32 =
      new Type() {
        @Override
        public int bits() {
          return 32;
        }

        @Override
        public Kind kind() {
          return Kind.INT;
        }

        @Override
        public String toString() {
          return "i32";
        }
      };

  public static final Type I64 =
      new Type() {
        @Override
        public int bits() {
          return 64;
        }

        @Override
        public Kind kind() {
          return Kind.INT;
        }

        @Override
        public String toString() {
          return "i64";
        }
      };

  public static final Type I8 =
      new Type() {
        @Override
        public int bits() {
          return 8;
        }

        @Override
        public Kind kind() {
          return Kind.INT;
        }

        @Override
        public String toString() {
          return "i8";
        }
      };

  public static final Type OPAQUE =
      new Type() {
        @Override
        public Kind kind() {
          return Kind.OPAQUE;
        }

        @Override
        public String toString() {
          return "opaque";
        }
      };

  public static final Type PPC_FP128 =
      new Type() {
        @Override
        public int bits() {
          return 128;
        }

        @Override
        public boolean isFloat() {
          return true;
        }

        @Override
        public Kind kind() {
          return Kind.PPC_FP128;
        }

        @Override
        public String toString() {
          return "ppc_fp128";
        }
      };

  public static final Type PTR =
      new Type() {
        @Override
        public Kind kind() {
          return Kind.PTR;
        }

        @Override
        public String toString() {
          return "ptr";
        }
      };

  public static final Type VOID =
      new Type() {
        @Override
        public Kind kind() {
          return Kind.VOID;
        }

        @Override
        public String toString() {
          return "void";
        }
      };

  public static final Type X86_FP80 =
      new Type() {
        @Override
        public int bits() {
          return 80;
        }

        @Override
        public boolean isFloat() {
          return true;
        }

        @Override
        public Kind kind() {
          return Kind.X86_FP80;
        }

        @Override
        public String toString() {
          return "x86_fp80";
        }
      };

  public Type array(int count) {
    return new Array(count, this);
  }

  public int bits() {
    throw new UnsupportedOperationException(toString());
  }

  public int count() {
    throw new UnsupportedOperationException(toString());
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

  public Type get(int i) {
    throw new IndexOutOfBoundsException(toString());
  }

  public boolean isFloat() {
    return false;
  }

  public final boolean isInt() {
    return kind() == Kind.INT;
  }

  @Override
  public Iterator<Type> iterator() {
    return Collections.emptyIterator();
  }

  public abstract Kind kind();

  public Type resolve(Map<String, Type> typeMap) {
    var types = new Type[size()];
    for (var i = 0; i < types.length; i++) types[i] = get(i).resolve(typeMap);
    return rewrite(types);
  }

  public Type rewrite(Type[] types) {
    assert types.length == 0;
    return this;
  }

  public int size() {
    return 0;
  }

  public static Type struct(List<Type> fields) {
    return new Struct(fields.toArray(new Type[0]));
  }

  public static Type struct(Type... fields) {
    return new Struct(fields);
  }

  public Type vector(int count) {
    return new Vector(count, this);
  }
}
