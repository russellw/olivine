package olivine;

import java.io.IOException;
import java.util.Objects;
import java.util.Properties;

final class Main {
  private static final Option[] OPTIONS =
      new Option[] {
        new Option('h', "help", null, "show help") {
          @Override
          public void accept(String arg) {
            Option.help(OPTIONS);
          }
        },
        new Option('V', "version", null, "show version") {
          @Override
          public void accept(String arg) {
            printVersion();
            System.exit(0);
          }
        },
      };

  private Main() {}

  public static void main(String[] args) {
    System.out.println("Hello World!");
  }

  private static String version() {
    var properties = new Properties();
    var stream =
        Etc.class
            .getClassLoader()
            .getResourceAsStream("META-INF/maven/olivine/olivine/pom.properties");
    if (stream == null) return null;
    try {
      properties.load(stream);
    } catch (IOException e) {
      e.printStackTrace();
      System.exit(1);
    }
    return properties.getProperty("version");
  }

  private static void printVersion() {
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
