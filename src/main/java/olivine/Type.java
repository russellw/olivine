package olivine;

public abstract class Type {
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

  abstract Kind kind();
}
