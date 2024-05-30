package olivine;

import java.io.IOException;
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

  public static void main(String[] args) throws IOException {
    // Command line
    Option.parse(OPTIONS, args);
    if (Option.positionalArgs.isEmpty()) {
      System.err.println("No input files specified");
      System.exit(1);
    }
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
