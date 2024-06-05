package olivine;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Objects;
import java.util.Properties;

final class Main {
  private static final Option[] OPTIONS =
      new Option[] {
        new Option('h', "help", null, "Show help") {
          @Override
          public void accept(String arg) {
            Option.help(OPTIONS);
          }
        },
        new Option('V', "version", null, "Show version") {
          @Override
          public void accept(String arg) throws IOException {
            printVersion();
            System.exit(0);
          }
        },
      };

  private static void run(String[] cmd) throws IOException, InterruptedException {
    // Print the command we are about to run
    var more = false;
    for (var s : cmd) {
      if (more) System.out.print(' ');
      more = true;
      System.out.print(s);
    }
    System.out.println();

    // Setup
    var builder = new ProcessBuilder(cmd);
    builder.inheritIO();

    // Run
    var process = builder.start();
    process.waitFor();

    // Check for error
    var e = process.exitValue();
    if (e != 0) {
      System.err.println("Process exit value: " + e);
      System.exit(e);
    }
  }

  public static void main(String[] args) throws IOException, InterruptedException {
    // Command line
    Option.parse(OPTIONS, args);
    if (Option.positionalArgs.isEmpty()) {
      System.err.println("No input files specified");
      System.exit(1);
    }

    // Input files
    var modules = new ArrayList<Module>();
    for (var file : Option.positionalArgs) {
      switch (Etc.extension(file)) {
        case "bc" -> {
          run(new String[] {"llvm-dis", "--", file});
          file = Etc.baseName(file) + ".ll";
        }
        case "ll" -> {}
        default -> {
          System.err.println(file + ": unknown extension");
          System.exit(1);
        }
      }
      modules.add(LlvmParser.parse(file, Files.readAllBytes(Path.of(file))));
    }
    Files.write(Path.of("a.ll"), LlvmComposer.compose(modules.getFirst()));
  }

  private static String version() throws IOException {
    var properties = new Properties();
    var stream =
        Etc.class
            .getClassLoader()
            .getResourceAsStream("META-INF/maven/olivine/olivine/pom.properties");
    if (stream == null) return null;
    properties.load(stream);
    return properties.getProperty("version");
  }

  private static void printVersion() throws IOException {
    System.out.printf(
        "Olivine %s, %s\n",
        Objects.toString(version(), "[unknown version, not running from jar]"),
        System.getProperty("java.class.path"));
    System.out.printf(
        "%s, %s, %s\n",
        System.getProperty("java.vm.name"),
        System.getProperty("java.vm.version"),
        System.getProperty("java.home"));
    System.out.printf(
        "%s, %s, %s\n",
        System.getProperty("os.name"),
        System.getProperty("os.version"),
        System.getProperty("os.arch"));
  }
}
