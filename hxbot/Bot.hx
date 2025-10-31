package hxbot;

import haxe.Http;
import haxe.Json;
import haxe.Timer;
import hxbot.data.*;

class Bot {
    public var token:String;
    public var onMessage:Event<Message>;
    public var onReady:Event<Void>;
    public var onInteraction:Event<Dynamic>;
    public var onThread:Event<Thread>;

    private var heartbeatInterval:Float = 0;
    private var lastSequence:Null<Float> = null;
    private var ws:Dynamic;
    private var heartbeatTimer:Timer;

    public var intentsMask:Int;
    public var baseUrl:String = "https://discord.com/api/v10";

    public var userCache:Cache<User>;
    public var channelCache:Cache<Channel>;
    public var guildCache:Cache<Guild>;
    public var rolesCache:Cache<Array<Role>>;

    public function new(token:String, ?intents:Array<Int>) {
        this.token = token;

        this.onMessage = new Event<Message>();
        this.onReady = new Event<Void>();
        this.onInteraction = new Event<Dynamic>();
        this.onThread = new Event<Thread>();

        this.userCache = new Cache<User>(5000, 60 * 60 * 1000);
        this.channelCache = new Cache<Channel>(2000, 30 * 60 * 1000);
        this.guildCache = new Cache<Guild>(1000, null);
        this.rolesCache = new Cache<Array<Role>>(5000, 30 * 60 * 1000);

        if (intents != null) {
            var intentsObj = new Intents(intents);
            this.intentsMask = intentsObj.getMask();
        } else {
            this.intentsMask = new Intents([Intents.GUILDS, Intents.GUILD_MESSAGES, Intents.MESSAGE_CONTENT]).getMask();
        }
    }

    public function startPolling(timeoutSec:Int = 20):Void {
        initGateway();
    }

    private function initGateway():Void {
        var url = baseUrl + "/gateway/bot";
        var http = new Http(url);
        http.setHeader("Authorization", "Bot " + token);
        http.onData = (data:String) -> {
            try {
                var js = Json.parse(data);
                var wsUrl:String = js.url;
                connectWebSocket(wsUrl + "/?v=10&encoding=json");
            } catch (e:Dynamic) {
                Sys.println("Parsing gateway info failed: " + e);
                Timer.delay( () -> initGateway(), 5000 );
            }
        };
        http.onError = (err:String) -> {
            Sys.println("HTTP error fetching gateway: " + err);
            Timer.delay( () -> initGateway(), 5000 );
        };
        http.request(false);
    }

    private function connectWebSocket(wsUrl:String):Void {
        ws = new websocket.WebSocket(wsUrl);
        ws.onOpen = () -> {
            // Sys.println("WebSocket opened");
        };
        ws.onStringData = (msg:String) -> {
            var obj = Json.parse(msg);
            var op:Int = obj.op;
            var d = obj.d;
            var t:Dynamic = obj.t;
            var s:Dynamic = obj.s;

            if (s != null) {
                lastSequence = Std.parseFloat(Std.string(s));
            }

            switch (op) {
                case 10:
                    heartbeatInterval = d.heartbeat_interval;
                    startHeartbeat();
                    sendIdentify();
                case 0:
                    switch (t) {
                        case "READY":
                            onReady.dispatchVoid();
                        case "MESSAGE_CREATE":
                            var m = mapToMessage(d);
                            onMessage.dispatch(m);
                        case "INTERACTION_CREATE":
                            onInteraction.dispatch(d);
                        case "THREAD_CREATE":
                            var th = mapToThread(d);
                            onThread.dispatch(th);
                        default:
                    }
                case 1:
                    sendHeartbeat();
                case 11:
                default:
            }
        };
        ws.onClose = (_) -> {
            // Sys.println("WebSocket closed — reconnecting");
            if (heartbeatTimer != null) heartbeatTimer.stop();
            Timer.delay( () -> initGateway(), 5000 );
        };
    }

    private function startHeartbeat():Void {
        sendHeartbeat();
        heartbeatTimer = new Timer(Std.int(heartbeatInterval));
        heartbeatTimer.run = () -> {
            sendHeartbeat();
        };
    }

    private function sendHeartbeat():Void {
        var payload = {
            op: 1,
            d: (lastSequence == null ? null : lastSequence)
        };
        var json = Json.stringify(payload);
        ws.sendString(json);
    }

