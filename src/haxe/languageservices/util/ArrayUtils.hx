package haxe.languageservices.util;

class ArrayUtils {
    static public function unique<T>(array:Array<T>):Array<T> {
        var out = new Array<T>();
        for (item in array) if (out.indexOf(item) < 0) out.push(item);
        return out;
    }

    static public function uniqueSorted<T>(array:Array<T>):Array<T> {
        var array = unique(array);
        array.sort(compare);
        return array;
    }

    static private function compare(a:Dynamic, b:Dynamic):Int {
        return if ( a < b ) -1 else if ( a > b ) 1 else 0;
    }
}
