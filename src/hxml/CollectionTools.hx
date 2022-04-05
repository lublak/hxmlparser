package hxml;

import haxe.ds.Option;

class CollectionTools {
  public static inline function delete<A>(it:Array<A>, f:(item:A) -> Bool, onlyFirst:Bool = false) {
    if(onlyFirst) {
      for (i in 0...it.length) {
        if(f(it[i])) {
          it.splice(i, 1);
          break;
        }
      }
    } else {
      var offset = 0;
      for (i in 0...it.length) {
        if(f(it[i])) offset++;
        else it[i-offset] = it[i];
      }
      it.splice(it.length-offset, offset);
    }
  }
  public static inline function filterMap<A, T>(it:Array<A>, f:A -> Option<T>):Array<T> {
    var r = [];
    for(v in it) {
      switch f(v) {
        case Some(v): r.push(v);
        case None:
      }
    }
    return r;
  }
  public static function findMap<T, S>(it:Iterable<T>, f:(item:T) -> Option<S>):S {
    for (v in it) {
      switch f(v) {
        case Some(v): return v;
        case None:
      }
    }
    return null;
  }
  public static inline function matchMap<T>(rex:EReg, str:String, f:(item:EReg) -> Option<T>) {
    var r = [];
    while (rex.match(str)) {
      str = rex.matchedRight();
      switch f(rex) {
        case Some(v): r.push(v);
        case None:
      }
    }
    return r;
  }
}