    private function sendIdentify():Void {
        var mask = this.intentsMask;
        var payload = {
            op: 2,
            d: {
                token: token,
                intents: mask,
                properties: {
                    "$os": "haxe",
                    "$browser": "hxbot",
                    "$device": "hxbot"
                }
            }
        };
        var json = Json.stringify(payload);
        ws.sendString(json);
    }

    public function sendMessage(channelId:String, content:String, ?components:Array<Dynamic>, ?embeds:Array<Dynamic>):Void {
        var url = baseUrl + "/channels/" + channelId + "/messages";
        var body = { content: content };
        if (components != null) {
            Reflect.setProperty(body, "components", components);
        }
        if (embeds != null) {
            Reflect.setProperty(body, "embeds", embeds);
        }
        request("POST", url, body, (res) -> {
            if (!res.success) {
                Sys.println("Failed to send message, error: " + res.error);
            }
        });
    }

    public function replyMessage(channelId:String, content:String, messageId:String, ?components:Array<Dynamic>, ?embeds:Array<Dynamic>):Void {
        var url = baseUrl + "/channels/" + channelId + "/messages";
        var body = {
            content: content,
            message_reference: {
                message_id: messageId
            }
        };
        if (components != null) {
            Reflect.setProperty(body, "components", components);
        }
        if (embeds != null) {
            Reflect.setProperty(body, "embeds", embeds);
        }
        request("POST", url, body, (res) -> {
            if (!res.success) {
                Sys.println("Failed to reply to message, error: " + res.error);
            }
        });
    }

    public function editMessage(channelId:String, messageId:String, content:String, ?components:Array<Dynamic>, ?embeds:Array<Dynamic>):Void {
        var url = baseUrl + "/channels/" + channelId + "/messages/" + messageId;
        var http = new haxe.Http(url);
        var body = { content: content };
        if (components != null) {
            Reflect.setProperty(body, "components", components);
        }
        if (embeds != null) {
            Reflect.setProperty(body, "embeds", embeds);
        }

        http.setHeader("Authorization", "Bot " + token);
        http.setHeader("Accept", "application/json");
        http.setHeader("Content-Type", "application/json");

        var responseBytes = new haxe.io.BytesOutput();
        http.onError = function(err:String):Void {
            Sys.println("editMessage HTTP error: " + err);
        };
        http.setPostData(Json.stringify(body));
        http.customRequest(true, responseBytes, null, "PATCH");
    }

    public function deleteMessage(channelId:String, messageId:String, callback:Bool->Void):Void {
        var url = baseUrl + "/channels/" + channelId + "/messages/" + messageId;
        var http = new haxe.Http(url);

        http.setHeader("Authorization", "Bot " + token);
        http.setHeader("Accept", "application/json");
        http.setHeader("Content-Type", "application/json");

        var responseBytes = new haxe.io.BytesOutput();

        http.onStatus = function(status:Int):Void {
            if (status == 204 || status == 200) {
                callback(true);
            } else {
                callback(false);
            }
        };
        http.onError = function(err:String):Void {
            Sys.println("deleteMessage HTTP error: " + err);
            callback(false);
        };
        http.customRequest(false, responseBytes, null, "DELETE");
    }

    public function createThread(parentChannelId:String, name:String, autoArchiveDuration:Int, ?messageId:String, ?firstMessage:String, callback:Dynamic->Void):Void {
        var url = baseUrl + "/channels/" + parentChannelId + "/threads";
        var body = {
            name: name,
            auto_archive_duration: autoArchiveDuration
        };
        if (messageId != null) {
            Reflect.setProperty(body, "message_id", messageId);
        }
        if (firstMessage != null) {
            Reflect.setProperty(body, "first_message", firstMessage);
        }
        request("POST", url, body, (res) -> {
            if (res.success) {
                callback(res.data);
            } else {
                Sys.println("createThread failed: " + res.error);
            }
        });
    }

    public function sendThreadMessage(threadChannelId:String, content:String, ?embeds:Array<Dynamic>, ?components:Array<Dynamic>):Void {
        sendMessage(threadChannelId, content, components, embeds);
    }

    public function createDM(userId:String, callback:Dynamic->Void):Void {
        var url = baseUrl + "/users/@me/channels";
        var body = { recipient_id: userId };
        request("POST", url, body, (res) -> {
            if (res.success) {
                callback(res.data);
            } else {
                Sys.println("createDM failed: " + res.error);
            }
        });
    }

    public function sendDM(userId:String, content:String, ?embeds:Array<Dynamic>, ?components:Array<Dynamic>):Void {
        createDM(userId, (dmChan) -> {
            var dmId = dmChan.id;
            sendMessage(dmId, content, components, embeds);
        });
    }

