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
import format.neko.Value;
import format.neko.Value.ValueTools.*;
import format.neko.internal.Macro.h;

class Builtins {
	
	public static inline var CINVALID = -1000;
	
	var vm : VM;
	public var table : Map<String,Value>;
	
	public function new(vm) {
		this.vm = vm;
		table = new Map();
		b("objsetproto", VFun2(objsetproto));
		b("typeof", VFun1(typeof));
		b("string", VFun1(string));
		b("print", VFunVar(print));
		
		b("call", VFun3(call));
		b("ssize", VFun1(ssize));
		b("array", VFunVar(array));
		b("amake", VFun1(amake));
		b("acopy", VFun1(acopy));
		b("asize", VFun1(asize));
		
		b("int", VFun1(int));
		b("objcall", VFun3(objcall));
		b("objget", VFun2(objget));
	}
	
	// -------- HELPERS ---------------------
	
	function b(name, f) {
		table.set(name, VFunction(f));
	}
	
	public function _nargs( f : ValueFunction ) {
		#if xneko_strict_value
		return switch( f ) {
		case VFun0(_): 0;
		case VFun1(_): 1;
		case VFun2(_): 2;
		case VFun3(_): 3;
		case VFun4(_): 4;
		case VFun5(_): 5;
		case VFunVar(_): -1;
		}
		
		//#elseif neko
		//return untyped $nargs(f);
		
		#else //TODO for all platforms
		return -1;
		
		#end
	}
	
	public function _compare( a : Value, b : Value ) : Int {
		#if xneko_strict_value
		switch( a ) {
		case VInt(a):
			switch(b) {
			case VInt(b):
				return (a == b)?0:((a < b)? -1:1);
			case VFloat(b):
				return (a == b)?0:((a < b)? -1:1);
			case VString(b):
				var a = Std.string(a);
				return (a == b)?0:((a < b)? -1:1);
			default:
			}
		case VFloat(a):
			switch(b) {
			case VInt(b):
				return (a == b)?0:((a < b)? -1:1);
			case VFloat(b):
				return (a == b)?0:((a < b)? -1:1);
			case VString(b):
				var a = Std.string(a);
				return (a == b)?0:((a < b)? -1:1);
			default:
			}
		case VString(a):
			switch(b) {
			case VInt(b):
				var b = Std.string(b);
				return (a == b)?0:((a < b)? -1:1);
			case VFloat(b):
				var b = Std.string(b);
				return (a == b)?0:((a < b)? -1:1);
			case VString(b):
				return (a == b)?0:((a < b)? -1:1);
			case VBool(b):
				var b = Std.string(b);
				return (a == b)?0:((a < b)? -1:1);
			default:
			}
		case VBool(a):
			switch( b ) {
			case VString(b):
				var a = Std.string(a);
				return (a == b)?0:((a < b)? -1:1);
			case VBool(b):
				return (a == b) ? 0 : (a ? 1 : -1);
			default:
			}
		case VObject(a):
			switch( b ) {
			case VObject(b):
				if( a == b )
					return 0;
				throw "TODO";
			default:
			}
		case VProxy(a):
			switch( b ) {
			case VProxy(b):
				return ( a == b ) ? 0 : CINVALID;
			default:
			}
		default:
		}
		return (a == b) ? 0 : CINVALID;
		
		#elseif xneko_strict
		return (is(a, ValueObject) && is(b, ValueObject)) ? (a == b || objcall(a, h("__compare__"), [b])) : Reflect.compare(a, b);
		
		#else
		return Reflect.compare(a, b);
		
		#end
	}
	
	public function _string( v : Value ) {
		#if xneko_strict_value
		return switch( v ) {
		case VNull: "null";
		case VInt(i): Std.string(i);
		case VFloat(f): Std.string(f);
		case VBool(b): b?"true":"false";
		case VArray(a):
			var b = new StringBuf();
			b.addChar("[".code);
			var first = true;
			for( v in a ) {
				if( first ) first = false else b.addChar(",".code);
				b.add(_string(v));
			}
			b.addChar("]".code);
			b.toString();
		case VString(s): s;
		case VFunction(f): "#function:" + _nargs(f);
		case VAbstract(_): "#abstract";
		case VObject(_):
			throw "TODO";
		case VProxy(o):
			Std.string(o);
		case VProxyFunction(f):
			Std.string(f);
		}
		
		#else
		return Std.string(v);
		
		#end
	}
	
	// ----------------- BUILTINS -------------------
	
	public function int( o : Value ) : Value
	{
		#if xneko_strict_value
		return switch(o)
		{
			case VInt(i): i;
			case VFloat(f): Std.int(f);
			case VString(s): Std.parseInt(s);
		}
		
		#elseif xneko_strict
		if (Std.is(o, String))
			return VInt(Std.parseInt(o));
		return (o == null) ? o : Std.int(o);
		
		#else
		return (o == null) ? o : Std.int(o);
		
		#end
	}
	
