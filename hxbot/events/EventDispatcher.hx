package hxbot.events;

typedef EventHandler = Dynamic -> Void;

class EventDispatcher {
    private var handlers:Map<String, Array<EventHandler>>;

    public function new() {
        handlers = new Map();
    }

    public function register(event:String, handler:EventHandler):Void {
        if (!handlers.exists(event)) {
            handlers.set(event, new Array());
        }
        handlers.get(event).push(handler);
    }

    public function dispatch(event:String, data:Dynamic):Void {
        if (handlers.exists(event)) {
            for (handler in handlers.get(event)) {
                handler(data);
            }
        }
    }
}