    public function fetchUser(userId:String, callback:User->Void):Void {
        if (userCache.has(userId)) {
            callback(userCache.get(userId));
            return;
        }

        var url = baseUrl + "/users/" + userId;
        request("GET", url, null, (res) -> {
            if (res.success) {
                var user = mapToUser(res.data);
                userCache.set(userId, user);
                callback(user);
            } else {
                Sys.println("Failed to fetch user: " + res.error);
            }
        });
    }

    public function fetchChannel(channelId:String, callback:Channel->Void):Void {
        // najpierw sprawdź cache
        if (channelCache.has(channelId)) {
            callback(channelCache.get(channelId));
            return;
        }

        var url = baseUrl + "/channels/" + channelId;
        request("GET", url, null, (res) -> {
            if (res.success) {
                var channel = mapToChannel(res.data);
                channelCache.set(channelId, channel);
                callback(channel);
            } else {
                Sys.println("Failed to fetch channel: " + res.error);
            }
        });
    }

    public function fetchGuild(guildId:String, callback:Guild->Void):Void {
        if (guildCache.has(guildId)) {
            callback(guildCache.get(guildId));
            return;
        }

        var url = baseUrl + "/guilds/" + guildId + "?with_counts=true";
        request("GET", url, null, (res) -> {
            if (res.success) {
                var guild = mapToGuild(res.data);
                guildCache.set(guildId, guild);
                callback(guild);
            } else {
                Sys.println("Failed to fetch guild: " + res.error);
            }
        });
    }

    public function fetchRoles(guildId:String, callback:Array<Role>->Void):Void {
        if (rolesCache.has(guildId)) {
            callback(rolesCache.get(guildId));
            return;
        }

        var url = baseUrl + "/guilds/" + guildId + "/roles";
        request("GET", url, null, (res) -> {
            if (res.success) {
                var rolesJson:Array<Dynamic> = res.data;
                var roles = rolesJson.map(mapToRole);
                rolesCache.set(guildId, roles);
                callback(roles);
            } else {
                Sys.println("Failed to fetch roles: " + res.error);
            }
        });
    }

    public function fetchRole(guildId:String, roleId:String, callback:Role->Void):Void {
        fetchRoles(guildId, function(roles:Array<Role>) {
            for (role in roles) {
                if (role.id == roleId) {
                    callback(role);
                    return;
                }
            }
            Sys.println("Role not found: " + roleId);
        });
    }

    public function sendFile(channelId:String, filePath:String, ?content:String = "", ?filename:String = null, ?embeds:Array<Dynamic> = null):Void {
        if (filename == null) {
            var parts = filePath.split("/");
            filename = parts[parts.length - 1];
        }

        var url = baseUrl + "/channels/" + channelId + "/messages";
        var bytes = sys.io.File.getBytes(filePath);

        var boundary = "----HxBotBoundary" + Std.int(Math.random() * 100000);
        var body = new StringBuf();

        var payload = {
            content: content,
            embeds: embeds
        };
        body.add("--" + boundary + "\r\n");
        body.add('Content-Disposition: form-data; name="payload_json"\r\n');
        body.add('Content-Type: application/json\r\n\r\n');
        body.add(haxe.Json.stringify(payload));
        body.add("\r\n");

        body.add("--" + boundary + "\r\n");
        body.add('Content-Disposition: form-data; name="files[0]"; filename="' + filename + '"\r\n');
        body.add("Content-Type: application/octet-stream\r\n\r\n");
        var headerBytes = haxe.io.Bytes.ofString(body.toString());

        var footer = "\r\n--" + boundary + "--\r\n";
        var footerBytes = haxe.io.Bytes.ofString(footer);

        var full = haxe.io.Bytes.alloc(headerBytes.length + bytes.length + footerBytes.length);
        full.blit(0, headerBytes, 0, headerBytes.length);
        full.blit(headerBytes.length, bytes, 0, bytes.length);
        full.blit(headerBytes.length + bytes.length, footerBytes, 0, footerBytes.length);

        var http = new haxe.Http(url);
        http.setHeader("Authorization", "Bot " + token);
        http.setHeader("Content-Type", "multipart/form-data; boundary=" + boundary);
        http.setPostBytes(full);

        http.onError = (e:String) -> {
            Sys.println("Failed to upload file: " + e);
        };

        http.request(true);
    }

