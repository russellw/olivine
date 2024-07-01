public class NestedSwitchDemo {
  public static void main(String[] args) {
    String season = "SUMMER";
    int month = 7;
    String activity = getSuggestedActivity(season, month);
    System.out.println("Suggested activity in " + season + " (Month " + month + "): " + activity);

    season = "WINTER";
    month = 12;
    activity = getSuggestedActivity(season, month);
    System.out.println("Suggested activity in " + season + " (Month " + month + "): " + activity);

    season = "SPRING";
    month = 4;
    activity = getSuggestedActivity(season, month);
    System.out.println("Suggested activity in " + season + " (Month " + month + "): " + activity);
  }

  public static String getSuggestedActivity(String season, int month) {
    return switch (season) {
      case "WINTER" ->
          switch (month) {
            case 12, 1, 2 -> "Skiing";
            default -> "Invalid month for winter";
          };
      case "SPRING" ->
          switch (month) {
            case 3, 4, 5 -> "Hiking";
            default -> "Invalid month for spring";
          };
      case "SUMMER" ->
          switch (month) {
            case 6, 7, 8 -> "Swimming";
            default -> "Invalid month for summer";
          };
      case "AUTUMN" ->
          switch (month) {
            case 9, 10, 11 -> "Leaf peeping";
            default -> "Invalid month for autumn";
          };
      default -> "Invalid season";
    };
  }
}
