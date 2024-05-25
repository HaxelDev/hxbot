package hxbot;

import haxe.Json;
import haxe.Timer;
import haxe.ws.WebSocket;
import haxe.ws.Types.MessageType;
import hxbot.events.EventDispatcher;

class Bot {
    public var token:String;
    public var socket:WebSocket;
    public var sequence:Int;

    private var eventDispatcher:EventDispatcher;
    private var heartbeatInterval:Int;

    public function new(token:String) {
        this.token = token;
        this.sequence = 0;
        this.eventDispatcher = new EventDispatcher();
        this.connect();
    }

    public function on(event:String, handler:Dynamic->Void):Void {
        eventDispatcher.register(event, handler);
    }

    public function connect():Void {
        Log.info("Starting connection to Discord Gateway...");

        socket = new WebSocket("wss://gateway.discord.gg/?v=6&encoding=json");
        socket.onmessage = function(type:MessageType) {
            switch (type) {
                case StrMessage(content):
                    haxe.EntryPoint.runInMainThread(onWebSocketMessage.bind(content));
                case BytesMessage(content):
                    // gejlon
            }
        };
        socket.onopen = function() {
            onWebSocketOpen();
        };
        socket.onclose = function() {
            connect();
        }
        socket.onerror = function(error) {
            Log.error("WebSocket error: " + error);
        };

        sys.thread.Thread.readMessage(true);
    }

    private function onWebSocketOpen():Void {
        Log.info("Connected to Discord Gateway.");
        var payload = {
            op: 2,
            d: {
                token: token,
                intents: 513,
                properties: {
                    "$os": "hxbot",
                    "$browser": "hxbot",
                    "$device": "hxbot"
                }
            }
        };
        send(payload);
    }

    private function onWebSocketMessage(message:String):Void {
        var json = Json.parse(message);
        var op:Int = json.op;
        var data:Dynamic = json.d;
        if (op == 10) {
            handleHello(json);
        } else if (op == 11) {
            Log.info("Heartbeat ACK received.");
        } else if (op == 0) {
            handleDispatch(json);
        } else {
            Log.error("Unknown opCode: " + op);
        }
    }

    private function handleHello(json:Dynamic):Void {
        Log.info("Received HELLO event from Discord.");
        this.heartbeatInterval = json.d.heartbeat_interval;
        sendHeartbeat();

        var payload = {
            "op": 2,
            "d": {
                "token": this.token,
                "intents": 513,
                "properties": {
                    "$os": "linux",
                    "$browser": "hxbot",
                    "$device": "desktop"
                }
            }
        };

        send(payload);
        setStatus("online", "Type !help for commands", 3);
    }

    private function handleDispatch(json:Dynamic):Void {
        var eventName = json.t;
        if (eventName == "MESSAGE_CREATE") {
            // jajca
        } else {
            Log.debug("Unhandled event: " + eventName);
        }
    }

    private function sendHeartbeat():Void {
        Timer.delay(function() {
            send({op: 1, d: sequence});
            Log.info("Sent heartbeat.");
            sendHeartbeat();
        }, heartbeatInterval);
    }

    private function send(data:Dynamic):Void {
        var message = Json.stringify(data);
        socket.send(message);
    }

    public function setStatus(status:String, activity:String, activityType:Int):Void {
        var payload = {
            op: 3,
            d: {
                since: null,
                activities: [{
                    name: activity,
                    type: activityType
                }],
                status: status,
                afk: false
            }
        };
        send(payload);
        Log.info("Set bot status to " + status + " with activity: " + activity);
    }
}