    public function respondInteraction(data:Dynamic, callback:Dynamic->Dynamic):Void {
        var responseData:Dynamic = callback(data);
        if (responseData == null) responseData = { content: "" };

        if (Reflect.hasField(responseData, "embeds") && (responseData.embeds == null || responseData.embeds.length == 0))
            Reflect.deleteField(responseData, "embeds");
        if (Reflect.hasField(responseData, "components") && (responseData.components == null || responseData.components.length == 0))
            Reflect.deleteField(responseData, "components");

        if (!Reflect.hasField(responseData, "content") && !Reflect.hasField(responseData, "embeds"))
            responseData.content = "";

        var body = { type: 4, data: responseData };
        var jsonBody = Json.stringify(body);

        var url = baseUrl + "/interactions/" + data.id + "/" + data.token + "/callback";
        var http = new haxe.Http(url);
        http.setHeader("Authorization", "Bot " + token);
        http.setHeader("Content-Type", "application/json");
        http.setPostData(jsonBody);

        http.onError = (e:String) -> Sys.println("Failed to respond to interaction, error: " + e);

        http.request(true);
    }

    public static function createButton(label:String, customId:String, style:Int = 1, emoji:Null<Dynamic> = null):Dynamic {
        var btn = {
            type: 2,
            style: style,
            label: label,
            custom_id: customId
        };
        if (emoji != null) Reflect.setProperty(btn, "emoji", emoji);
        return btn;
    }

    public static function createActionRow(buttons:Array<Dynamic>):Dynamic {
        return {
            type: 1,
            components: buttons
        };
    }

    public static function createEmbed(title:String, description:String, color:Int = 0x00FF00, ?fields:Array<Dynamic> = null):Dynamic {
        var embed = {
            title: title,
            description: description,
            color: color
        };
        if (fields != null) Reflect.setProperty(embed, "fields", fields);
        return embed;
    }

    public function setPresence(status:Status, ?activities:Array<Dynamic>):Void {
        var payload = {
            op: 3,
            d: {
                since: null,
                activities: (activities == null ? [] : activities),
                status: Std.string(status).toLowerCase(),
                afk: false
            }
        };
        var json = Json.stringify(payload);
        ws.sendString(json);
    }

    private function request(method:String, url:String, body:Dynamic, callback:Dynamic):Void {
        var http = new Http(url);
        http.onData = (data:String) -> {
            try {
                var js = Json.parse(data);
                callback({ success: true, data: js });
            } catch (e:Dynamic) {
                callback({ success: false, error: e });
            }
        };
        http.onError = (e:String) -> {
            callback({ success: false, error: e });
        };

        http.setHeader("Authorization", "Bot " + token);
        http.setHeader("Content-Type", "application/json");

        var methodBool = switch(method) {
            case "POST": true;
            default: false;
        };

        if (methodBool) {
            http.setPostData(Json.stringify(body));
        }
        http.request(methodBool);
    }

    private function mapToMessage(data:Dynamic):Message {
        return {
            id: data.id,
            channel_id: data.channel_id,
            guild_id: data.guild_id,
            author: {
                id: data.author.id,
                username: data.author.username,
                discriminator: data.author.discriminator,
                avatar: data.author.avatar,
                bot: data.author.bot
            },
            message_reference: {
                message_id: data.message_reference != null && Reflect.hasField(data.message_reference, "message_id") ? data.message_reference.message_id : null,
                channel_id: data.message_reference != null && Reflect.hasField(data.message_reference, "channel_id") ? data.message_reference.channel_id : null,
                guild_id: data.message_reference != null && Reflect.hasField(data.message_reference, "guild_id") ? data.message_reference.guild_id : null
            },
            content: data.content,
            timestamp: data.timestamp,
            edited_timestamp: data.edited_timestamp,
            tts: data.tts,
            mention_everyone: data.mention_everyone,
            mentions: data.mentions.map((m) -> {
                return {
                    id: m.id,
                    username: m.username,
                    discriminator: m.discriminator,
                    avatar: m.avatar
                };
            }),
            mention_roles: data.mention_roles,
            mention_channels: data.mention_channels,
            attachments: data.attachments,
            embeds: data.embeds,
            components: data.components
        };
    }

    private function mapToUser(data:Dynamic):User {
        return {
            id: data.id,
            username: data.username,
            discriminator: data.discriminator,
            avatar: data.avatar,
            bot: data.bot,
            email: null,
            verified: false,
            flags: 0,
            banner: null,
            accent_color: null,
            premium_type: 0,
            public_flags: 0
        };
    }

