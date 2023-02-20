import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.*;

public abstract class Option {
  private final String description;
  private final String argName;
  private final String[] names;

  private static boolean parsingOptions = true;

  static boolean readStdin = false;
  static final List<String> positionalArgs = new ArrayList<>();

  Option(String description, String argName, String... names) {
    this.description = description;
    this.argName = argName;
    this.names = names;
  }

  private String sortKey() {
    var s = names[0];
    if (Character.isUpperCase(s.charAt(0))) s += ' ';
    return s.toLowerCase(Locale.ROOT);
  }

  private static void help(Option[] options) {
    // print options in alphabetical order
    Arrays.sort(options, Comparator.comparing(Option::sortKey));

    // calculate width of the first column
    // so we know how much to indent the second
    var width = 5;
    for (var option : options) {
      var n = 1 + option.names[0].length();
      if (option.argName != null) {
        n += 1 + option.argName.length();
      }
      width = Math.max(width, n);
    }
    width += 2;

    // print the list of options and exit
    System.out.print("@file");
    for (var i = 5; i < width; i++) System.out.print(' ');
    System.out.print("read args from file\n");

    System.out.print('-');
    for (var i = 1; i < width; i++) System.out.print(' ');
    System.out.print("read from stdin\n");

    for (var option : options) {
      var n = 1 + option.names[0].length();
      System.out.print('-' + option.names[0]);
      if (option.argName != null) {
        n += 1 + option.argName.length();
        System.out.print(' ' + option.argName);
      }
      for (var i = n; i < width; i++) System.out.print(' ');
      System.out.print(option.description);
      System.out.print('\n');
    }
    System.exit(0);
  }

  abstract void accept(String arg);

  private static Option getOption(Option[] options, String name) {
    for (var option : options) for (var s : option.names) if (s.equals(name)) return option;
    return null;
  }

  static void parse(Option[] options0, String[] args) throws IOException {
    var options = new Option[options0.length + 2];
    options[0] =
        new Option("show help", null, "h", "help") {
          void accept(String arg) {
            help(options);
          }
        };
    options[1] =
        new Option("show version", null, "V", "version") {
          void accept(String arg) {
            version();
          }
        };
    System.arraycopy(options0, 0, options, 2, options0.length);

    for (var i = 0; i < args.length; i++) {
      var s = args[i];
      if (parsingOptions)
        switch (s.charAt(0)) {
          case '@' -> {
            parse(
                options,
                Files.readAllLines(Path.of(s.substring(1)), StandardCharsets.UTF_8)
                    .toArray(new String[0]));
            continue;
          }
          case '-' -> {
            switch (s) {
              case "-" -> {
                readStdin = true;
                continue;
              }
              case "--" -> {
                parsingOptions = false;
                continue;
              }
            }
            var o = s;

            // eat the -'s
            while (o.startsWith("-")) o = o.substring(1);

            // find arg if any
            String arg = null;
            var v = o.split("[:=]");
            if (v.length == 2) {
              o = v[0];
              arg = v[1];
            }

            // find the option
            var option = getOption(options, o);
            if (option == null) {
              System.err.printf("%s: unknown option\n", s);
              System.exit(1);
            }

            // not expecting arg
            if (option.argName == null) {
              if (arg != null) {
                System.err.printf("%s: unexpected arg\n", s);
                System.exit(1);
              }
              option.accept(null);
              continue;
            }

            // have arg
            if (arg != null) {
              option.accept(arg);
              continue;
            }

            // still want arg
            if (i + 1 == args.length) {
              System.err.printf("%s: expected arg\n", s);
              System.exit(1);
            }
            option.accept(args[++i]);
            continue;
          }
        }
      positionalArgs.add(s);
    }
  }

  private static void version() {
    System.out.print("Olivine version 0");
    var path = System.getProperty("java.class.path");
    if (!(".".equals(path))) System.out.print(", " + path);
    System.out.print('\n');

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
    System.exit(0);
  }
}
