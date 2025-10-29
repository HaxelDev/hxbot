package hxbot.data;

typedef Role = {
    id: String,
    name: String,
    color: Int,
    hoist: Bool,
    position: Int,
    permissions: String,
    managed: Bool,
    mentionable: Bool,
    ?icon: Null<String>,
    ?unicode_emoji: Null<String>,
    ?guild_id: String,
    ?flags: Int,
    ?raw_color: Int,
    ?raw_permissions: String,
    ?created_at: String,
    ?tags: {
        ?bot_id: Null<String>,
        ?integration_id: Null<String>,
        ?premium_subscriber: Null<Bool>,
        ?subscription_listing_id: Null<String>,
        ?available_for_purchase: Null<Bool>,
    }
};