    private function mapToChannel(data:Dynamic):Channel {
        return {
            id: data.id,
            type: data.type,
            guild_id: data.guild_id,
            position: data.position,
            permission_overwrites: data.permission_overwrites,
            name: data.name,
            topic: data.topic,
            nsfw: data.nsfw,
            last_message_id: data.last_message_id,
            bitrate: data.bitrate,
            user_limit: data.user_limit,
            rate_limit_per_user: data.rate_limit_per_user,
            recipients: data.recipients.map(mapToUser),
            recipient_flags: data.recipient_flags,
            icon: data.icon,
            nicks: data.nicks,
            managed: data.managed,
            blocked_user_warning_dismissed: data.blocked_user_warning_dismissed,
            safety_warnings: data.safety_warnings,
            application_id: data.application_id
        };
    }

    private function mapToGuild(data:Dynamic):Guild {
        return {
            id: data.id,
            name: data.name,
            icon: data.icon,
            owner_id: data.owner_id,
            permissions: data.permissions,
            afk_channel_id: data.afk_channel_id,
            afk_timeout: data.afk_timeout,
            banner: data.banner,
            description: data.description,
            preferred_locale: data.preferred_locale,
            region: data.region,
            verification_level: data.verification_level,
            default_message_notifications: data.default_message_notifications,
            explicit_content_filter: data.explicit_content_filter,
            features: data.features,
            mfa_level: data.mfa_level,
            max_presences: data.max_presences,
            max_members: data.max_members,
            premium_tier: data.premium_tier,
            premium_subscription_count: data.premium_subscription_count,
            public_updates_channel_id: data.public_updates_channel_id,
            rules_channel_id: data.rules_channel_id,
            system_channel_id: data.system_channel_id,
            system_channel_flags: data.system_channel_flags,
            widget_enabled: data.widget_enabled,
            widget_channel_id: data.widget_channel_id,
            approximate_member_count: data.approximate_member_count,
            approximate_presence_count: data.approximate_presence_count,
            joined_at: data.joined_at,
            large: data.large,
            unavailable: data.unavailable,
            member_count: data.member_count
        };
    }

    private function mapToThread(data:Dynamic):Thread {
        return {
            id: data.id,
            guild_id: if (Reflect.hasField(data, "guild_id")) data.guild_id else null,
            parent_id: if (Reflect.hasField(data, "parent_id")) data.parent_id else null,
            name: data.name,
            message_count: data.message_count,
            member_count: data.member_count,
            owner_id: if (Reflect.hasField(data, "owner_id")) data.owner_id else null,
            locked: data.locked,
            invitable: data.invitable,
            archive_timestamp: data.archive_timestamp,
            archived: data.archived,
            auto_archive_duration: data.auto_archive_duration,
            create_timestamp: data.create_timestamp,
            applied_tags: data.applied_tags,
            slowmode_delay: if (Reflect.hasField(data, "rate_limit_per_user")) data.rate_limit_per_user else null,
            total_message_sent: if (Reflect.hasField(data, "total_message_sent")) data.total_message_sent else 0
        };
    }

    private function mapToRole(data:Dynamic):Role {
        return {
            id: data.id,
            name: data.name,
            color: data.color,
            hoist: data.hoist,
            position: data.position,
            permissions: data.permissions,
            managed: data.managed,
            mentionable: data.mentionable,
            icon: if (Reflect.hasField(data, "icon")) data.icon else null,
            unicode_emoji: if (Reflect.hasField(data, "unicode_emoji")) data.unicode_emoji else null,
            guild_id: if (Reflect.hasField(data, "guild_id")) data.guild_id else null,
            flags: if (Reflect.hasField(data, "flags")) data.flags else null,
            raw_color: if (Reflect.hasField(data, "raw_color")) data.raw_color else null,
            raw_permissions: if (Reflect.hasField(data, "raw_permissions")) data.raw_permissions else null,
            created_at: if (Reflect.hasField(data, "created_at")) data.created_at else null,
            tags: if (Reflect.hasField(data, "tags")) data.tags else null
        };
    }

    public function clearCache():Void {
        userCache.clear();
        channelCache.clear();
        guildCache.clear();
        rolesCache.clear();
    }
}

enum ActivityType {
    PLAYING;
    STREAMING;
    LISTENING;
    WATCHING;
    CUSTOM;
    COMPETING;
}

enum Status {
    ONLINE;
    DND;
    IDLE;
    INVISIBLE;
}
