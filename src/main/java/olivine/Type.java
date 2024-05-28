package olivine;

import java.util.Iterator;
import java.util.NoSuchElementException;

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
    return new NullaryIterator();
  }

  abstract Kind kind();

  private static class NullaryIterator implements Iterator<Type> {
    @Override
    public boolean hasNext() {
      return false;
    }

    @Override
    public Type next() {
      throw new NoSuchElementException();
    }
  }
}
