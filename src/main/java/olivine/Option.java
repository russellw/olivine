package olivine;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;

public abstract class Option {
  private static boolean parsingOptions = true;
  public static final List<String> positionalArgs = new ArrayList<>();

  private final String argName;
  private final String description;
  private final String longName;
  private final char shortName;

  protected Option(char shortName, String longName, String argName, String description) {
    this.shortName = shortName;
    this.longName = longName;
    this.argName = argName;
    this.description = description;
  }

  public abstract void accept(String arg) throws IOException;

  private static Option getOption(Option[] options, String longName) {
    for (var option : options) if (option.longName.equals(longName)) return option;
    return null;
  }

  private static Option getOption(Option[] options, char shortName) {
    for (var option : options) if (option.shortName == shortName) return option;
    return null;
  }

  private static int help(Option[] options, boolean live, int width) {
    if (live) {
      System.out.print("@file");
      for (var i = 5; i < width; i++) System.out.print(' ');
      System.out.println("  Read args from file");
    }
    var width1 = 0;
    for (var option : options) {
      // Short name
      var n = 4;
      if (live)
        if (option.shortName == '\0') System.out.print("    ");
        else {
          System.out.print('-');
          System.out.print(option.shortName);
          System.out.print(", ");
        }

      // Long name
      n += 2 + option.longName.length();
      if (live) {
        System.out.print("--");
        System.out.print(option.longName);
      }

      // Arg name
      if (option.argName != null) {
        n += 1 + option.argName.length();
        if (live) {
          System.out.print(' ');
          System.out.print(option.argName);
        }
      }

      // Description
      width1 = Math.max(width1, n);
      if (live) {
        for (var i = n; i < width; i++) System.out.print(' ');
        System.out.print("  ");
        System.out.println(option.description);
      }
    }
    return width1;
  }

  public static void help(Option[] options) {
    var width = help(options, false, 0);
    help(options, true, width);
    System.exit(0);
  }

  private static boolean isSeparator(char c) {
    return switch (c) {
      case ':', '=' -> true;
      default -> false;
    };
  }

  public static void parse(Option[] options, String[] args) throws IOException {
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
            // -
            if (s.length() == 1) {
              System.err.printf("%s: unknown option\n", s);
              System.exit(1);
            }

            // Option, maybe with option arg
            Option option;
            int argBegin;
            if (s.charAt(1) == '-') {
              // --
              if (s.length() == 2) {
                parsingOptions = false;
                continue;
              }

              // --opt[=arg]
              argBegin = separator(s, 2);
              option = getOption(options, s.substring(2, argBegin));
              argBegin++;
            } else if (s.length() == 2) {
              // -o
              option = getOption(options, s.charAt(1));
              argBegin = s.length();
            } else if (isSeparator(s.charAt(2))) {
              // -o=arg
              option = getOption(options, s.charAt(1));
              argBegin = 3;
            } else {
              // -oarg
              option = getOption(options, s.charAt(1));
              argBegin = 2;
            }

            // The option was not found
            if (option == null) {
              System.err.printf("%s: unknown option\n", s);
              System.exit(1);
            }

            // Not expecting arg
            if (option.argName == null) {
              if (argBegin < s.length()) {
                System.err.printf("%s: unexpected arg\n", s);
                System.exit(1);
              }
              option.accept(null);
              continue;
            }

            // Expecting arg
            String arg = null;
            if (argBegin < s.length()) arg = s.substring(argBegin);
            else if (i + 1 == args.length) {
              System.err.printf("%s: expected arg\n", s);
              System.exit(1);
            } else arg = args[++i];
            option.accept(arg);
            continue;
          }
        }
      positionalArgs.add(s);
    }
  }

  private static int separator(String s, @SuppressWarnings("SameParameterValue") int i) {
    while (i < s.length() && !isSeparator(s.charAt(i))) i++;
    return i;
  }
}