	public function objcall( o : Value, f : IntValue, args : ArrayValue<Value> )
	{
		#if xneko_strict_value
		switch(o)
		{
			case VArray(a):
				return vm.call(o, objget(o, f), a);
			default:
				vm.exc(VString('Expected Array for $args'));
				return VNull;
		}
		
		#else
		val_check_array(args);
		return vm.call(o, objget(o, f), args);
		
		#end
	}
	
	public inline function objget( o : Value, f : IntValue ) : Value
	{
		#if xneko_strict_value
		switch(f)
		{
			case VInt(i):
				return vm.getField(o, i);
			default:
				vm.exc(VString('Expected int for $f'));
				return null;
		}
		
		#else
		val_check_int(f);
		return vm.getField(o, f);
		
		#end
	}
	
	public function array( args : Array<Value> ) : Value
	{
		return VArray(args);
	}
	
	public function call( f : Value, ctx : Value, args : ArrayValue<Value> ) : Value
	{
		#if xneko_strict_value
		var args = switch(args)
		{
			case VArray(v):v;
			default: vm.exc(VString("Expected array as argument")); null;
		};
		#else
		val_check_array(args);
		
		#end
		return vm.call(ctx, f, args);
	}
	
	public function ssize( s : Value ) : Value
	{
		#if xneko_strict_value
		switch(s)
		{
			case VString(s): return VInt(s.length);
			default: return throw 'Expected string for $s';
		};
		
		#else
		return VInt(s.length);
		
		#end
	}
	
	public function amake( s : IntValue ) : Value
	{
		#if xneko_strict_value
		switch(s)
		{
			case VInt(i):
				var arr = [];
				for (i in 0...i) arr.push(null);
				return VArray(arr);
			default:
				return throw 'Expected int $s';
		}
		
		#else
		val_check_int(s);
		var arr = [];
		for (i in 0...s) arr.push(null);
		return VArray(arr);
		
		#end
	}
	
	public function acopy( a : ArrayValue<Value> ) : Value
	{
		#if xneko_strict_value
		switch(a)
		{
			case VArray(a):
				return VArray(a.copy());
			default:
				throw 'Array value expected; Got $a';
		}
		
		#else
		val_check_array(a);
		var a2 = as(a, Array);
		if (a2 == null)
			throw 'Array value expected; Got $a';
		return a2.copy();
		
		#end
	}
	
	public function asize( a : ArrayValue<Value> ) : IntValue
	{
		#if xneko_strict_value
		switch(a)
		{
			case VArray(a):
				return VInt(a.length);
			default:
				throw 'Array value expected; Got $a';
		}
		
		#else
		val_check_array(a);
		var a2 = as(a, Array);
		if (a2 == null)
			throw 'Array value expected; Got $a';
		return a2.length;
		
		#end
	}
		
	public function typeof( o : Value ) : Value {
		#if xneko_strict_value
		return VInt(switch( o ) {
		case VProxy(_): 5; // $tobject
		case VProxyFunction(_): 7; // $tfunction
		default: Type.enumIndex(o);
		});
		#elseif neko
		return untyped $typeof(o);
		#else //TODO optimize target-based
		if (o == null)
			return 0;
		else if (Std.is(o, Float))
			return Std.is(o, Int) ? 1 : 2;
		else if (Std.is(o, Bool))
			return 3;
		else if (Reflect.isFunction(o))
			return 7;
		else {
			var cl = Type.getClass(o);
			if (cl == null)
				return 5;
			else if (cl == String)
				return 4;
			else if (cl == Array)
				return 6;
			else if (Std.is(cl, VAbstract))
				return 8;
			else
				return 5;
		}
		#end
	}
	
	function print( vl : Array<Value> ) {
		var buf = new StringBuf();
		for( v in vl )
			buf.add(_string(v));
		vm.doPrint(buf.toString());
		return VNull;
	}
	
	function string( v : Value ) {
		return VString(_string(v));
	}
	
	function objsetproto( o : Value, p : Value ) : Value {
		#if xneko_strict_value
		switch( o ) {
		case VObject(o):
			switch(p) {
			case VNull: o.proto = null;
			case VObject(p): o.proto = p;
			default: return null;
			}
		default:
			return null;
		}
		return VNull;
		
		#else
		var o2 = as(o, ValueObject);
		if (o2 != null)
		{
			o2.proto = p;
		} else {
			throw 'Cannot set prototype for consolidated type: $o';
		}
		
		return null;
		
		#end
	}
	
}