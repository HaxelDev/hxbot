package hxbot.data;

typedef Message = {
    id: String,
    channel_id: String,
    ?guild_id: String,
    author: {
        id: String,
        username: String,
        discriminator: String,
        ?avatar: String,
        ?bot: Bool
    },
    content: String,
    timestamp: String,
    ?edited_timestamp: String,
    tts: Bool,
    message_reference: {
        ?message_id: String,
        ?channel_id: String,
        ?guild_id: String
    },
    mention_everyone: Bool,
    mentions: Array<{
        id: String,
        username: String,
        discriminator: String,
        ?avatar: String
    }>,
    mention_roles: Array<String>,
    mention_channels: Array<{
        id: String,
        guild_id: String,
        type: Int,
        name: String
    }>,
    attachments: Array<{
        id: String,
        filename: String,
        size: Int,
        url: String,
        proxy_url: String,
        ?height: Int,
        ?width: Int
    }>,
    embeds: Array<{
        ?title: String,
        ?type: String,
        ?description: String,
        ?url: String,
        ?timestamp: String,
        ?color: Int,
        ?footer: {
            text: String,
            ?icon_url: String
        },
        ?image: {
            url: String
        },
        ?thumbnail: {
            url: String
        },
        ?video: {
            url: String
        },
        ?provider: {
            name: String,
            url: String
        },
        ?author: {
            name: String,
            url: String,
            icon_url: String
        },
        fields: Array<{
            name: String,
            value: String
            // inline: Bool
        }>
    }>,
    components: Array<{
        type: Int,
        components: Array<{
            type: Int,
            style: Int,
            label: String,
            custom_id: String,
            url: String,
            disabled: Bool,
            ?emoji: {
                ?id: String,
                ?name: String,
                animated: Bool
            }
        }>
    }>
}
