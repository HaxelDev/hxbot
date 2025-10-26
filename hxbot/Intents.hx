package hxbot;

class Intents {
    public static inline var GUILDS:Int = 1 << 0;
    public static inline var GUILD_MEMBERS:Int = 1 << 1;
    public static inline var GUILD_BANS:Int = 1 << 2;
    public static inline var GUILD_EMOJIS:Int = 1 << 3;
    public static inline var GUILD_INTEGRATIONS:Int = 1 << 4;
    public static inline var GUILD_WEBHOOKS:Int = 1 << 5;
    public static inline var GUILD_INVITES:Int = 1 << 6;
    public static inline var GUILD_VOICE_STATES:Int = 1 << 7;
    public static inline var GUILD_PRESENCES:Int = 1 << 8;
    public static inline var GUILD_MESSAGES:Int = 1 << 9;
    public static inline var GUILD_MESSAGE_REACTIONS:Int = 1 << 10;
    public static inline var GUILD_MESSAGE_TYPING:Int = 1 << 11;
    public static inline var DIRECT_MESSAGES:Int = 1 << 12;
    public static inline var DIRECT_MESSAGE_REACTIONS:Int = 1 << 13;
    public static inline var DIRECT_MESSAGE_TYPING:Int = 1 << 14;
    public static inline var MESSAGE_CONTENT:Int = 1 << 15;

    private var mask:Int = 0;

    public function new(intents:Array<Int>) {
        for (intent in intents) {
            mask |= intent;
        }
    }

    public function getMask():Int {
        return mask;
    }

    public function add(intent:Int):Intents {
        mask |= intent;
        return this;
    }
}
