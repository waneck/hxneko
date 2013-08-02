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

#if xneko_strict_value
enum Value {
	VNull;
	VInt( i : Int );
	VFloat( f : Float );
	VBool( b : Bool );
	VString( s : String );
	VObject( o : ValueObject );
	VArray( a : Array<Value> );
	VFunction( f : ValueFunction );
	VAbstract( v : ValueAbstract );
	VProxy( o : Dynamic );
	VProxyFunction( f : Dynamic );
}

enum ValueFunction {
	VFun0( f : Void -> Value );
	VFun1( f : Value -> Value );
	VFun2( f : Value -> Value -> Value );
	VFun3( f : Value -> Value -> Value -> Value );
	VFun4( f : Value -> Value -> Value -> Value -> Value );
	VFun5( f : Value -> Value -> Value -> Value -> Value -> Value );
	VFunVar( f : Array<Value> -> Value );
	VEnvFun( f : ValueEnvFunction );
}

typedef ArrayValue<T> = Value;
typedef IntValue = Value;
typedef FloatValue = Value;
typedef BoolValue = Value;
typedef StringValue = Value;

#else
typedef Value = Dynamic;
typedef ValueFunction = Dynamic;

typedef ArrayValue<T> = Array<T>;
typedef IntValue = Int;
typedef FloatValue = Float;
typedef BoolValue = Bool;
typedef StringValue = String;

#end

class ValueTools
{
	#if !xneko_strict_value
	public static inline var VNull = null;
	public static inline function VInt( i : Int ) return i;
	public static inline function VFloat( f : Float ) return f;
	public static inline function VBool( b : Bool ) return b;
	public static inline function VString( s : String ) return s;
	public static inline function VObject( o : ValueObject ) return o;
	public static inline function VArray( a : Array<Value> ) return a;
	public static inline function VFunction( f : Dynamic ) return f;
	public static inline function VAbstract( v : ValueAbstract ) return v;
	public static inline function VProxy( o : Dynamic ) return o;
	public static inline function VProxyFunction( f : Dynamic ) return f;
	
	public static inline function VFun0( f : Void -> Value ) : ValueFunction return f;
	public static inline function VFun1( f : Value -> Value ) : ValueFunction return f;
	public static inline function VFun2( f : Value -> Value -> Value ) : ValueFunction return f;
	public static inline function VFun3( f : Value -> Value -> Value -> Value ) : ValueFunction return f;
	public static inline function VFun4( f : Value -> Value -> Value -> Value -> Value ) : ValueFunction return f;
	public static inline function VFun5( f : Value -> Value -> Value -> Value -> Value -> Value ) : ValueFunction return f;
	public static inline function VFunVar( f : Array<Value> -> Value ) : ValueFunction return Reflect.makeVarArgs(f);
	public static inline function VEnvFun( f : ValueEnvFunction ) : ValueFunction return f;
	
	public static inline function is( v : Value, c : Class<Dynamic> )
	{
		#if js
		return untyped __instanceof__(v, c);
		
		#else
		return Std.is(v, c);
		
		#end
	}
	
	public static inline function as<T>( v : Dynamic, c : Class<T> ) : T
	{
		//#if cpp
		//return cast v;
		
		#if cs
		return cs.Lib.as(v, c);
		
		#elseif (haxe_ver >= 310)
		return Std.instance(v, c); //FIXME: not available?
		
		#else
		return (Std.is(v, c) ? cast v : null);
		
		#end
	}
	
	public static inline function val_check_int( v : IntValue )
	{
		#if (!static && xneko_strict)
		if (!Std.is(v, Int)) throw 'Int value expected. Got $v';
		#end
	}
	
	public static inline function val_check_bool( v : BoolValue )
	{
		#if (!static && xneko_strict)
		if (!Std.is(v, Bool)) throw 'Bool value expected. Got $v';
		#end
	}
	
	public static inline function val_check_string( v : StringValue )
	{
		#if (!static && xneko_strict)
		if (!Std.is(v, String)) throw 'String value expected. Got $v';
		#end
	}
	
	public static inline function val_check_array<T>( v : ArrayValue<T> )
	{
		#if (!static && xneko_strict)
		if (!Std.is(v, Array)) throw 'Array value expected. Got $v';
		#end
	}
	
	#else
	
	
	#end

	
}

class ValueObject {
	public var fields : Map<Int,Value>;
	public var proto : Null<ValueObject>;
	public function new(?p) {
		fields = new Map();
		proto = p;
	}
}

class ValueEnvFunction 
{
	public var module(default, null):Module;
	public var func(default, null):ValueFunction;
	public var env(default, null):Array<Value>;
	
	public function new(func, module, env)
	{
		this.module = module;
		this.func = func;
		this.env = env;
	}
}

interface ValueAbstract {
}

class Module {
	public var code : Data;
	public var gtable : Array<Value>;
	public var debug : Null<DebugInfos>;
	public var exports : ValueObject;
	public var loader : ValueObject;
	public function new(code,loader) {
		this.code = code;
		this.loader = loader;
		gtable = [];
		exports = new ValueObject();
		if( code.globals.length > 0 ) gtable[code.globals.length - 1] = null;
	}
}