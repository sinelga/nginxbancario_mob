import "dart:isolate" as l;import "dart:html" as q;import "dart:async" as MB;import "dart:mirrors" as SC;class TC{static const  UC="Chrome";final  JC;final  minimumVersion;const TC(this.JC,[this.minimumVersion]);}class VC{const VC();}class WC{final  name;const WC(this.name);}class XC{const XC();}class YC{const YC();}var HB; main(){var v=zB(uri:"http://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20rss%20where%20url%20%3D%20%22http%3A%2F%2Fquotidianohome.feedsportal.com%2Fc%2F33327%2Ff%2F565662%2Findex.rss%22&format=json&diagnostics=true&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys&callback=?");v.then(( o){HB=new List<RB>();var h=o["query"]["results"]["item"];for(var g=0;g<h.length;g++ ){var i=new RB();i.title=h[g]["title"];i.OC=h[g]["link"];i.PC=h[g]["pubDate"];var k=h[g]["description"];var GB=k.indexOf('<img')!=-1;if(GB){var QC=k.indexOf('<img');i.description=k.substring(0,QC);}HB.add(i);}bB(o);var gC=q.query("#rssfeed").text;var j=new StringBuffer();for(int g=0;g<HB.length;g++ ){j.write("<div class=\"well\">");j.writeln(HB[g].title);j.write("</div>");}var RC=q.query('#rssfeed');RC.innerHtml=j.toString();});}class RB{var title,OC,description,PC;}final hB=r"""
(function() {
  // Proxy support for js.dart.

  var globalContext = window;

  // Support for binding the receiver (this) in proxied functions.
  function bindIfFunction(f, _this) {
    if (typeof(f) != "function") {
      return f;
    } else {
      return new BoundFunction(_this, f);
    }
  }

  function unbind(obj) {
    if (obj instanceof BoundFunction) {
      return obj.object;
    } else {
      return obj;
    }
  }

  function getBoundThis(obj) {
    if (obj instanceof BoundFunction) {
      return obj._this;
    } else {
      return globalContext;
    }
  }

  function BoundFunction(_this, object) {
    this._this = _this;
    this.object = object;
  }

  // Table for local objects and functions that are proxied.
  function ProxiedObjectTable() {
    // Name for debugging.
    this.name = 'js-ref';

    // Table from IDs to JS objects.
    this.map = {};

    // Generator for new IDs.
    this._nextId = 0;

    // Counter for deleted proxies.
    this._deletedCount = 0;

    // Flag for one-time initialization.
    this._initialized = false;

    // Ports for managing communication to proxies.
    this.port = new ReceivePortSync();
    this.sendPort = this.port.toSendPort();

    // Set of IDs that are global.
    // These will not be freed on an exitScope().
    this.globalIds = {};

    // Stack of scoped handles.
    this.handleStack = [];

    // Stack of active scopes where each value is represented by the size of
    // the handleStack at the beginning of the scope.  When an active scope
    // is popped, the handleStack is restored to where it was when the
    // scope was entered.
    this.scopeIndices = [];
  }

  // Number of valid IDs.  This is the number of objects (global and local)
  // kept alive by this table.
  ProxiedObjectTable.prototype.count = function () {
    return Object.keys(this.map).length;
  }

  // Number of total IDs ever allocated.
  ProxiedObjectTable.prototype.total = function () {
    return this.count() + this._deletedCount;
  }

  // Adds an object to the table and return an ID for serialization.
  ProxiedObjectTable.prototype.add = function (obj) {
    if (this.scopeIndices.length == 0) {
      throw "Cannot allocate a proxy outside of a scope.";
    }
    // TODO(vsm): Cache refs for each obj?
    var ref = this.name + '-' + this._nextId++;
    this.handleStack.push(ref);
    this.map[ref] = obj;
    return ref;
  }

  ProxiedObjectTable.prototype._initializeOnce = function () {
    if (!this._initialized) {
      this._initialize();
      this._initialized = true;
    }
  }

  // Enters a new scope for this table.
  ProxiedObjectTable.prototype.enterScope = function() {
    this._initializeOnce();
    this.scopeIndices.push(this.handleStack.length);
  }

  // Invalidates all non-global IDs in the current scope and
  // exit the current scope.
  ProxiedObjectTable.prototype.exitScope = function() {
    var start = this.scopeIndices.pop();
    for (var i = start; i < this.handleStack.length; ++i) {
      var key = this.handleStack[i];
      if (!this.globalIds.hasOwnProperty(key)) {
        delete this.map[this.handleStack[i]];
        this._deletedCount++;
      }
    }
    this.handleStack = this.handleStack.splice(0, start);
  }

  // Makes this ID globally scope.  It must be explicitly invalidated.
  ProxiedObjectTable.prototype.globalize = function(id) {
    this.globalIds[id] = true;
  }

  // Invalidates this ID, potentially freeing its corresponding object.
  ProxiedObjectTable.prototype.invalidate = function(id) {
    var old = this.get(id);
    delete this.globalIds[id];
    delete this.map[id];
    this._deletedCount++;
  }

  // Gets the object or function corresponding to this ID.
  ProxiedObjectTable.prototype.get = function (id) {
    if (!this.map.hasOwnProperty(id)) {
      throw 'Proxy ' + id + ' has been invalidated.'
    }
    return this.map[id];
  }

  ProxiedObjectTable.prototype._initialize = function () {
    // Configure this table's port to forward methods, getters, and setters
    // from the remote proxy to the local object.
    var table = this;

    this.port.receive(function (message) {
      // TODO(vsm): Support a mechanism to register a handler here.
      try {
        var object = table.get(message[0]);
        var receiver = unbind(object);
        var member = message[1];
        var kind = message[2];
        var args = message[3].map(deserialize);
        if (kind == 'get') {
          // Getter.
          var field = member;
          if (field in receiver && args.length == 0) {
            var result = bindIfFunction(receiver[field], receiver);
            return [ 'return', serialize(result) ];
          }
        } else if (kind == 'set') {
          // Setter.
          var field = member;
          if (args.length == 1) {
            return [ 'return', serialize(receiver[field] = args[0]) ];
          }
        } else if (kind == 'apply') {
          // Direct function invocation.
          var _this = getBoundThis(object);
          return [ 'return', serialize(receiver.apply(_this, args)) ];
        } else if (member == '[]' && args.length == 1) {
          // Index getter.
          var result = bindIfFunction(receiver[args[0]], receiver);
          return [ 'return', serialize(result) ];
        } else if (member == '[]=' && args.length == 2) {
          // Index setter.
          return [ 'return', serialize(receiver[args[0]] = args[1]) ];
        } else {
          // Member function invocation.
          var f = receiver[member];
          if (f) {
            var result = f.apply(receiver, args);
            return [ 'return', serialize(result) ];
          }
        }
        return [ 'none' ];
      } catch (e) {
        return [ 'throws', e.toString() ];
      }
    });
  }

  // Singleton for local proxied objects.
  var proxiedObjectTable = new ProxiedObjectTable();

  // DOM element serialization code.
  var _localNextElementId = 0;
  var _DART_ID = 'data-dart_id';
  var _DART_TEMPORARY_ATTACHED = 'data-dart_temporary_attached';

  function serializeElement(e) {
    // TODO(vsm): Use an isolate-specific id.
    var id;
    if (e.hasAttribute(_DART_ID)) {
      id = e.getAttribute(_DART_ID);
    } else {
      id = (_localNextElementId++).toString();
      e.setAttribute(_DART_ID, id);
    }
    if (e !== document.documentElement) {
      // Element must be attached to DOM to be retrieve in js part.
      // Attach top unattached parent to avoid detaching parent of "e" when
      // appending "e" directly to document. We keep count of elements
      // temporarily attached to prevent detaching top unattached parent to
      // early. This count is equals to the length of _DART_TEMPORARY_ATTACHED
      // attribute. There could be other elements to serialize having the same
      // top unattached parent.
      var top = e;
      while (true) {
        if (top.hasAttribute(_DART_TEMPORARY_ATTACHED)) {
          var oldValue = top.getAttribute(_DART_TEMPORARY_ATTACHED);
          var newValue = oldValue + "a";
          top.setAttribute(_DART_TEMPORARY_ATTACHED, newValue);
          break;
        }
        if (top.parentNode == null) {
          top.setAttribute(_DART_TEMPORARY_ATTACHED, "a");
          document.documentElement.appendChild(top);
          break;
        }
        if (top.parentNode === document.documentElement) {
          // e was already attached to dom
          break;
        }
        top = top.parentNode;
      }
    }
    return id;
  }

  function deserializeElement(id) {
    // TODO(vsm): Clear the attribute.
    var list = document.querySelectorAll('[' + _DART_ID + '="' + id + '"]');

    if (list.length > 1) throw 'Non unique ID: ' + id;
    if (list.length == 0) {
      throw 'Element must be attached to the document: ' + id;
    }
    var e = list[0];
    if (e !== document.documentElement) {
      // detach temporary attached element
      var top = e;
      while (true) {
        if (top.hasAttribute(_DART_TEMPORARY_ATTACHED)) {
          var oldValue = top.getAttribute(_DART_TEMPORARY_ATTACHED);
          var newValue = oldValue.substring(1);
          top.setAttribute(_DART_TEMPORARY_ATTACHED, newValue);
          // detach top only if no more elements have to be unserialized
          if (top.getAttribute(_DART_TEMPORARY_ATTACHED).length === 0) {
            top.removeAttribute(_DART_TEMPORARY_ATTACHED);
            document.documentElement.removeChild(top);
          }
          break;
        }
        if (top.parentNode === document.documentElement) {
          // e was already attached to dom
          break;
        }
        top = top.parentNode;
      }
    }
    return e;
  }


  // Type for remote proxies to Dart objects.
  function DartProxy(id, sendPort) {
    this.id = id;
    this.port = sendPort;
  }

  // Serializes JS types to SendPortSync format:
  // - primitives -> primitives
  // - sendport -> sendport
  // - DOM element -> [ 'domref', element-id ]
  // - Function -> [ 'funcref', function-id, sendport ]
  // - Object -> [ 'objref', object-id, sendport ]
  function serialize(message) {
    if (message == null) {
      return null;  // Convert undefined to null.
    } else if (typeof(message) == 'string' ||
               typeof(message) == 'number' ||
               typeof(message) == 'boolean') {
      // Primitives are passed directly through.
      return message;
    } else if (message instanceof SendPortSync) {
      // Non-proxied objects are serialized.
      return message;
    } else if (message instanceof Element &&
        (message.ownerDocument == null || message.ownerDocument == document)) {
      return [ 'domref', serializeElement(message) ];
    } else if (message instanceof BoundFunction &&
               typeof(message.object) == 'function') {
      // Local function proxy.
      return [ 'funcref',
               proxiedObjectTable.add(message),
               proxiedObjectTable.sendPort ];
    } else if (typeof(message) == 'function') {
      if ('_dart_id' in message) {
        // Remote function proxy.
        var remoteId = message._dart_id;
        var remoteSendPort = message._dart_port;
        return [ 'funcref', remoteId, remoteSendPort ];
      } else {
        // Local function proxy.
        return [ 'funcref',
                 proxiedObjectTable.add(message),
                 proxiedObjectTable.sendPort ];
      }
    } else if (message instanceof DartProxy) {
      // Remote object proxy.
      return [ 'objref', message.id, message.port ];
    } else {
      // Local object proxy.
      return [ 'objref',
               proxiedObjectTable.add(message),
               proxiedObjectTable.sendPort ];
    }
  }

  function deserialize(message) {
    if (message == null) {
      return null;  // Convert undefined to null.
    } else if (typeof(message) == 'string' ||
               typeof(message) == 'number' ||
               typeof(message) == 'boolean') {
      // Primitives are passed directly through.
      return message;
    } else if (message instanceof SendPortSync) {
      // Serialized type.
      return message;
    }
    var tag = message[0];
    switch (tag) {
      case 'funcref': return deserializeFunction(message);
      case 'objref': return deserializeObject(message);
      case 'domref': return deserializeElement(message[1]);
    }
    throw 'Unsupported serialized data: ' + message;
  }

  // Create a local function that forwards to the remote function.
  function deserializeFunction(message) {
    var id = message[1];
    var port = message[2];
    // TODO(vsm): Add a more robust check for a local SendPortSync.
    if ("receivePort" in port) {
      // Local function.
      return unbind(proxiedObjectTable.get(id));
    } else {
      // Remote function.  Forward to its port.
      var f = function () {
        var depth = enterScope();
        try {
          var args = Array.prototype.slice.apply(arguments);
          args.splice(0, 0, this);
          args = args.map(serialize);
          var result = port.callSync([id, '#call', args]);
          if (result[0] == 'throws') throw deserialize(result[1]);
          return deserialize(result[1]);
        } finally {
          exitScope(depth);
        }
      };
      // Cache the remote id and port.
      f._dart_id = id;
      f._dart_port = port;
      return f;
    }
  }

  // Creates a DartProxy to forwards to the remote object.
  function deserializeObject(message) {
    var id = message[1];
    var port = message[2];
    // TODO(vsm): Add a more robust check for a local SendPortSync.
    if ("receivePort" in port) {
      // Local object.
      return proxiedObjectTable.get(id);
    } else {
      // Remote object.
      return new DartProxy(id, port);
    }
  }

  // Remote handler to construct a new JavaScript object given its
  // serialized constructor and arguments.
  function construct(args) {
    args = args.map(deserialize);
    var constructor = unbind(args[0]);
    args = Array.prototype.slice.call(args, 1);

    // Until 10 args, the 'new' operator is used. With more arguments we use a
    // generic way that may not work, particulary when the constructor does not
    // have an "apply" method.
    var ret = null;
    if (args.length === 0) {
      ret = new constructor();
    } else if (args.length === 1) {
      ret = new constructor(args[0]);
    } else if (args.length === 2) {
      ret = new constructor(args[0], args[1]);
    } else if (args.length === 3) {
      ret = new constructor(args[0], args[1], args[2]);
    } else if (args.length === 4) {
      ret = new constructor(args[0], args[1], args[2], args[3]);
    } else if (args.length === 5) {
      ret = new constructor(args[0], args[1], args[2], args[3], args[4]);
    } else if (args.length === 6) {
      ret = new constructor(args[0], args[1], args[2], args[3], args[4],
                            args[5]);
    } else if (args.length === 7) {
      ret = new constructor(args[0], args[1], args[2], args[3], args[4],
                            args[5], args[6]);
    } else if (args.length === 8) {
      ret = new constructor(args[0], args[1], args[2], args[3], args[4],
                            args[5], args[6], args[7]);
    } else if (args.length === 9) {
      ret = new constructor(args[0], args[1], args[2], args[3], args[4],
                            args[5], args[6], args[7], args[8]);
    } else if (args.length === 10) {
      ret = new constructor(args[0], args[1], args[2], args[3], args[4],
                            args[5], args[6], args[7], args[8], args[9]);
    } else {
      // Dummy Type with correct constructor.
      var Type = function(){};
      Type.prototype = constructor.prototype;

      // Create a new instance
      var instance = new Type();

      // Call the original constructor.
      ret = constructor.apply(instance, args);
      ret = Object(ret) === ret ? ret : instance;
    }
    return serialize(ret);
  }

  // Remote handler to return the top-level JavaScript context.
  function context(data) {
    return serialize(globalContext);
  }

  // Remote handler to track number of live / allocated proxies.
  function proxyCount() {
    var live = proxiedObjectTable.count();
    var total = proxiedObjectTable.total();
    return [live, total];
  }

  // Return true if two JavaScript proxies are equal (==).
  function proxyEquals(args) {
    return deserialize(args[0]) == deserialize(args[1]);
  }

  // Return true if a JavaScript proxy is instance of a given type (instanceof).
  function proxyInstanceof(args) {
    var obj = unbind(deserialize(args[0]));
    var type = unbind(deserialize(args[1]));
    return obj instanceof type;
  }

  // Return true if a JavaScript proxy has a given property.
  function proxyHasProperty(args) {
    var obj = unbind(deserialize(args[0]));
    var member = unbind(deserialize(args[1]));
    return member in obj;
  }

  // Delete a given property of object.
  function proxyDeleteProperty(args) {
    var obj = unbind(deserialize(args[0]));
    var member = unbind(deserialize(args[1]));
    delete obj[member];
  }

  function proxyConvert(args) {
    return serialize(deserializeDataTree(args));
  }

  function deserializeDataTree(data) {
    var type = data[0];
    var value = data[1];
    if (type === 'map') {
      var obj = {};
      for (var i = 0; i < value.length; i++) {
        obj[value[i][0]] = deserializeDataTree(value[i][1]);
      }
      return obj;
    } else if (type === 'list') {
      var list = [];
      for (var i = 0; i < value.length; i++) {
        list.push(deserializeDataTree(value[i]));
      }
      return list;
    } else /* 'simple' */ {
      return deserialize(value);
    }
  }

  function makeGlobalPort(name, f) {
    var port = new ReceivePortSync();
    port.receive(f);
    window.registerPort(name, port.toSendPort());
  }

  // Enters a new scope in the JavaScript context.
  function enterJavaScriptScope() {
    proxiedObjectTable.enterScope();
  }

  // Enters a new scope in both the JavaScript and Dart context.
  var _dartEnterScopePort = null;
  function enterScope() {
    enterJavaScriptScope();
    if (!_dartEnterScopePort) {
      _dartEnterScopePort = window.lookupPort('js-dart-interop-enter-scope');
    }
    return _dartEnterScopePort.callSync([]);
  }

  // Exits the current scope (and invalidate local IDs) in the JavaScript
  // context.
  function exitJavaScriptScope() {
    proxiedObjectTable.exitScope();
  }

  // Exits the current scope in both the JavaScript and Dart context.
  var _dartExitScopePort = null;
  function exitScope(depth) {
    exitJavaScriptScope();
    if (!_dartExitScopePort) {
      _dartExitScopePort = window.lookupPort('js-dart-interop-exit-scope');
    }
    return _dartExitScopePort.callSync([ depth ]);
  }

  makeGlobalPort('dart-js-interop-context', context);
  makeGlobalPort('dart-js-interop-create', construct);
  makeGlobalPort('dart-js-interop-proxy-count', proxyCount);
  makeGlobalPort('dart-js-interop-equals', proxyEquals);
  makeGlobalPort('dart-js-interop-instanceof', proxyInstanceof);
  makeGlobalPort('dart-js-interop-has-property', proxyHasProperty);
  makeGlobalPort('dart-js-interop-delete-property', proxyDeleteProperty);
  makeGlobalPort('dart-js-interop-convert', proxyConvert);
  makeGlobalPort('dart-js-interop-enter-scope', enterJavaScriptScope);
  makeGlobalPort('dart-js-interop-exit-scope', exitJavaScriptScope);
  makeGlobalPort('dart-js-interop-globalize', function(data) {
    if (data[0] == "objref" || data[0] == "funcref") return proxiedObjectTable.globalize(data[1]);
    throw 'Illegal type: ' + data[0];
  });
  makeGlobalPort('dart-js-interop-invalidate', function(data) {
    if (data[0] == "objref" || data[0] == "funcref") return proxiedObjectTable.invalidate(data[1]);
    throw 'Illegal type: ' + data[0];
  });
})();
"""; iB(g){final h=new q.ScriptElement()..type='text/javascript'..text=g;q.document.body.nodes.add(h);}var DB=null;var jB=null;var kB=null;var SB=null;var lB=null;var mB=null;var nB=null;var oB=null;var TB=null;var UB=null;var VB=null;var WB=null;var XB=null;var YB=null; pB(){if(DB!=null)return;try {DB=q.window.lookupPort('dart-js-interop-context');}catch (h){}if(DB==null){iB(hB);DB=q.window.lookupPort('dart-js-interop-context');}jB=q.window.lookupPort('dart-js-interop-create');kB=q.window.lookupPort('dart-js-interop-proxy-count');SB=q.window.lookupPort('dart-js-interop-equals');lB=q.window.lookupPort('dart-js-interop-instanceof');mB=q.window.lookupPort('dart-js-interop-has-property');nB=q.window.lookupPort('dart-js-interop-delete-property');oB=q.window.lookupPort('dart-js-interop-convert');TB=q.window.lookupPort('dart-js-interop-enter-scope');UB=q.window.lookupPort('dart-js-interop-exit-scope');VB=q.window.lookupPort('dart-js-interop-globalize');WB=q.window.lookupPort('dart-js-interop-invalidate');XB=new q.ReceivePortSync()..receive((jC)=>ZB());YB=new q.ReceivePortSync()..receive((g)=>aB(g[0]));q.window.registerPort('js-dart-interop-enter-scope',XB.toSendPort());q.window.registerPort('js-dart-interop-exit-scope',YB.toSendPort());} get qB{NB();return JB(DB.callSync([] ));}get rB=>m.kC.length; NB(){if(rB==0){var g=ZB();MB.runAsync(()=>aB(g));}} ZB(){pB();m.KC();TB.callSync([] );return m.kC.length;} aB( g){assert(m.kC.length==g);UB.callSync([] );m.LC();} sB( g){VB.callSync(BB(g.FB()));return g;} bB( g){WB.callSync(BB(g.FB()));}class ZC implements CB<IB>{var lC;var mC;var nC;pB(g){lC=g;mC=m.add(nC);m.MC(mC);}oC(){var g=m.NC(mC);} FB()=>new IB.iC(m.LB,mC);ZC.hC( h,{ withThis: false}){nC=( g){try {return Function.apply(h,withThis?g:g.skip(1).toList());}finally {oC();}};pB(false);}}class aC{const aC();}const AB=const aC(); tB(i,j,k,o,v,GB){final g=[i,j,k,o,v,GB];final h=g.indexOf(AB);if(h<0)return g;return g.sublist(0,h);}class t implements CB<t>{var pC;final mC;t.iC(this.pC,this.mC); FB()=>this;operator[](g)=>EB(this,'[]','method',[g]);operator[]=(g,h)=>EB(this,'[]=','method',[g,h]);operator==(g)=>identical(this,g)?true:(g is t&&SB.callSync([BB(this),BB(g)])); toString()=>EB(this,'toString','method',[] ,onNone:()=>super.toString());noSuchMethod( h){var g=SC.MirrorSystem.getName(h.memberName);if(g.indexOf('@')!=-1){g=g.substring(0,g.indexOf('@'));}var i;var j=h.positionalArguments;if(j==null)j=[] ;if(h.isGetter){i='get';}else if(h.isSetter){i='set';if(g.endsWith('=')){g=g.substring(0,g.length-1);}}else if(g=='call'){i='apply';}else{i='method';}return EB(this,g,i,j,onNone:()=>super.noSuchMethod(h));}static EB( h, i, j, k,{onNone()}){NB();var g=h.pC.callSync([h.mC,i,j,k.map(BB).toList()]);switch (g[0]){case 'return':return JB(g[1]);case 'throws':throw JB(g[1]);case 'none':return onNone==null?null:onNone();default:throw 'Invalid return value';}}}class IB extends t implements CB<IB>{IB.iC( g,h):super.iC(g,h);call([g=AB,h=AB,i=AB,j=AB,k=AB,o=AB]){var v=tB(g,h,i,j,k,o);return t.EB(this,'','apply',v);}}abstract class CB<uB>{ FB();}class vB{final  qC;var rC;var sC;final  tC;final  pC;final  uC;final  vC;final  kC;KC(){kC.add(vC.length);}LC(){var h=kC.removeLast();for(int g=h;g<vC.length; ++g){var i=vC[g];if(!uC.contains(i)){tC.remove(vC[g]);sC++ ;}}if(h!=vC.length){vC.removeRange(h,vC.length);}}MC(g)=>uC.add(g);NC(g){var h=tC[g];uC.remove(g);tC.remove(g);sC++ ;return h;}vB():qC='dart-ref',rC=0,sC=0,tC={},pC=new q.ReceivePortSync(),vC=new List<String>(),kC=new List<int>(),uC=new Set<String>(){pC.receive((g){try {final h=tC[g[0]];final i=g[1];final j=g[2].map(JB).toList();if(i=='#call'){final k=h as Function;var o=BB(k(j));return ['return',o];}else{throw 'Invocation unsupported on non-function Dart proxies';}}catch (v){return ['throws','${v}'];}});} add(h){NB();final g='${qC}-${rC++ }';tC[g]=h;vC.add(g);return g;}Object get( g){return tC[g];}get LB=>pC.toSendPort();}var m=new vB();BB(var g){if(g==null){return null;}else if(g is String||g is num||g is bool){return g;}else if(g is l.SendPortSync){return g;}else if(g is q.Element&&(g.document==null||g.document==q.document)){return ['domref',xB(g)];}else if(g is IB){return ['funcref',g.mC,g.pC];}else if(g is t){return ['objref',g.mC,g.pC];}else if(g is CB){return BB(g.FB());}else{return ['objref',m.add(g),m.LB];}}JB(var g){j(g){var h=g[1];var i=g[2];if(i==m.LB){return m.get(h);}else{return new IB.iC(i,h);}}k(g){var h=g[1];var i=g[2];if(i==m.LB){return m.get(h);}else{return new t.iC(i,h);}}if(g==null){return null;}else if(g is String||g is num||g is bool){return g;}else if(g is l.SendPortSync){return g;}var o=g[0];switch (o){case 'funcref':return j(g);case 'objref':return k(g);case 'domref':return yB(g[1]);}throw 'Unsupported serialized data: ${g}';}var wB=0;const KB='data-dart_id';const u='data-dart_temporary_attached';xB( h){var i;if(h.attributes.containsKey(KB)){i=h.attributes[KB];}else{i='dart-${wB++ }';h.attributes[KB]=i;}if(!identical(h,q.document.documentElement)){var g=h;while (true){if(g.attributes.containsKey(u)){final j=g.attributes[u];final k=j+'a';g.attributes[u]=k;break;}if(g.parent==null){g.attributes[u]='a';q.document.documentElement.children.add(g);break;}if(identical(g.parent,q.document.documentElement)){break;}g=g.parent;}}return i;} yB(var h){var i=q.queryAll('[${KB}="${h}"]');if(i.length>1)throw 'Non unique ID: ${h}';if(i.length==0){throw 'Only elements attached to document can be serialized: ${h}';}final j=i[0];if(!identical(j,q.document.documentElement)){var g=j;while (true){if(g.attributes.containsKey(u)){final k=g.attributes[u];final o=k.substring(1);g.attributes[u]=o;if(g.attributes[u].length==0){g.attributes.remove(u);g.remove();}break;}if(identical(g.parent,q.document.documentElement)){break;}g=g.parent;}}return j;} zB({ uri: null, uriGenerator( callback): null, type: null})=>GC(const OB(const bC(),const cC()),uri:uri,uriGenerator:uriGenerator,type:type);class bC extends cB{const bC(); fB( h, i){qB[h]=new ZC.hC(( g){sB(g);i.complete(g);});} gB( g){bB(g);}}class cC extends dB{const cC(); request( g){q.document.body.nodes.add(new q.ScriptElement()..src=g);}}abstract class cB{const cB(); fB( g, h); gB(var g);}abstract class dB{const dB(); request( g);}class OB<AC extends cB,BC extends dB>{final  QB;final  html;const OB(this.QB,this.html);}class CC{static var DC=0;static  EC(){return "jsonp_receive_${DC++ }";}final  PB;final  eB=EC();CC(this.PB); request( g( callback))=>PB.html.request(g(eB)); convert( h,var g){var i=SC.reflectClass(h).newInstance(const Symbol('fromProxy'),[g]);PB.QB.gB(g);return i.reflectee;}}class FC extends CC{final  wC=new MB.Completer();FC( g):super(g){g.QB.fB(eB,wC);} future({ type: null})=>type==null?wC.future:wC.future.then((var g)=>convert(type,g));} GC( h,{ uri: null, uriGenerator( callback): null, type: null}){try {final  g=new FC(h);g.request(( i)=>HC(uri,uriGenerator,i));return g.future(type:type);}catch (j){return new MB.Future.error(j);}} HC( g, h( callback), i){if(g==null&&h==null){throw new ArgumentError("Missing Parameter: uri or uriGenerator required");}return g!=null?IC(g,i):h(i);} IC( v, GB){var g,i;var h;var j=0;g=Uri.parse(v);h=new Map<String,String>();g.queryParameters.forEach(( k, o){if(o=='?'){h[k]=GB;j++ ;}else{h[k]=o;}});if(j==0){throw new ArgumentError("Missing Callback Placeholder: when providing a uri, at least one query parameter must have the ? value");}i=new Uri(scheme:g.scheme,userInfo:g.userInfo,host:g.host,port:g.port,path:g.path,fragment:g.fragment,queryParameters:h);return i.toString();}const dC=const eC();class eC{const eC();}