package ;

import cpp.Lib;
import format.neko.Reader;
import format.neko.VM;
import sys.FileSystem;
import sys.io.File;

/**
 * ...
 * @author waneck
 */

class Main 
{
	
	static function main() 
	{
		var d = new Reader(File.read("test.n")).read();
		var vm = new VM();
		var md = vm.load(d, vm.defaultLoader());
		trace(md.exports);
		//md.
	}
	
}