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
    public var onUser:Event<User>;
    public var onChannel:Event<Channel>;

    private var heartbeatInterval:Float = 0;
    private var lastSequence:Null<Float> = null;
    private var ws:Dynamic;
    private var heartbeatTimer:Timer;

    public var intentsMask:Int;
    public var baseUrl:String = "https://discord.com/api/v10";

    public function new(token:String, ?intents:Array<Int>) {
        this.token = token;

        this.onMessage = new Event<Message>();
        this.onReady = new Event<Void>();
        this.onInteraction = new Event<Dynamic>();
        this.onUser = new Event<User>();
        this.onChannel = new Event<Channel>();

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
                        case "USER_UPDATE":
                            var user = mapToUser(d);
                            onUser.dispatch(user);
                        case "CHANNEL_UPDATE":
                            var channel = mapToChannel(d);
                            onChannel.dispatch(channel);
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
        var body = { content: content };
        if (components != null) {
            Reflect.setProperty(body, "components", components);
        }
        if (embeds != null) {
            Reflect.setProperty(body, "embeds", embeds);
        }
        request("PATCH", url, body, (res) -> {
            if (!res.success) {
                Sys.println("Failed to edit message, error: " + res.error);
            }
        });
    }

    public function editReplyMessage(interactionData:Dynamic, content:String, ?components:Array<Dynamic>, ?embeds:Array<Dynamic>):Void {
        var url = baseUrl + "/webhooks/" + interactionData.application_id + "/" + interactionData.token + "/messages/@original";
        var body = { content: content };
        if (components != null) {
            Reflect.setProperty(body, "components", components);
        }
        if (embeds != null) {
            Reflect.setProperty(body, "embeds", embeds);
        }
        request("PATCH", url, body, (res) -> {
            if (!res.success) {
                Sys.println("Failed to edit reply message, error: " + res.error);
            }
        });
    }

    public function fetchUser(userId:String, callback:User->Void):Void {
        var url = baseUrl + "/users/" + userId;
        request("GET", url, null, (res) -> {
            if (res.success) {
                var user = mapToUser(res.data);
                callback(user);
            } else {
                Sys.println("Failed to fetch user: " + res.error);
            }
        });
    }

    public function fetchChannel(channelId:String, callback:Channel->Void):Void {
        var url = baseUrl + "/channels/" + channelId;
        request("GET", url, null, (res) -> {
            if (res.success) {
                var channel = mapToChannel(res.data);
                callback(channel);
            } else {
                Sys.println("Failed to fetch channel: " + res.error);
            }
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
            case "PUT": true;
            case "PATCH": true;
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
