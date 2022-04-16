package hxml;

import haxe.io.Path;

using Lambda;
using StringTools;
using hxml.CollectionTools;

enum abstract Dce(String) {
  var std;
  var full;
  var no;
}

private class VersionTools {
  public static inline function toString(version:Version):String return switch version {
    case Git(url, commit): 'git:$url' + (version == null ? '' : '#$commit');
    case Haxelib(version): version;
  }
}

@:using(hxml.Hxml.VersionTools)
enum Version {
  Git(url:String, ?commit:String);
  Haxelib(version:String);
}

private class HxmlArgumentTools {
  public static inline function toString(arg:HxmlArgument):String return internalToString(arg, false);
  public static inline function toHxmlString(arg:HxmlArgument):String return internalToString(arg, true);
  public static inline function toArgArray(arg:HxmlArgument) {
    return switch arg {
      case CArg(arg): ['--c-arg', arg];
      case ClassPath(path): ['--class-path', path];
      case Cls(cls): [cls];
      case Cmd(command): ['--cmd', command];
      case Connect(port): ['--connect', '$port'];
      case Comment(_): [];
      case Cpp(dir): ['--cpp', dir];
      case Cppia(file): ['--cppia', file];
      case Cs(dir): ['--cs', dir];
      case Cwd(dir): ['--cwd', dir];
      case Dce(dce): ['--dce', cast dce];
      case Debug: ['--debug'];
      case Define(key, value): ['-D', value == null ? key : '$key=$value'];
      case Display: ['--display'];
      case Execute(file): ['-x', file];
      case FlashStrict: ['--flash-strict'];
      case Hl(file): ['--hl', file];
      case Interp: ['--interp'];
      case Java(dir): ['--java', dir];
      case JavaLib(file): ['--java-lib', file];
      case Js(file): ['--js', file];
      case Jvm(file): ['--jvm', file];
      case Library(name, version): ['-L', name + (version == null ? '' : ':${VersionTools.toString(version)}')];
      case Lua(file): ['--lua', file];
      case Macro(code): ['--macro', code];
      case Main(cls): ['--main', cls];
      case Neko(file): ['--neko', file];
      case NetLib(file, name): ['--net-lib', file + (name == null ? '' : '@$name')];
      case NetStd(file): ['--net-std', file];
      case NoInline: ['--no-inline'];
      case NoOpt: ['--no-opt'];
      case NoOutput: ['--no-output'];
      case NoTraces: ['--no-traces'];
      case Php(dir): ['--php', dir];
      case Prompt: ['--prompt'];
      case Python(file): ['--python', file];
      case Remap(pack, target): ['--remap', '$pack:$target'];
      case Resource(file, name): ['-r', file + (name == null ? '' : '@$name')];
      case Run(module, args): ['--run', module].concat(args);
      case Swf(file): ['--swf', file];
      case SwfHeader(header): ['--swf-header', header];
      case SwfLib(lib): ['--swf-lib', lib];
      case SwfLibExtern(lib): ['--swf-lib-extern', lib];
      case SwfVersion(version): ['--swf-version', version];
      case Times: ['--times'];
      case Verbose: ['--verbose'];
      case Wait(port): ['--wait', '$port'];
    };
  }
  public static inline function quoteSpaceArg(val:String) {
    return val.contains(' ') ? '"$val"' : val;
  }
  private static inline function internalToString(arg:HxmlArgument, hxml:Bool = false):String {
    return switch arg {
      case Comment(comment): hxml ? '#$comment' : '';
      case Run(module, args): '--run $module' + (args == null ? '' : (hxml ? args.map(quoteSpaceArg).join('\n') : args.map(quoteSpaceArg).join(' ')));
      default:
        var args = toArgArray(arg);
        if(args.length > 0) {
          var r = [args[0]];
          for (i in 1...args.length) r.push(quoteSpaceArg(args[i]));
          r.join(' ');
        } else '';
    };
  }
}

@:using(hxml.Hxml.HxmlArgumentTools)
enum HxmlArgument {
  CArg(arg:String);
  ClassPath(path:String);
  Cls(cls:String);
  Cmd(command:String);
  Connect(port:Int);
  Comment(comment:String);
  Cpp(dir:String);
  Cppia(file:String);
  Cs(dir:String);
  Cwd(dir:String);
  Dce(dce:Dce);
  Debug;
  Define(key:String, ?value:String);
  Display;
  Execute(file:String);
  FlashStrict;
  Hl(file:String);
  Interp;
  Java(dir:String);
  JavaLib(file:String);
  Js(file:String);
  Jvm(file:String);
  Library(name:String, ?version:Version);
  Lua(file:String);
  Macro(code:String);
  Main(cls:String);
  Neko(file:String);
  NetLib(file:String, ?s:String);
  NetStd(dir:String);
  NoInline;
  NoOpt;
  NoOutput;
  NoTraces;
  Php(dir:String);
  Prompt;
  Python(file:String);
  Remap(pack:String, target:String);
  Resource(file:String, ?name:String);
  Run(module:String, ?args:Array<String>);
  Swf(file:String);
  SwfHeader(header:String);
  SwfLib(lib:String);
  SwfLibExtern(lib:String);
  SwfVersion(version:String);
  Times;
  Verbose;
  Wait(port:Int);
}

