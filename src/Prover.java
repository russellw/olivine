import java.io.BufferedInputStream;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.*;

public final class Prover {
  private static Language specified;
  private static final Option[] OPTIONS =
      new Option[] {
        new Option("input language TPTP", null, "tptp") {
          void accept(String arg) {
            specified = Language.TPTP;
          }
        },
        new Option("input language DIMACS", null, "dimacs") {
          void accept(String arg) {
            specified = Language.DIMACS;
          }
        },
        new Option("time limit", "seconds", "t", "T", "cpu-limit") {
          void accept(String arg) {
            var seconds = Double.parseDouble(arg);
            new Timer()
                .schedule(
                    new TimerTask() {
                      public void run() {
                        System.exit(0);
                      }
                    },
                    (long) (seconds * 1000));
          }
        },
      };

  private static Language language(String file) {
    if (specified != null) return specified;
    if (file == null) {
      System.err.print("Language not specified\n");
      System.exit(1);
    }
    switch (Etc.ext(file)) {
      case "cnf" -> {
        return Language.DIMACS;
      }
      case "ax", "p" -> {
        return Language.TPTP;
      }
    }
    System.err.print(file + ": language not specified\n");
    System.exit(1);
    throw new IllegalStateException();
  }

  private static boolean solve(String file, long steps, InputStream stream) throws IOException {
    var cnf = new CNF();
    switch (language(file)) {
      case DIMACS -> DimacsParser.parse(file, stream, cnf);
      case TPTP -> TptpParser.parse(file, stream, cnf);
    }
    var clauses = cnf.clauses;
    return Clause.propositional(clauses)
        ? Dpll.sat(clauses, steps)
        : Superposition.sat(clauses, steps);
  }

  static boolean solve(String file, long steps) throws IOException {
    if (file == null) return solve("stdin", steps, System.in);
    try (var stream = new BufferedInputStream(new FileInputStream(file))) {
      return solve(file, steps, stream);
    }
  }

  public static void main(String[] args) throws IOException {
    // TODO SYN000-3 is reporting sat
    try {
      Option.parse(OPTIONS, args);

      // if the user has specified an input language but not file,
      // that is sufficient cue to read standard input
      if (Option.positionalArgs.isEmpty() && specified != null) Option.readStdin = true;

      // exactly one input source
      if (Option.positionalArgs.size() + (Option.readStdin ? 1 : 0) != 1) {
        System.err.print("Expected one input source\n");
        System.exit(1);
      }
      var file = Option.readStdin ? null : Option.positionalArgs.get(0);
      System.out.print(solve(file, Long.MAX_VALUE) ? "sat" : "unsat");
      System.out.print('\n');
    } catch (Fail ignored) {
      System.exit(0);
    } catch (Throwable e) {
      // this needs to be done explicitly in case there is a timer thread still running,
      // which would cause the program to hang until timeout without the explicit System.exit
      e.printStackTrace();
      System.exit(1);
    }
    System.exit(0);
  }
}
