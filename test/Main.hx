package ;

//import cpp.Lib;
import format.neko.Reader;
import format.neko.VM;
import sys.FileSystem;
import sys.io.File;
import format.neko.Value.ValueTools.*;

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
		
		var loader = vm.defaultLoader();
		loader.fields.set(vm.hashField("args"), VArray(Sys.args().map(vm.wrap)));
		var md = vm.load(d, loader);
		trace(md.exports);
		//md.
	}
	
}