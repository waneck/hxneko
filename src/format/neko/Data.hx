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
import haxe.ds.Vector;

extern class Op
{
	public static inline var AccNull =		0;
	public static inline var AccTrue =		1;
	public static inline var AccFalse =		2;
	public static inline var AccThis =		3;
	public static inline var AccInt =		4;
	public static inline var AccStack =		5;
	public static inline var AccGlobal =	6;
	public static inline var AccEnv =		7;
	public static inline var AccField =		8;
	public static inline var AccArray =		9;
	public static inline var AccIndex =		10;
	public static inline var AccBuiltin =	11;
	public static inline var SetStack =		12;
	public static inline var SetGlobal =	13;
	public static inline var SetEnv =		14;
	public static inline var SetField =		15;
	public static inline var SetArray =		16;
	public static inline var SetIndex =		17;
	public static inline var SetThis =		18;
	public static inline var Push =			19;
	public static inline var Pop =			20;
	public static inline var Call =			21;
	public static inline var ObjCall =		22;
	public static inline var Jump =			23;
	public static inline var JumpIf =		24;
	public static inline var JumpIfNot =	25;
	public static inline var Trap =			26;
	public static inline var EndTrap =		27;
	public static inline var Ret =			28;
	public static inline var MakeEnv =		29;
	public static inline var MakeArray =	30;
	// value ops
	public static inline var Bool =			31;
	public static inline var IsNull =		32;
	public static inline var IsNotNull =	33;
	public static inline var Add =			34;
	public static inline var Sub =			35;
	public static inline var Mult =			36;
	public static inline var Div =			37;
	public static inline var Mod =			38;
	public static inline var Shl =			39;
	public static inline var Shr =			40;
	public static inline var UShr =			41;
	public static inline var Or =			42;
	public static inline var And =			43;
	public static inline var Xor =			44;
	public static inline var Eq =			45;
	public static inline var Neq =			46;
	public static inline var Gt =			47;
	public static inline var Gte =			48;
	public static inline var Lt =			49;
	public static inline var Lte =			50;
	public static inline var Not =			51;
	// extra ops
	public static inline var TypeOf =		52;
	public static inline var Compare =		53;
	public static inline var Hash =			54;
	public static inline var New =			55;
	public static inline var JumpTable =	56;
	public static inline var Apply =		57;
	public static inline var AccStack0 =	58;
	public static inline var AccStack1 =	59;
	public static inline var AccIndex0 =	60;
	public static inline var AccIndex1 =	61;
	public static inline var PhysCompare =	62;
	public static inline var TailCall =		63;
}

enum Opcode {
	OAccNull;
	OAccTrue;
	OAccFalse;
	OAccThis;
	OAccInt;
	OAccStack;
	OAccGlobal;
	OAccEnv;
	OAccField;
	OAccArray;
	OAccIndex;
	OAccBuiltin;
	OSetStack;
	OSetGlobal;
	OSetEnv;
	OSetField;
	OSetArray;
	OSetIndex;
	OSetThis;
	OPush;
	OPop;
	OCall;
	OObjCall;
	OJump;
	OJumpIf;
	OJumpIfNot;
	OTrap;
	OEndTrap;
	ORet;
	OMakeEnv;
	OMakeArray;
	// value ops
	OBool;
	OIsNull;
	OIsNotNull;
	OAdd;
	OSub;
	OMult;
	ODiv;
	OMod;
	OShl;
	OShr;
	OUShr;
	OOr;
	OAnd;
	OXor;
	OEq;
	ONeq;
	OGt;
	OGte;
	OLt;
	OLte;
	ONot;
	// extra ops
	OTypeOf;
	OCompare;
	OHash;
	ONew;
	OJumpTable;
	OApply;
	OAccStack0;
	OAccStack1;
	OAccIndex0;
	OAccIndex1;
	OPhysCompare;
	OTailCall;
}

typedef DebugInfos = Vector<Null<{ file : String, line : Int }>>;

enum Global {
	GlobalVar( v : String );
	GlobalFunction( pos : Int, nargs : Int );
	GlobalString( v : String );
	GlobalFloat( v : String );
	GlobalDebug( debug : DebugInfos );
}

typedef Data = {
	var globals : Vector<Global>;
	var fields : Vector<String>;
	var code : Vector<Int>;
}