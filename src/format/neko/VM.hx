/*
 * format - haXe File Formats
 * NekoVM emulator by Nicolas Cannasse
 *
 * Copyright (c) 2008, The haXe Project Contributors
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE HAXE PROJECT CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE HAXE PROJECT CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
package format.neko;
import format.neko.Data;
import format.neko.Value;
import format.neko.Value.ValueTools.*;
import format.neko.internal.Macro.h;
import haxe.ds.Vector;

class VM {
	
	public static var current(default, null):VM;
	
	static inline var s_id = h("__s");
	static inline var a_id = h("__a");

	// globals
	var opcodes : Array<Opcode>;
	var builtins : Builtins;
	var hfields : Map<Int,String>;
	var hbuiltins : Map<Int,Value>;
	var hloader : Int;
	var hexports : Int;

	// registers
	var vthis : Value;
	var env : Array<Value>;
	var stack : Array<Value>;
	var trap : Int = -1;

	// current module
	var module : Module;

	public function new() {
		hbuiltins = new Map();
		hfields = new Map();
		opcodes = [];
		stack = [];
		for ( f in Type.getEnumConstructs(Opcode) )
		{
			//FIXME java
			if (StringTools.startsWith(f, "$"))
				break;
			opcodes.push(Type.createEnum(Opcode, f));
		}
		builtins = new Builtins(this);
		for( b in builtins.table.keys() )
			hbuiltins.set(hash(b), builtins.table.get(b));
		hloader = h("loader");
		hexports = h("exports");
	}

	function hash( s : String ) {
		var h = 0;
		#if (neko_v2 || !haxe3)
		for( i in 0...s.length )
			h = 223 * h + s.charCodeAt(i);
		return h;
		#else
		for( i in 0...s.length )
			h = (((223 * h) >> 1) + s.charCodeAt(i)) << 1;
		return h >> 1;
		#end
	}

	public dynamic function doPrint( s : String ) {
		#if sys
		Sys.print(s);
		#else
		haxe.Log.trace(s, null);
		#end
	}

	public function hashField( f : String ) {
		var fid = hash(f);
		var f2 = hfields.get(fid);
		if( f2 != null ) {
			if( f2 == f ) return fid;
			throw "Hashing conflicts between '" + f + "' and '" + f2 + "'";
		}
		hfields.set(fid, f);
		return fid;
	}

	/*
	public function _abstract<T>( b : Value, t : Class<T> ) : T {
		#if xneko_strict_value
		switch( b ) {
		case VAbstract(v):
			if( Std.is(v, t) )
				return cast v;
		default:
		}
		exc(VString("Invalid call"));
		return null;
		
		#else
		var a = as(b, t);
		if (a == null)
			exc(VString("Invalid call"));
		return a;
		
		#end
	}
	*/

	public function valueToString( v : Value ) {
		return builtins._string(v);
	}

	public function exc( v : Value ) {
		throw v;
	}

	function loadPrim( vprim : Value, vargs : Value ) {
		var prim:String, nargs:Int;
		#if xneko_strict_value
		switch( vprim ) {
		case VString(s): prim = s;
		default: return null;
		}
		switch(vargs) {
		case VInt(n): nargs = n;
		default: return null;
		}
		
		#else
		val_check_string(vprim);
		val_check_int(vargs);
		prim = vprim; nargs = vargs;
		
		#end
		var me = this;
		return VFunction(VFunVar(function(_) { me.exc(VString("Failed to load primitive " + prim + ":" + nargs)); return null; } ));
	}

	public function defaultLoader() {
		var loader = new ValueObject(null);
		loader.fields.set(hash("loadprim"), VFunction(VFun2(loadPrim)));
		return loader;
	}

	public function load( m : Data, ?loader : ValueObject ) {
		if( loader == null ) loader = defaultLoader();
		this.module = new Module(m, loader);
		for( i in 0...m.globals.length ) {
			var me = this, mod = module;
			module.gtable[i] = switch(m.globals[i]) {
			case GlobalVar(_): VNull;
			case GlobalFloat(v): VFloat(Std.parseFloat(v));
			case GlobalString(s): VString(s);
			case GlobalFunction(pos, nargs): VFunction(switch( nargs ) {
				case 0: VFun0(function() {
					return me.fcall(mod, pos);
				});
				case 1: VFun1(function(a) {
					me.stack.push(a);
					return me.fcall(mod, pos);
				});
				case 2: VFun2(function(a, b) {
					me.stack.push(a);
					me.stack.push(b);
					return me.fcall(mod, pos);
				});
				case 3: VFun3(function(a, b, c) {
					me.stack.push(a);
					me.stack.push(b);
					me.stack.push(c);
					return me.fcall(mod, pos);
				});
				case 4: VFun4(function(a, b, c, d) {
					me.stack.push(a);
					me.stack.push(b);
					me.stack.push(c);
					me.stack.push(d);
					return me.fcall(mod, pos);
				});
				case 5: VFun5(function(a, b, c, d, e) {
					me.stack.push(a);
					me.stack.push(b);
					me.stack.push(c);
					me.stack.push(d);
					me.stack.push(e);
					return me.fcall(mod, pos);
				});
				default:
					throw "assert";
			});
			case GlobalDebug(debug): module.debug = debug; VNull;
			};
		}
		for( f in m.fields )
			hashField(f);
		vthis = VNull;
		env = [];
		var initStack = stack.length;
		
		var old = current;
		try
		{
			current = this;
			loop(0, VNull);
		}
		catch (e:Value)
		{
			if (trap >= 0 && trap >= initStack)
			{
				if (stack.length <= trap)
					throw VString('Invalid trap $trap (${stack.length})');
				stack.splice(trap, stack.length - trap);
				this.vthis = stack.pop();
				this.env = stack.pop();
				var pc = stack.pop();
				this.trap = stack.pop();
				loop(pc, e);
			} else {
				// if uncaught or outside init stack, reraise
				current = old;
				throw e;
			}
		}
		
		current = old;
		return this.module;
	}

	function error( pc : Int, msg : String ) {
		pc--;
		var pos;
		if( pc < 0 )
			pos = "C Function";
		else if( module.debug != null ) {
			var p = module.debug[pc];
			pos = p.file+"("+p.line+")";
		} else
			pos = "@" + StringTools.hex(pc);
		throw VString(pos+" : "+msg);
	}

	function fieldName( fid : Int ) {
		var name = hfields.get(fid);
		return (name == null) ? "?" + fid : name;
	}

	public function call( vthis : Value, vfun : Value, args : Array<Value> ) : Value {
		for( a in args )
			stack.push(a);
		return mcall(0, vthis, vfun, args.length );
	}

	function fcall( m : Module, pc : Int) {
		var old = this.module;
		this.module = m;
		var acc = loop(pc, VNull);
		this.module = old;
		return acc;
	}

	function mcall( pc : Int, obj : Value, f : Value, nargs : Int ) {
		#if xneko_strict_value
		var ret = null;
		var old = vthis;
		vthis = obj;
		switch( f ) {
		case VFunction(f):
			switch( f ) {
			case VFun0(f):
				if( nargs != 0 ) error(pc, "Invalid call");
				ret = f();
			case VFun1(f):
				if( nargs != 1 ) error(pc, "Invalid call");
				var a = stack.pop();
				ret = f(a);
			case VFun2(f):
				if( nargs != 2 ) error(pc, "Invalid call");
				var b = stack.pop();
				var a = stack.pop();
				ret = f(a,b);
			case VFun3(f):
				if( nargs != 3 ) error(pc, "Invalid call");
				var c = stack.pop();
				var b = stack.pop();
				var a = stack.pop();
				ret = f(a,b,c);
			case VFun4(f):
				if( nargs != 4 ) error(pc, "Invalid call");
				var d = stack.pop();
				var c = stack.pop();
				var b = stack.pop();
				var a = stack.pop();
				ret = f(a,b,c,d);
			case VFun5(f):
				if( nargs != 5 ) error(pc, "Invalid call");
				var e = stack.pop();
				var d = stack.pop();
				var c = stack.pop();
				var b = stack.pop();
				var a = stack.pop();
				ret = f(a,b,c,d,e);
			case VFunVar(f):
				var args = [];
				for( i in 0...nargs )
					args.push(stack.pop());
				ret = f(args);
			}
		case VProxyFunction(f):
			var args = [];
			for( i in 0...nargs )
				args.unshift(unwrap(stack.pop()));
			ret = wrap(Reflect.callMethod(switch( obj ) { case VProxy(o): o; default: null; }, f, args));
		default:
			error(pc, "Invalid call");
		}
		if( ret == null )
			error(pc, "Invalid call");
		vthis = old;
		return ret;
		
		#else
		var ret = null;
		var old = vthis;
		vthis = obj;
		
		var args = [];
		for( i in 0...nargs )
			args.unshift(unwrap(stack.pop()));
		
		var fn:ValueEnvFunction = as(f, ValueEnvFunction);
		if (fn != null)
		{
			var oenv = env, omod = module;
			env = fn.env;
			module = fn.module;
			ret = Reflect.callMethod(obj, fn.func, args);
			env = oenv;
			module = omod;
		} else {
			#if debug
			if (!Reflect.isFunction(f))
				error(pc,'Expected function. Got $f');
			#end
			ret = Reflect.callMethod(obj, f, args);
		}
		
		vthis = old;
		return ret;
		
		#end
	}

	inline function compare( pc : Int, a : Value, b : Value ) {
		return builtins._compare(a, b);
	}

	inline function accIndex( pc : Int, acc : Value, index : Int ) {
		#if xneko_strict_value
		switch( acc ) {
		case VArray(a):
			acc = a[index];
			if( acc == null ) acc = VNull;
		case VObject(_):
			throw "TODO";
		default:
			error(pc, "Invalid array access");
		}
		return acc;
		
		#elseif (cpp || java || cs || neko || !xneko_strict) //already calls __get
		return acc[index];
		
		#else
		var arr = as(acc, Array);
		if (arr == null)
			throw "TODO";
		return arr[index];
		
		#end
	}

	public function wrap( v : Dynamic ) {
		#if xneko_strict_value
		return switch( Type.typeof(v) ) {
			case TNull: VNull;
			case TInt: VInt(v);
			case TFloat: VFloat(v);
			case TBool: VBool(v);
			case TFunction: VProxyFunction(v);
			case TObject, TClass(_), TEnum(_): VProxy(v);
			case TUnknown:
				#if neko
				untyped {
					var t = $typeof(v);
					if( t == $tstring ) VString(new String(v)) else if( t == $tarray ) VArray(Array.new1(v, $asize(v))) else null;
				}
				#else
				null;
				#end
		};
		
		#else
		return v;
		
		#end
	}

	public function unwrap( v : Value ) : Dynamic {
		#if xneko_strict_value
		switch(v) {
		case VNull: return null;
		case VInt(i): return i;
		case VFloat(f): return f;
		case VString(s): return s;
		case VProxy(o): return o;
		case VBool(b): return b;
		case VAbstract(v): return v;
		case VProxyFunction(f): return f;
		case VArray(a):
			var a2 = [];
			for( x in a )
				a2.push(unwrap(x));
			return a2;
		case VObject(o):
			var a = { };
			for( f in o.fields.keys() )
				Reflect.setField(a, fieldName(f), unwrap(o.fields.get(f)));
			return a;
		case VFunction(f):
			var me = this;
			switch(f) {
			case VFun0(f): return function() return me.unwrap(f());
			case VFun1(f): return function(x) return me.unwrap(f(me.wrap(x)));
			case VFun2(f): return function(x,y) return me.unwrap(f(me.wrap(x),me.wrap(y)));
			case VFun3(f): return function(x,y,z) return me.unwrap(f(me.wrap(x),me.wrap(y),me.wrap(z)));
			case VFun4(f): return function(x,y,z,w) return me.unwrap(f(me.wrap(x),me.wrap(y),me.wrap(z),me.wrap(w)));
			case VFun5(f): return function(x,y,z,w,k) return me.unwrap(f(me.wrap(x),me.wrap(y),me.wrap(z),me.wrap(w),me.wrap(k)));
			case VFunVar(f): return Reflect.makeVarArgs(function(args) {
					var args2 = new Array();
					for( x in args ) args2.push(me.wrap(x));
					return me.unwrap(f(args2));
				});
			}
		}
		
		#else
		return v;
		
		#end
	}

	public function getField( v : Value, fid : Int ) {
		#if xneko_strict_value
		switch( v ) {
		case VObject(o):
			while( true ) {
				v = o.fields.get(fid);
				if( v != null ) break;
				o = o.proto;
				if( o == null ) {
					v = VNull;
					break;
				}
			}
		case VProxy(o):
			var f : Dynamic = try Reflect.field(o, fieldName(fid)) catch( e : Dynamic ) null;
			v = wrap(f);
		default:
			v = null;
		}
		return v;
		
		#else
		var o2 = as(v, ValueObject);
		if (o2 != null)
		{
			do
			{
				var r = o2.fields.get(fid);
				if (r != null)
					return r;
				o2 = o2.proto;
			} while (o2 != null);
			
			return null;
		} else {
			return wrap(Reflect.field(v, fieldName(fid)));
		}
		
		#end
	}
	
	inline function getFieldObj(v:ValueObject, fid:Int):Value
	{
		var r:Value = null;
		do
		{
			r = v.fields.get(fid);
			if (r != null)
				break;
			v = v.proto;
		} while (v != null);
		
		return r;
	}

	function loop( pc : Int, acc:Value ) {
		
		//var acc:Value = VNull;
		var code = module.code.code;
		while( true ) {
			var op = code[pc++];
			//var dbg = module.debug[pc];
			//if( dbg != null ) trace(dbg.file + "(" + dbg.line + ") " + opcodes[op]+ " " +stack.length);
			switch( op ) {
			case Op.AccNull:
				acc = VNull;
			case Op.AccTrue:
				acc = VBool(true);
			case Op.AccFalse:
				acc = VBool(false);
			case Op.AccThis:
				acc = vthis;
			case Op.AccInt:
				acc = VInt(code[pc++]);
			case Op.AccInt32:
				acc = VInt(code[pc++]);
			case Op.AccStack:
				var idx = code[pc++];
				acc = stack[stack.length - idx - 3];
			case Op.AccStack0:
				acc = stack[stack.length - 1];
			case Op.AccStack1:
				acc = stack[stack.length - 2];
			case Op.AccGlobal:
				acc = module.gtable[code[pc++]];
			case Op.AccEnv:
				var i = code[pc++];
				
				#if debug
				var env = env;
				if (env == null || i >= env.length)
					error(pc, "Reading outside env");
				#end
				//trace(dbg.file + "(" + dbg.line + ") " + 'accessing  $env : $i :: ${env[i]}');
				acc = env[i];
			case Op.AccField:
				switch(code[pc])
				{
				case s_id if (Std.is(acc, String)):
				case a_id if (Std.is(acc, Array)):
				default:
					acc = getField(acc, code[pc]);
					if( acc == null ) error(pc, "Invalid field access : " + fieldName(code[pc]));
				}
				pc++;
			case Op.AccArray:
				var arr = stack.pop();
				
				#if xneko_strict_value
				switch( arr ) {
				case VArray(a):
					switch( acc ) {
					case VInt(i): acc = a[i]; if( acc == null ) acc = VNull;
					default: error(pc, "Invalid array access");
					}
				case VObject(_):
					throw "TODO";
				default:
					error(pc, "Invalid array access");
				}
				
				#else
				var i:IntValue = acc;
				val_check_int(i);
				acc = accIndex(pc, arr, i);
				
				#end
			case Op.AccIndex:
				acc = accIndex(pc, acc, code[pc] + 2);
				pc++;
			case Op.AccIndex0:
				acc = accIndex(pc, acc, 0);
			case Op.AccIndex1:
				acc = accIndex(pc, acc, 1);
			case Op.AccBuiltin:
				acc = hbuiltins.get(code[pc++]);
				if( acc == null ) {
					if( code[pc - 1] == hloader )
						acc = VObject(module.loader);
					else if( code[pc-1] == hexports )
						acc = VObject(module.exports);
					else
						error(pc - 1, "Builtin not found : " + fieldName(code[pc - 1]));
				}
			case Op.SetStack:
				var idx = code[pc++];
				stack[stack.length - idx - 1] = acc;
			case Op.SetGlobal:
				module.gtable[code[pc++]] = acc;
			case Op.SetEnv:
				var i = code[pc++];
				
				#if debug
				var env = env;
				if (env == null || i >= env.length)
					error(pc, "Writing outside Env");
				//trace('setting  $env : $i :: $acc');
				#end
				env[i] = acc;
			case Op.SetField:
				var obj = stack.pop();
				
				#if xneko_strict_value
				switch( obj ) {
				case VObject(o): o.fields.set(code[pc++], acc);
				case VProxy(o): Reflect.setField(o, fieldName(code[pc++]), unwrap(acc));
				default: error(pc, "Invalid field access : " + fieldName(code[pc]));
				}
				
				#else
				var o2 = as(obj, ValueObject);
				if (o2 != null)
				{
					o2.fields.set(code[pc++], acc); //FIXME: check for references on prototype
				} else {
					Reflect.setField(obj, fieldName(code[pc++]), acc);
				}
				
				#end
			case Op.SetArray:
				var arr = stack.pop();
				var i = stack.pop();
				if (is(arr, Array))
				{
					var arr2:Array<Dynamic> = arr;
					var i2:IntValue = i;
					val_check_int(i2);
					arr2[i2] = acc;
				} else if (is(arr, ValueObject)) {
					var arr:ValueObject = cast arr;
					var f = getFieldObj(arr, h("__set") );
					if (f == null)
						error(pc, "Unsupported operation");
					call(arr, f, [i, acc]);
				} else {
					arr[i] = acc;
				}
			case Op.SetIndex:
				var i = code[pc++];
				var arr = stack.pop();
				if (is(arr, Array))
				{
					var arr2:Array<Dynamic> = arr;
					arr2[i] = acc;
				} else if (is(arr, ValueObject)) {
					var arr:ValueObject = cast arr;
					var f = getFieldObj(arr, h("__set") );
					if (f == null)
						error(pc, "Unsupported operation");
					call(arr, f, [i, acc]);
				} else {
					arr[i] = acc;
				}
			case Op.SetThis:
				vthis = acc;
			case Op.Push:
				#if xneko_strict_value
				if ( acc == null ) error(pc, "assert");
				
				#end
				stack.push(acc);
			case Op.Pop:
				for( i in 0...code[pc++] )
					stack.pop();
			case Op.TailCall:
				var v = code[pc];
				var nstack = v >> 3;
				var nargs = v & 7;
				nstack -= nargs;
				if (nargs == 0) {
					for(i in 0...nstack)
						stack.pop();
				} else {
					var len = stack.length;
					for (i in 0...nargs)
					{
						stack[len - nstack - 1] = stack[len - 1];
						len--;
					}
					for (i in 0...nstack)
						stack.pop();
				}
				return mcall(pc, vthis, acc, nargs);
			case Op.Call:
				acc = mcall(pc, vthis, acc, code[pc]);
				pc++;
			case Op.ObjCall:
				acc = mcall(pc, stack.pop(), acc, code[pc]);
				pc++;
			case Op.Jump:
				pc += code[pc] - 1;
			case Op.JumpIf:
				#if xneko_strict_value
				switch( acc ) {
				case VBool(a): if( a ) pc += code[pc] - 2;
				default:
				}
				
				#else
				var b:BoolValue = acc;
				val_check_bool(b);
				if (b) pc += code[pc] - 2;
				
				#end
				pc++;
			case Op.JumpIfNot:
				#if xneko_strict_value
				switch( acc ) {
				case VBool(a): if( !a ) pc += code[pc] - 2;
				default: pc += code[pc] - 2;
				}
				#else
				var b:BoolValue = acc;
				val_check_bool(b);
				if (!b) pc += code[pc] - 2;
				
				#end
				pc++;
			case Op.Trap:
				stack.push(vthis);
				stack.push(env);
				stack.push(pc);
				stack.push(trap);
				
				trap = stack.length;
				
				pc++;
			case Op.EndTrap:
				if (trap != stack.length) error(pc, "Invalid End Trap");
				trap = stack.pop();
				stack.pop();
				stack.pop();
				stack.pop();
			
			case Op.Ret:
				for( i in 0...code[pc++] )
					stack.pop();
				return acc;
			case Op.MakeEnv:
				var n = code[pc++];
				var tmp = stack.splice(stack.length - n, n);
				if (Reflect.isFunction(acc))
				{
					var fn = new ValueEnvFunction(acc, this.module, tmp);
					acc = fn;
				} else {
					var fn = as(acc, ValueEnvFunction);
					if (fn == null)
						error(pc, "Invalid environment");
					var fn2 = new ValueEnvFunction(fn.func, fn.module, tmp);
					acc = fn2;
				}
			case Op.MakeArray:
				var a = new Array();
				for( i in 0...code[pc++] )
					a.unshift(stack.pop());
				a.unshift(acc);
				acc = VArray(a);
			case Op.Bool:
				#if xneko_strict_value
				acc = switch( acc ) {
				case VBool(_): acc;
				case VNull: VBool(false);
				case VInt(i): VBool(i != 0);
				default: VBool(true);
				}
				
				#else
				var b:BoolValue = acc;
					#if !static
					if (!Std.is(acc, Bool))
						b = acc != 0 && acc != null;
					
					#end
				acc = b;
				
				#end
			case Op.Not:
				#if xneko_strict_value
				acc = switch( acc ) {
				case VBool(b): VBool(!b);
				case VNull: VBool(true);
				case VInt(i): VBool(i == 0);
				default: VBool(false);
				}
				
				#else
				var b:BoolValue = acc;
					#if !static
					if (!Std.is(acc, Bool))
						b = acc == 0 || acc == null;
					else
						b = !b;
					#else
					b = !b;
					
					#end
				acc = b;
				
				#end
			case Op.IsNull:
				acc = VBool(acc == VNull);
			case Op.IsNotNull:
				acc = VBool(acc != VNull);
			case Op.Add:
				var a = stack.pop();
				#if xneko_strict_value
				acc = switch( acc ) {
				case VInt(b):
					switch( a ) {
					case VInt(a): VInt(a + b);
					case VFloat(a): VFloat(a + b);
					case VString(a): VString(a + b);
					case VProxy(a): wrap(a + b);
					default: null;
					}
				case VFloat(b):
					switch( a ) {
					case VInt(a): VFloat(a + b);
					case VFloat(a): VFloat(a + b);
					case VString(a): VString(a + b);
					case VProxy(a): wrap(a + b);
					default: null;
					}
				case VString(b):
					switch( a ) {
					case VInt(a): VString(a + b);
					case VFloat(a): VString(a + b);
					case VString(a): VString(a + b);
					case VProxy(a): wrap(a + b);
					default: null;
					}
				case VProxy(b):
					wrap(unwrap(a) + b);
				default: null;
				}
				if ( acc == null ) error(pc, "+");
				
				#elseif xneko_strict
				throw "TODO";
				
				#else
				if (is(a, ValueObject))
				{
					var a:ValueObject = cast a;
					var add = getFieldObj(a, h("__add"));
					if (add == null)
						error(pc, "Invalid operation: +");
					acc = call(a, add, [acc]);
				} else if (is(acc, ValueObject)) {
					var b:ValueObject = cast acc;
					var add = getFieldObj(b, h("__radd"));
					if (add == null)
						error(pc, "Invalid operation: +");
					acc = call(b, add, [a]);
				} else {
					acc = a + acc;
				}
				
				#end
			case Op.Sub:
				var a = stack.pop();
				#if xneko_strict_value
				throw "TODO";
				
				#elseif xneko_strict
				throw "TODO";
				
				#else
				acc = a - acc;
				
				#end
			case Op.Mult:
				var a = stack.pop();
				#if xneko_strict_value
				throw "TODO";
				
				#elseif xneko_strict
				throw "TODO";
				
				#else
				acc = a * acc;
				
				#end
			case Op.Div:
				var a = stack.pop();
				#if xneko_strict_value
				throw "TODO";
				
				#elseif xneko_strict
				throw "TODO";
				
				#else
				acc = a / acc;
				
				#end
			case Op.Mod:
				var a = stack.pop();
				#if xneko_strict_value
				throw "TODO";
				
				#elseif xneko_strict
				throw "TODO";
				
				#else
				acc = a % acc;
				
				#end
			case Op.Shl:
				var a = stack.pop();
				#if xneko_strict_value
				throw "TODO";
				
				#elseif xneko_strict
				throw "TODO";
				
				#else
				acc = a << acc;
				
				#end
			case Op.Shr:
				var a = stack.pop();
				#if xneko_strict_value
				throw "TODO";
				
				#elseif xneko_strict
				throw "TODO";
				
				#else
				acc = a >> acc;
				
				#end
			case Op.UShr:
				var a = stack.pop();
				#if xneko_strict_value
				throw "TODO";
				
				#elseif xneko_strict
				throw "TODO";
				
				#else
				acc = a >>> acc;
				
				#end
			case Op.Or:
				var a = stack.pop();
				#if xneko_strict_value
				throw "TODO";
				
				#elseif xneko_strict
				throw "TODO";
				
				#else
				acc = a | acc;
				
				#end
			case Op.And:
				var a = stack.pop();
				#if xneko_strict_value
				throw "TODO";
				
				#elseif xneko_strict
				throw "TODO";
				
				#else
				acc = a & acc;
				
				#end
			case Op.Xor:
				var a = stack.pop();
				#if xneko_strict_value
				throw "TODO";
				
				#elseif xneko_strict
				throw "TODO";
				
				#else
				acc = a ^ acc;
				
				#end
			case Op.Eq:
				var c = compare(pc, stack.pop(), acc);
				acc = VBool(c == 0 && c != Builtins.CINVALID);
			case Op.Neq:
				var c = compare(pc, stack.pop(), acc);
				acc = VBool(c != 0 && c != Builtins.CINVALID);
			case Op.Gt:
				var c = compare(pc, stack.pop(), acc);
				acc = VBool(c > 0 && c != Builtins.CINVALID);
			case Op.Gte:
				var c = compare(pc, stack.pop(), acc);
				acc = VBool(c >= 0 && c != Builtins.CINVALID);
			case Op.Lt:
				var c = compare(pc, stack.pop(), acc);
				acc = VBool(c < 0 && c != Builtins.CINVALID);
			case Op.Lte:
				var c = compare(pc, stack.pop(), acc);
				acc = VBool(c <= 0 && c != Builtins.CINVALID);
			case Op.TypeOf:
				acc = builtins.typeof(acc);
			case Op.Compare:
				var v = builtins._compare(stack.pop(), acc);
				acc = (v == Builtins.CINVALID) ? VNull : VInt(v);
			case Op.Hash:
				#if xneko_strict_value
				switch( acc ) {
				case VString(f): acc = VInt(hashField(f));
				default: error(pc, "$hash");
				}
				
				#else
				var i:StringValue = acc;
				val_check_string(i);
				acc = hashField(i);
				
				#end
			case Op.New:
				#if xneko_strict_value
				switch( acc ) {
				case VNull: acc = VObject(new ValueObject(null));
				case VObject(o): acc = VObject(new ValueObject(o));
				default: error(pc, "$new");
				}
				
				#else
				//TODO add support for non-sandboxed objects
				acc = new ValueObject(acc);
				
				#end
			case Op.JumpTable:
				#if xneko_strict_value
				switch ( acc ) {
				case VInt(a) if (a < code[pc]):
					pc += a;
				default:
					pc++;
				}
				
				#else
				if (Std.is(acc, Int))
				{
					var a:Int = acc;
					if (a < code[pc])
						pc += a;
					else
						pc++;
				} else {
					pc++;
				}
				
				#end
			case Op.Apply:
				throw "TODO: OApply. Need to implement nargs before";
			case Op.PhysCompare:
				error(pc, "$pcompare");
			case Op.Loop:
				// space for GC/Debug
			case Op.MakeArray2:
				// similar to MakeArray but will keep a correct evaluation order
				var a = new Array();
				var n = code[pc++];
				a[n] = acc;
				while (n > 0)
				{
					a[--n] = stack.pop();
				}
				acc = VArray(a);
			default:
				throw "TODO:" + opcodes[code[pc - 1]];
			}
		}
		return null;
	}

}