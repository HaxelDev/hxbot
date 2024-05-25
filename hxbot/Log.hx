package hxbot;

class Log {
    private static var RESET = "\x1b[0m";
    private static var RED = "\x1b[31m";
    private static var YELLOW = "\x1b[33m";
    private static var BLUE = "\x1b[34m";
    private static var CYAN = "\x1b[36m";
    private static var GREEN = "\x1b[32m";
    private static var MAGENTA = "\x1b[35m";
    private static var BOLD = "\x1b[1m";
    private static var UNDERLINE = "\x1b[4m";

    private static function formatMessage(level:String, color:String, message:String, ?pos:haxe.PosInfos):String {
        return BOLD + color + "[" + level + "]" + RESET + " - " + message;
    }

    public static function info(message:String):Void {
        Sys.println(formatMessage("INFO", CYAN, message));
    }

    public static function warn(message:String):Void {
        Sys.println(formatMessage("WARN", YELLOW, message));
    }

    public static function error(message:String):Void {
        Sys.println(formatMessage("ERROR", RED, message));
    }

    public static function debug(message:String):Void {
        Sys.println(formatMessage("DEBUG", BLUE, message));
    }

    public static function success(message:String):Void {
        Sys.println(formatMessage("SUCCESS", GREEN, message));
    }

    public static function important(message:String):Void {
        Sys.println(BOLD + UNDERLINE + formatMessage("IMPORTANT", MAGENTA, message));
    }
}
