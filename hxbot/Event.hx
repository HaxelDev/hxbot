package hxbot;

typedef Listener<T> = T -> Void;

class Event<T> {
    private var listeners:Array<Listener<T>>;

    public function new() {
        listeners = [];
    }

    public function add(listener:Listener<T>):Void {
        listeners.push(listener);
    }

    public function remove(listener:Listener<T>):Void {
        for (i in 0...listeners.length) {
            if (listeners[i] == listener) {
                listeners.splice(i, 1);
                return;
            }
        }
    }

    public function dispatch(data:T):Void {
        for (listener in listeners) {
            listener(data);
        }
    }

    public function dispatchVoid():Void {
        for (listener in listeners) {
            listener(null);
        }
    }

    public function clear():Void {
        listeners = [];
    }
}
