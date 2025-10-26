package hxbot.data;

typedef Channel = {
    id: String,
    type: Int,
    guild_id: Null<String>,
    position: Null<Int>,
    permission_overwrites: Array<Dynamic>,
    name: String,
    topic: Null<String>,
    nsfw: Bool,
    last_message_id: Null<String>,
    bitrate: Null<Int>,
    user_limit: Null<Int>,
    rate_limit_per_user: Null<Int>,
    recipients: Null<Array<User>>,
    recipient_flags: Null<Int>,
    icon: Null<String>,
    nicks: Null<Array<Dynamic>>,
    managed: Bool,
    blocked_user_warning_dismissed: Null<Bool>,
    safety_warnings: Null<Array<Dynamic>>,
    application_id: Null<String>
};