abstract Hxml (Array<HxmlArgument>) to Array<HxmlArgument> {
  public inline function new() this = [];
  public static inline function getVersion(v:String):Version {
    if(v.startsWith('git:')) {
      var ci = v.indexOf('#');
      if(ci == null) return Git(v.substring('git:'.length));
      else return Git(v.substring('git:'.length, ci), v.substring(ci+1));
    }
    return Haxelib(v);
  }
  public static inline function getLibraryInfos(l:String):{name:String, ?version:String} {
    var i = l.indexOf(':');
    if(i == -1) return { name: l };
    else return {
      name: l.substring(0, i),
      version: l.substring(i+1)
    };
  }

  public static inline function getRemapInfos(r:String):Null<{pack:String, remap:String}> {
    var i = r.indexOf(':');
    if(i == -1) return null;
    else return {
      pack: r.substring(0, i),
      remap: r.substring(i+1)
    };
  }

  public static inline function getDefineInfos(d:String):{key:String, ?value:String} {
    var i = d.indexOf('=');
    if(i == -1) return { key: d };
    else return {
      key: d.substring(0, i),
      value: d.substring(i+1)
    };
  }

  public static inline function getResourceInfos(r:String):{file:String, ?name:String} {
    var i = r.indexOf('@');
    if(i == -1) return { file: r };
    else return {
      file: r.substring(0, i),
      name: r.substring(i+1)
    };
  }

  public static inline function getNetLibInfos(l:String):{file:String, ?std:String} {
    var i = l.indexOf('@');
    if(i == -1) return { file: l };
    else return {
      file: l.substring(0, i),
      std: l.substring(i+1)
    };
  }

  public static inline function getRunInfos(r:String):{module:String, ?args:Array<String>} {
    var result = ~/[^\s"']+|"([^"]*)"/.matchMap(r, f -> {
      return Some(~/"([^"]*)"/.replace(f.matched(0), '$1'));
    });
    var module = result.shift();
    if(module == null) return null;
    return {
      module: module,
      args: result.length > 0 ? result : null
    };
  }

  public inline function clearTarget() {
    this.delete(f -> switch f {
      case Cpp(_), Cppia(_), Cs(_), Execute(_), Hl(_), Interp, Java(_), Js(_), Jvm(_), Lua(_), Neko(_), Php(_), Python(_), Run(_, _): true;
      default: false;
    });
  }

  public inline function getCArg() return this.filterMap(f -> switch(f) {
    case CArg(arg): Some(arg);
    default: null;
  });
  public inline function addCArg(arg:String) if(!this.exists(f -> switch(f) {
    case CArg(_arg) if(_arg == arg): true;
    default: false;
  })) this.push(CArg(arg));
  public inline function removeCArg(arg:String) this.delete(f -> switch(f) {
    case CArg(_arg) if(_arg == arg): true;
    default: false;
  }, true);
  public inline function removeCArgAll() this.delete(f -> f.match(CArg(_)));

  public inline function getClassPaths() return this.filterMap(f -> switch(f) {
    case ClassPath(path): Some(path);
    default: null;
  });
  public inline function addClassPath(path:String) if(!this.exists(f -> switch(f) {
    case ClassPath(_path) if(_path == path): true;
    default: false;
  })) this.push(ClassPath(path));
  public inline function removeClassPath(path:String) this.delete(f -> switch(f) {
    case ClassPath(_path) if(_path == path): true;
    default: false;
  }, true);
  public inline function removeAllClassPaths() this.delete(f -> f.match(ClassPath(_)));

  public inline function getCmds() return this.filterMap(f -> switch f {
    case Cmd(command): Some(command);
    default: null;
  });
  public inline function addCmd(command:String) if(!this.exists(f -> switch(f) {
    case Cmd(_command) if(_command == command): true;
    default: false;
  })) this.push(Cmd(command));
  public inline function removeCmd(command:String) this.delete(f -> switch(f) {
    case Cmd(_command) if(_command == command): true;
    default: false;
  }, true);
  public inline function removeAllCmds() this.delete(f -> f.match(Cmd(_)));

  public var connect(get, set):Null<Int>;
  private inline function get_connect() return this.findMap(f -> switch(f) {
    case Connect(port): return Some(port);
    default: None;
  });
  private inline function set_connect(port:Null<Int>) {
    if(port == null) {
      this.delete(f -> f.match(Connect(_)));
      return port;
    }
    var i = this.findIndex(f -> f.match(Connect(_)));
    if(i == -1) this.push(Connect(port));
    else this[i] = Connect(port);
    return port;
  }

  public var cpp(get, set):Null<String>;
  private inline function get_cpp() return this.findMap(f -> switch(f) {
    case Cpp(dir): return Some(dir);
    default: None;
  });
  private inline function set_cpp(dir:Null<String>) {
    if(dir == null) {
      this.delete(f -> f.match(Cpp(_)));
      return dir;
    }
    clearTarget();
    this.push(Cpp(dir));
    return dir;
  }

  public var cppia(get, set):Null<String>;
  private inline function get_cppia() return this.findMap(f -> switch(f) {
    case Cppia(file): return Some(file);
    default: None;
  });
  private inline function set_cppia(file:Null<String>) {
    if(file == null) {
      this.delete(f -> f.match(Cppia(_)));
      return file;
    }
    clearTarget();
    this.push(Cppia(file));
    return file;
  }

  public var cs(get, set):Null<String>;
  private inline function get_cs() return this.findMap(f -> switch(f) {
    case Cs(dir): return Some(dir);
    default: None;
  });
  private inline function set_cs(dir:Null<String>) {
    if(dir == null) {
      this.delete(f -> f.match(Cs(_)));
      return dir;
    }
    clearTarget();
    this.push(Cs(dir));
    return dir;
  }

  public inline function getCwds() return this.filterMap(f -> switch f {
    case Cwd(cwd): Some(cwd);
    default: null;
  });
  public inline function addCwd(cwd:String) if(!this.exists(f -> switch(f) {
    case Cwd(_cwd) if(_cwd == cwd): true;
    default: false;
  })) this.push(Cmd(cwd));
  public inline function removeCwd(cwd:String) this.delete(f -> switch(f) {
    case Cwd(_cwd) if(_cwd == cwd): true;
    default: false;
  }, true);
  public inline function removeAllCwds() this.delete(f -> f.match(Cwd(_)));

  public var dce(get, set):Null<Dce>;
  private inline function get_dce() return this.findMap(f -> switch(f) {
    case Dce(d): return Some(d);
    default: None;
  });
  private inline function set_dce(dce:Null<Dce>) {
    if(dce == null) {
      this.delete(f -> f.match(Dce(_)));
      return dce;
    }
    var i = this.findIndex(f -> f.match(Dce(_)));
    if(i == -1) this.push(Dce(dce));
    else this[i] = Dce(dce);
    return dce;
  }

  public var debug(get, set):Bool;
  private inline function get_debug() return this.exists(f -> switch(f) {
    case Debug: return true;
    default: false;
  });
  private inline function set_debug(debug:Bool) {
    if(debug) if(!this.exists(f -> f.match(Debug))) this.push(Debug);
    else this.delete(f -> f.match(Debug), true);
    return debug;
  }

  public inline function getDefines() return this.filterMap(f -> switch(f) {
    case Define(key, value): Some({key: key, value: value});
    default: null;
  });
  public inline function getDefine(key:String) return this.findMap(f -> switch(f) {
    case Define(_key, value) if(_key == key): Some(value);
    default: null;
  });
  public inline function setDefine(key:String, value:String) {
    var i = this.findIndex(f -> switch(f) {
      case Define(_key, _) if(_key == key): true;
      default: false;
    });
    if(i == -1) this.push(Define(key, value));
    else this[i] = Define(key, value);
  }
  public inline function setDefineFlag(key:String, value:Bool) {
    if(value) {
      var i = this.findIndex(f -> switch(f) {
        case Define(_key, _) if(_key == key): true;
        default: false;
      });
      if(i == -1) this.push(Define(key));
      else this[i] = Define(key);
    } else this.delete(f -> switch(f) {
      case Define(_key, _) if(_key == key): true;
      default: false;
    }, true);
  }
  public inline function removeAllDefines() this.delete(f -> f.match(Define(_, _)));

  public var display(get, set):Bool;
  private inline function get_display() return this.exists(f -> switch(f) {
    case Display: return true;
    default: false;
  });
  private inline function set_display(display:Bool) {
    if(display) if(!this.exists(f -> f.match(Display))) this.push(Display);
    else this.delete(f -> f.match(Display), true);
    return display;
  }

  public var execute(get, set):Null<String>;
  private inline function get_execute() return this.findMap(f -> switch(f) {
    case Execute(d): return Some(d);
    default: None;
  });
  private inline function set_execute(x:Null<String>) {
    if(x == null) {
      this.delete(f -> f.match(Execute(_)));
      return x;
    }
    clearTarget();
    this.push(Execute(x));
    return x;
  }

  public var flashStrict(get, set):Bool;
  private inline function get_flashStrict() return this.exists(f -> switch(f) {
    case FlashStrict: return true;
    default: false;
  });
  private inline function set_flashStrict(flashStrict:Bool) {
    if(flashStrict) if(!this.exists(f -> f.match(FlashStrict))) this.push(FlashStrict);
    else this.delete(f -> f.match(FlashStrict), true);
    return flashStrict;
  }

  public var hl(get, set):Null<String>;
  private inline function get_hl() return this.findMap(f -> switch(f) {
    case Hl(file): return Some(file);
    default: None;
  });
  private inline function set_hl(file:Null<String>) {
    if(file == null) {
      this.delete(f -> f.match(Hl(_)));
      return file;
    }
    clearTarget();
    this.push(Hl(file));
    return file;
  }

  public var interp(get, set):Bool;
  private inline function get_interp() return this.exists(f -> switch(f) {
    case Interp: return true;
    default: false;
  });
  private inline function set_interp(interp:Bool) {
    if(interp) if(!this.exists(f -> f.match(Interp))) this.push(Interp);
    else this.delete(f -> f.match(Interp), true);
    return interp;
  }

  public var java(get, set):Null<String>;
  private inline function get_java() return this.findMap(f -> switch(f) {
    case Java(dir): return Some(dir);
    default: None;
  });
  private inline function set_java(dir:Null<String>) {
    if(dir == null) {
      this.delete(f -> f.match(Java(_)));
      return dir;
    }
    clearTarget();
    this.push(Java(dir));
    return dir;
  }

  public inline function getJavaLibs() return this.filterMap(f -> switch f {
    case JavaLib(file): Some(file);
    default: null;
  });
  public inline function addJavaLib(file:String) if(!this.exists(f -> switch(f) {
    case JavaLib(_file) if(_file == file): true;
    default: false;
  })) this.push(JavaLib(file));
  public inline function removeJavaLib(file:String) this.delete(f -> switch(f) {
    case JavaLib(_file) if(_file == file): true;
    default: false;
  }, true);
  public inline function removeAllJavaLibs() this.delete(f -> f.match(JavaLib(_)));

  public var js(get, set):Null<String>;
  private inline function get_js() return this.findMap(f -> switch(f) {
    case Js(file): return Some(file);
    default: None;
  });
  private inline function set_js(file:Null<String>) {
    if(file == null) {
      this.delete(f -> f.match(Js(_)));
      return file;
    }
    clearTarget();
    this.push(Js(file));
    return file;
  }

  public var jvm(get, set):Null<String>;
  private inline function get_jvm() return this.findMap(f -> switch(f) {
    case Jvm(file): return Some(file);
    default: None;
  });
  private inline function set_jvm(file:Null<String>) {
    if(file == null) {
      this.delete(f -> f.match(Jvm(_)));
      return file;
    }
    clearTarget();
    this.push(Jvm(file));
    return file;
  }

  public inline function getLibrarys() return this.filterMap(f -> switch f {
    case Library(name, version): Some(name + (version == null ? '' : ':${VersionTools.toString(version)}'));
    default: None;
  });
  public inline function addLibrary(name:String, ?version:String) {
    var i = this.findIndex(f -> switch f {
      case Library(name, _) if(name == name): true;
      default: false;
    });
    if(i == -1) this.push(Library(name, getVersion(version)));
    else this[i] = Library(name, getVersion(version));
  }
  public inline function removeLibrary(name:String) {
    this.delete(f -> switch f {
      case Library(name, _) if(name == name): true;
      default: false;
    });
  }
  public inline function removeAllLibrarys() this.delete(f -> f.match(Library(_, _)));

  public var lua(get, set):Null<String>;
  private inline function get_lua() return this.findMap(f -> switch(f) {
    case Lua(file): return Some(file);
    default: None;
  });
  private inline function set_lua(file:Null<String>) {
    if(file == null) {
      this.delete(f -> f.match(Lua(_)));
      return file;
    }
    clearTarget();
    this.push(Lua(file));
    return file;
  }

  public inline function getMacros() return this.filterMap(f -> switch f {
    case Macro(code): Some(code);
    default: null;
  });
  public inline function addMacro(code:String) if(!this.exists(f -> switch(f) {
    case Macro(_code) if(_code == code): true;
    default: false;
  })) this.push(Cmd(code));
  public inline function removeMacro(code:String) this.delete(f -> switch(f) {
    case Macro(_code) if(_code == code): true;
    default: false;
  }, true);
  public inline function removeAllMacros() this.delete(f -> f.match(Macro(_)));

  public var main(get, set):Null<String>;
  private inline function get_main() return this.findMap(f -> switch(f) {
    case Main(d): return Some(d);
    default: None;
  });
  private inline function set_main(main:Null<String>) {
    if(main == null) {
      this.delete(f -> f.match(Main(_)));
      return main;
    }
    var i = this.findIndex(f -> f.match(Main(_)));
    if(i == -1) this.push(Main(main));
    else this[i] = Main(main);
    return main;
  }

  public var neko(get, set):Null<String>;
  private inline function get_neko() return this.findMap(f -> switch(f) {
    case Neko(file): return Some(file);
    default: None;
  });
  private inline function set_neko(file:Null<String>) {
    if(file == null) {
      this.delete(f -> f.match(Neko(_)));
      return file;
    }
    clearTarget();
    this.push(Neko(file));
    return file;
  }

  public inline function getNetLibs() return this.filterMap(f -> switch f {
    case NetLib(file, s): Some(file + (s == null ? '' : '@$s'));
    default: null;
  });
  public inline function addNetLib(file:String, s:String) {
    if(!this.exists(f -> switch(f) {
      case NetLib(_file, _s) if(_file == file && _s == s): true;
      default: false;
    })) this.push(NetLib(file, s));
  }
  public inline function removeNetLib(file:String) this.delete(f -> switch(f) {
    case NetLib(_file) if(_file == file): true;
    default: false;
  }, true);
  public inline function removeAllNetLibs() this.delete(f -> f.match(NetLib(_)));

  public inline function getNetStds() return this.filterMap(f -> switch f {
    case NetStd(dir): Some(dir);
    default: null;
  });
  public inline function addNetStd(dir:String) if(!this.exists(f -> switch(f) {
    case NetStd(_dir) if(_dir == dir): true;
    default: false;
  })) this.push(NetStd(dir));
  public inline function removeNetStd(dir:String) this.delete(f -> switch(f) {
    case NetStd(_dir) if(_dir == dir): true;
    default: false;
  }, true);
  public inline function removeAllNetStds() this.delete(f -> f.match(NetStd(_)));

  public var noInline(get, set):Bool;
  private inline function get_noInline() return this.exists(f -> switch(f) {
    case NoInline: return true;
    default: false;
  });
  private inline function set_noInline(noInline:Bool) {
    if(noInline) if(!this.exists(f -> f.match(NoInline))) this.push(NoInline);
    else this.delete(f -> f.match(NoInline), true);
    return noInline;
  }

  public var noOpt(get, set):Bool;
  private inline function get_noOpt() return this.exists(f -> switch(f) {
    case NoOpt: return true;
    default: false;
  });
  private inline function set_noOpt(noOpt:Bool) {
    if(noOpt) if(!this.exists(f -> f.match(NoOpt))) this.push(NoOpt);
    else this.delete(f -> f.match(NoOpt), true);
    return noOpt;
  }

  public var noOutput(get, set):Bool;
  private inline function get_noOutput() return this.exists(f -> switch(f) {
    case NoOutput: return true;
    default: false;
  });
  private inline function set_noOutput(noOutput:Bool) {
    if(noOutput) if(!this.exists(f -> f.match(NoOutput))) this.push(NoOutput);
    else this.delete(f -> f.match(NoOutput), true);
    return noOutput;
  }

  public var noTraces(get, set):Bool;
  private inline function get_noTraces() return this.exists(f -> switch(f) {
    case NoTraces: return true;
    default: false;
  });
  private inline function set_noTraces(noTraces:Bool) {
    if(noTraces) if(!this.exists(f -> f.match(NoTraces))) this.push(NoTraces);
    else this.delete(f -> f.match(NoTraces), true);
    return noTraces;
  }

  public var php(get, set):Null<String>;
  private inline function get_php() return this.findMap(f -> switch(f) {
    case Php(dir): return Some(dir);
    default: None;
  });
  private inline function set_php(dir:Null<String>) {
    if(dir == null) {
      this.delete(f -> f.match(Php(_)));
      return dir;
    }
    clearTarget();
    this.push(Php(dir));
    return dir;
  }

  public var prompt(get, set):Bool;
  private inline function get_prompt() return this.exists(f -> switch(f) {
    case Prompt: return true;
    default: false;
  });
  private inline function set_prompt(prompt:Bool) {
    if(prompt) if(!this.exists(f -> f.match(Prompt))) this.push(Prompt);
    else this.delete(f -> f.match(Prompt), true);
    return prompt;
  }

  public var python(get, set):Null<String>;
  private inline function get_python() return this.findMap(f -> switch(f) {
    case Python(file): return Some(file);
    default: None;
  });
  private inline function set_python(file:Null<String>) {
    if(file == null) {
      this.delete(f -> f.match(Python(_)));
      return file;
    }
    clearTarget();
    this.push(Python(file));
    return file;
  }

  public inline function getRemaps() return this.filterMap(f -> switch(f) {
    case Remap(pack, remap): Some({pack: pack, remap: remap});
    default: null;
  });
  public inline function getRemap(pack:String) return this.filterMap(f -> switch(f) {
    case Remap(_pack, remap) if(_pack == pack): Some(remap);
    default: null;
  });
  public inline function setRemap(pack:String, remap:Null<String>) {
    if(remap == null) {
      this.delete(f -> switch(f) {
        case Remap(_pack, _) if(_pack == pack): true;
        default: false;
      }, true);
    } else {
      var i = this.findIndex(f -> switch(f) {
        case Remap(_pack, _) if(_pack == pack): true;
        default: false;
      });
      if(i == -1) this.push(Remap(pack, remap));
      else this[i] = Remap(pack, remap);
    }
  }
  public inline function removeAllRemaps() this.delete(f -> f.match(Remap(_, _)));

  public inline function getResources() return this.filterMap(f -> switch f {
    case Resource(file, name): Some({file: file, name: name});
    default: None;
  });
  public inline function getResource(name:String) return this.findMap(f -> switch f {
    case Resource(file, _name) if(_name == null ? Path.withoutExtension(Path.withoutDirectory(file)) == name: _name == name): Some({file: file, name: name});
    default: None;
  });
  public inline function addResource(file:String, ?name:String) {
    var name = name == null ? Path.withoutExtension(Path.withoutDirectory(file)) : name;
    var i = this.findIndex(f -> switch f {
      case Resource(_, _name) if(_name == name): true;
      default: false;
    });
    if(i == -1) this.push(Resource(file, name));
    else this[i] = Resource(file, name);
  }
  public inline function removeResource(name:String) {
    this.delete(f -> switch f {
      case Resource(file, _name) if(_name == null ? Path.withoutExtension(Path.withoutDirectory(file)) == name: _name == name): true;
      default: false;
    });
  }
  public inline function removeAllResources() this.delete(f -> f.match(Resource(_, _)));

  public var run(get, set):Null<String>;
  private inline function get_run() return this.findMap(f -> switch(f) {
    case Run(module, args): return Some(module + (args != null && args.length > 0 ? ' ${args.map(HxmlArgumentTools.quoteSpaceArg).join(' ')}' : ''));
    default: None;
  });
  private inline function set_run(run:Null<String>) {
    if(run == null) {
      this.delete(f -> f.match(Run(_, _)));
      return run;
    }
    var i = this.findIndex(f -> switch(f) {
      case Run(_, _): true;
      default: false;
    });
    var infos = getRunInfos(run);
    if(infos != null) {
      if(i == -1) this.push(Run(infos.module, infos.args));
      else this[i] = Run(infos.module, infos.args);
    }
    return run;
  }

  public inline function getRun() return this.findMap(f -> switch f {
    case Run(module, args): Some({module: module, args: args});
    default: None;
  });
  public inline function setRun(module:String, args:Array<String>) {
    var i = this.findIndex(f -> switch(f) {
      case Run(_, _): true;
      default: false;
    });
    if(i == -1) this.push(Run(module, args));
    else this[i] = Run(module, args);
  }
  public inline function removeRun() this.delete(f -> switch f {
    case Run(_, _): true;
    default: false;
  }, true);

  public var swf(get, set):Null<String>;
  private inline function get_swf() return this.findMap(f -> switch(f) {
    case Swf(file): return Some(file);
    default: None;
  });
  private inline function set_swf(file:Null<String>) {
    if(file == null) {
      this.delete(f -> f.match(Swf(_)));
      return file;
    }
    clearTarget();
    this.push(Swf(file));
    return file;
  }

  public inline function getSwfHeaders() return this.filterMap(f -> switch(f) {
    case SwfHeader(header): Some(header);
    default: null;
  });
  public inline function addSwfHeader(header:String) if(!this.exists(f -> switch(f) {
    case SwfHeader(_header) if(_header == header): true;
    default: false;
  })) this.push(SwfHeader(header));
  public inline function removeSwfHeader(header:String) this.delete(f -> switch(f) {
    case SwfHeader(_header) if(_header == header): true;
    default: false;
  }, true);
  public inline function removeAllSwfHeaders() this.delete(f -> f.match(SwfHeader(_)));

  public inline function getSwfLibs() return this.filterMap(f -> switch f {
    case SwfLib(file): Some(file);
    default: null;
  });
  public inline function addSwfLib(file:String) if(!this.exists(f -> switch(f) {
    case SwfLib(_file) if(_file == file): true;
    default: false;
  })) this.push(SwfLib(file));
  public inline function removeSwfLib(file:String) this.delete(f -> switch(f) {
    case SwfLib(_file) if(_file == file): true;
    default: false;
  }, true);
  public inline function removeAllSwfLibs() this.delete(f -> f.match(SwfLib(_)));

  public inline function getSwfLibExterns() return this.filterMap(f -> switch f {
    case SwfLibExtern(file): Some(file);
    default: null;
  });
  public inline function addSwfLibExtern(file:String) if(!this.exists(f -> switch(f) {
    case SwfLibExtern(_file) if(_file == file): true;
    default: false;
  })) this.push(SwfLibExtern(file));
  public inline function removeSwfLibExtern(file:String) this.delete(f -> switch(f) {
    case SwfLibExtern(_file) if(_file == file): true;
    default: false;
  }, true);
  public inline function removeAllSwfLibExterns() this.delete(f -> f.match(SwfLibExtern(_)));

  public var swfVersion(get, set):Null<String>;
  private inline function get_swfVersion() return this.findMap(f -> switch(f) {
    case SwfVersion(d): return Some(d);
    default: None;
  });
  private inline function set_swfVersion(swfVersion:Null<String>) {
    if(swfVersion == null) {
      this.delete(f -> f.match(SwfVersion(_)));
      return swfVersion;
    }
    var i = this.findIndex(f -> f.match(SwfVersion(_)));
    if(i == -1) this.push(SwfVersion(swfVersion));
    else this[i] = SwfVersion(swfVersion);
    return swfVersion;
  }

  public var times(get, set):Bool;
  private inline function get_times() return this.exists(f -> switch(f) {
    case Times: return true;
    default: false;
  });
  private inline function set_times(times:Bool) {
    if(times) if(!this.exists(f -> f.match(Times))) this.push(Times);
    else this.delete(f -> f.match(Times), true);
    return times;
  }

  public var verbose(get, set):Bool;
  private inline function get_verbose() return this.exists(f -> switch(f) {
    case Verbose: return true;
    default: false;
  });
  private inline function set_verbose(verbose:Bool) {
    if(verbose) if(!this.exists(f -> f.match(Verbose))) this.push(Verbose);
    else this.delete(f -> f.match(Verbose), true);
    return verbose;
  }

  public var wait(get, set):Null<Int>;
  private inline function get_wait() return this.findMap(f -> switch(f) {
    case Wait(port): return Some(port);
    default: None;
  });
  private inline function set_wait(port:Null<Int>) {
    if(port == null) {
      this.delete(f -> f.match(Wait(_)));
      return port;
    }
    var i = this.findIndex(f -> f.match(Wait(_)));
    if(i == -1) this.push(Wait(port));
    else  this[i] = Wait(port);
    return port;
  }

  public inline function getClasses() return this.filterMap(f -> switch(f) {
    case Cls(cls): Some(cls);
    default: null;
  });
  public inline function addClass(cls:String) if(!this.exists(f -> switch(f) {
    case Cls(_cls) if(_cls == cls): true;
    default: false;
  })) this.push(Cls(cls));
  public inline function removeClass(cls:String) this.delete(f -> switch(f) {
    case Cls(_cls) if(_cls == cls): true;
    default: false;
  }, true);
  public inline function removeAllClasses() this.delete(f -> f.match(Cls(_)));

  public inline function getComments() return this.filterMap(f -> switch(f) {
    case Comment(comment): Some(comment);
    default: null;
  });
  public inline function addComment(comment:String) this.push(Comment(comment));
  public inline function removeComment(comment:String, onlyFirst:Bool = false) this.delete(f -> switch(f) {
    case Cls(_comment) if(_comment == comment): true;
    default: false;
  }, onlyFirst);
  public inline function removeAllComments() this.delete(f -> f.match(Comment(_)));
  
  public inline function set(name:String, ?args:String) {
    if(name.startsWith('#')) {
      if(args == null) addComment(name.substring(1));
      else addComment('${name.substring(1)} $args');
    } else if(name == '--run') {
      if(args == null) setByArgArray([name]);
      else setByArgArray([name].concat(~/[^\s"']+|"([^"]*)"/.matchMap(args, f -> {
        return Some(~/"([^"]*)"/.replace(f.matched(0), '$1'));
      })));
    } else if(args == null) setByArgArray([name]);
    else setByArgArray([name, args]);
  }

  public inline function setByArgArray(arr:Array<String>) {
    var i = 0;
    while (i < arr.length) {
      switch arr[i] {
        case '--no-output': noOutput = true;
        case '--interp': interp = true;
        case '-v', '--verbose': verbose = true;
        case '--debug': debug = true;
        case '--prompt': prompt = true;
        case '--no-traces': noTraces = true;
        case '--display': display = true;
        case '--times': times = true;
        case '--no-inline': noInline = true;
        case '--no-opt': noOpt = true;
        case '--flash-strict': flashStrict = true;
        case '--run':
          setRun(arr[i], arr.slice(i+1));
          i = arr.length;
        case '-p', '-cp', '--class-path': addClassPath(arr[++i]);
        case '-L', '--library': addLibrary(arr[++i]);
        case '-m', '--main': main = arr[++i];
        case '-D':
          var infos = getDefineInfos(arr[++i]);
          setDefine(infos.key, infos.value);
        case '--js': js = arr[++i];
        case '--swf': swf = arr[++i];
        case '--neko': neko = arr[++i];
        case '--php': php = arr[++i];
        case '--cpp': cpp = arr[++i];
        case '--cs': cs = arr[++i];
        case '--java': java = arr[++i];
        case '--jvm': jvm = arr[++i];
        case '--python': python = arr[++i];
        case '--lua': lua = arr[++i];
        case '--hl': hl = arr[++i];
        case '--cppia': cppia = arr[++i];
        case '--x': execute = arr[++i];
        case '--dce': switch arr[++i] {
          case 'no': dce = no;
          case 'full': dce = full;
          case 'std': dce = std;
        }
        case '--cmd': addCmd(arr[++i]);
        case '--remap':
          var infos = getRemapInfos(arr[++i]);
          setRemap(infos.pack, infos.remap);
        case '-r', '--resource':
          var infos = getResourceInfos(arr[++i]);
          addResource(infos.name, infos.name);
        case '--macro': addMacro(arr[++i]);
        case '--wait': wait = Std.parseInt(arr[++i]);
        case '--connect': connect = Std.parseInt(arr[++i]);
        case '-C', '--cwd': addCwd(arr[++i]);
        case '--swf-version': swfVersion = arr[++i];
        case '--swf-header': addSwfHeader(arr[++i]);
        case '--swf-lib': addSwfLib(arr[++i]);
        case '--swf-lib-extern': addSwfLibExtern(arr[++i]);
        case '--java-lib': addJavaLib(arr[++i]);
        case '--net-lib':
          var infos = getNetLibInfos(arr[++i]);
          addNetLib(infos.file, infos.std);
        case '--net-std': addNetStd(arr[++i]);
        case '--c-arg': addCArg(arr[++i]);
        case e if(!e.startsWith('-')): addClass(e);
      }
      i++;
    }
  }

  public inline function copy():Null<Hxml> return cast this.copy();

  public var length(get, never):Null<Int>;
  private inline function get_length() return this.length;

  public static inline function parseArgs(content:String):Hxml {
    var hxml = new Hxml();
    hxml.setByArgArray(~/[^\s"']+|"([^"]*)"/.matchMap(content, f -> {
      return Some(~/"([^"]*)"/.replace(f.matched(0), '$1'));
    }));
    return hxml;
  }
  
  public static inline function parseHXML(content:String):Array<Hxml> {
    var result:Array<Hxml> = [];
    var hxml = new Hxml();
    var each:Hxml = null;
    var lines = ~/(\r\n|\r|\n)/g.split(content);
    var i = 0;
    while(i < lines.length) {
      var line = lines[i];
      if(line == '--next') {
        result.push(hxml);
        hxml = each == null ? new Hxml() : each.copy();
      }
      else if(line == '--each') each = hxml;
      else if(line.startsWith('--run')) {
        var r = line.substring('--run '.length);
        var t = [];
        i++;
        while(i < lines.length) {
          t.push(lines[i]);
          i++;
        }
        hxml.setRun(r, t);
      } else {
        var si = line.indexOf(' ');
        if(si == -1) hxml.set(line);
        else hxml.set(line.substring(0, si), line.substring(si+1));
      }
      i++;
    }

    if(hxml.length > 0) result.push(hxml);

    return result;
  }
  @:to public inline function toString() this.map(HxmlArgumentTools.toString).join(' ');
  public inline function toHXML() return this.map(HxmlArgumentTools.toHxmlString).join('\n');
  public inline function toArgs() return this.map(HxmlArgumentTools.toArgArray).flatten();
}