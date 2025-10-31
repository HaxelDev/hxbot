package hxbot;

class Cache<V> {
    private var map:haxe.ds.StringMap<V>;
    private var keyQueue:Array<String>;
    private var maxSize:Int;
    private var ttlMillis:Null<Float>;

    public function new(?maxSize:Int = null, ?ttlMillis:Float = null) {
        this.map = new haxe.ds.StringMap<V>();
        this.keyQueue = [];
        this.maxSize = (maxSize == null ? -1 : maxSize);
        this.ttlMillis = ttlMillis;
    }

    public function get(key:String):Null<V> {
        return map.get(key);
    }

    public function set(key:String, value:V):Void {
        if (map.exists(key)) {
            var idx = keyQueue.indexOf(key);
            if (idx >= 0) keyQueue.splice(idx, 1);
        }
        keyQueue.push(key);

        if (maxSize > 0 && keyQueue.length > maxSize) {
            var oldest = keyQueue.shift();
            if (oldest != null) {
                map.remove(oldest);
            }
        }
        map.set(key, value);

        if (ttlMillis != null) {
            var keyCopy = key;
            haxe.Timer.delay(() -> {
                if (map.exists(keyCopy)) {
                    map.remove(keyCopy);
                    var idx2 = keyQueue.indexOf(keyCopy);
                    if (idx2 >= 0) keyQueue.splice(idx2, 1);
                }
            }, Std.int(ttlMillis));
        }
    }

    public function has(key:String):Bool {
        return map.exists(key);
    }

    public function remove(key:String):Void {
        if (map.exists(key)) {
            map.remove(key);
        }
        var idx = keyQueue.indexOf(key);
        if (idx >= 0) keyQueue.splice(idx, 1);
    }

    public function clear():Void {
        map.clear();
        keyQueue = [];
    }
}
