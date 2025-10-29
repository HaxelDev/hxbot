package hxbot.data;

typedef Thread = {
    id:String,
    guild_id:Null<String>,
    parent_id:Null<String>,
    name:String,
    message_count:Int,
    member_count:Int,
    owner_id:Null<String>,
    locked:Bool,
    invitable:Bool,
    archive_timestamp:String,
    archived:Bool,
    auto_archive_duration:Int,
    create_timestamp:String,
    applied_tags:Array<String>,
    slowmode_delay:Null<Int>,
    total_message_sent:Int
};
