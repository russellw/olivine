public class SwitchDemo {
    public static void main(String[] args) {
        String day = "MONDAY";
        int dayNumber = getDayNumber(day);
        System.out.println("Day number for " + day + " is: " + dayNumber);

        day = "SUNDAY";
        dayNumber = getDayNumber(day);
        System.out.println("Day number for " + day + " is: " + dayNumber);

        day = "FRIDAY";
        dayNumber = getDayNumber(day);
        System.out.println("Day number for " + day + " is: " + dayNumber);

        day = "HOLIDAY";
        dayNumber = getDayNumber(day);
        System.out.println("Day number for " + day + " is: " + dayNumber);
    }

    public static int getDayNumber(String day) {
        return switch (day) {
            case "MONDAY" -> 1;
            case "TUESDAY" -> 2;
            case "WEDNESDAY" -> 3;
            case "THURSDAY" -> 4;
            case "FRIDAY" -> 5;
            case "SATURDAY" -> 6;
            case "SUNDAY" -> 7;
            default -> throw new IllegalArgumentException("Invalid day: " + day);
        };
    }
}
