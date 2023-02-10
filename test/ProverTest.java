import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.nio.file.attribute.BasicFileAttributes;
import java.util.Timer;
import java.util.TimerTask;
import java.util.regex.Pattern;

class ProverTest {
  private enum SZS {
    Theorem,
    Satisfiable,
    Unsatisfiable,
    Unknown,
    CounterSatisfiable,
    ContradictoryAxioms,
    Open,
  }

  private static final Pattern DIMACS_PATTERN = Pattern.compile(".* (SAT|UNSAT) .*");

  private static final Option[] OPTIONS =
      new Option[] {
        new Option("time limit", "seconds", "t", "T", "cpu-limit") {
          void accept(String arg) {
            var seconds = Double.parseDouble(arg);
            new Timer()
                .schedule(
                    new TimerTask() {
                      public void run() {
                        System.exit(1);
                      }
                    },
                    (long) (seconds * 1000));
          }
        },
      };

  private static SZS statusDimacs(String file) throws IOException {
    for (var s : Files.readAllLines(Path.of(file), StandardCharsets.UTF_8)) {
      var matcher = DIMACS_PATTERN.matcher(s);
      if (matcher.matches())
        return switch (matcher.group(1)) {
          case "SAT" -> SZS.Satisfiable;
          case "UNSAT" -> SZS.Unsatisfiable;
          default -> throw new IllegalStateException(s);
        };
    }
    return SZS.Unknown;
  }

  private static SZS status(String file) throws IOException {
    return switch (language(file)) {
      case DIMACS -> statusDimacs(file);
      default -> throw new IllegalStateException(file);
    };
  }

  private static Language language(String file) {
    return switch (Etc.ext(file)) {
      case "cnf" -> Language.DIMACS;
      case "p" -> Language.TPTP;
      default -> null;
    };
  }

  private static void test(String file) throws IOException {
    var lang = language(file);
    if (lang == null) return;

    System.out.printf("%-50s", file);

    var expected = status(file);
    System.out.printf(" %-19s", expected);

    Etc.startTimer();
    try {
      var result = Prover.solve(file, Long.MAX_VALUE) ? SZS.Satisfiable : SZS.Unsatisfiable;
      System.out.printf(" %-19s", result);
      if (result != expected) throw new IllegalStateException();
    } catch (Fail ignored) {
      System.out.printf(" %-19s", "");
    }
    Etc.endTimer();
  }

  public static void main(String[] args) {
    try {
      Option.parse(OPTIONS, args);
      for (var file : Option.positionalArgs) {
        var path = Path.of(file);
        if (Files.isDirectory(path)) {
          Files.walkFileTree(
              path,
              new SimpleFileVisitor<>() {
                public FileVisitResult visitFile(Path file, BasicFileAttributes attrs)
                    throws IOException {
                  test(file.toString());
                  return FileVisitResult.CONTINUE;
                }
              });
          continue;
        }
        if (file.endsWith(".lst")) {
          for (var s : Files.readAllLines(path, StandardCharsets.UTF_8)) test(s);
          continue;
        }
        test(file);
      }
    } catch (Throwable e) {
      e.printStackTrace();
      System.exit(1);
    }
    System.exit(0);
  }
}
