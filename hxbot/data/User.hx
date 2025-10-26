package hxbot.data;

typedef User = {
    id: String,
    username: String,
    discriminator: String,
    avatar: String,
    bot: Bool,
    email: Null<String>,
    verified: Bool,
    flags: Int,
    banner: Null<String>,
    accent_color: Null<Int>,
    premium_type: Int,
    public_flags: Int
};
