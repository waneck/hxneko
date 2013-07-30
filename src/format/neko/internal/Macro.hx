package format.neko.internal;

/**
 * ...
 * @author waneck
 */
class Macro
{

	macro public static function h( es : haxe.macro.Expr ) : haxe.macro.Expr
	{
		switch( es.expr )
		{
		case EConst(CString(s)):
			var h = 0;
			for( i in 0...s.length )
				h = (((223 * h) >> 1) + s.charCodeAt(i)) << 1;
			h = h >> 1;
			return { expr:EConst(CInt(h + "")), pos:es.pos };
		case _:
			return haxe.macro.Context.error("Constant string expected", es.pos);
		}
	}
	
}