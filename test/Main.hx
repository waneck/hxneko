package ;

//import cpp.Lib;
import format.neko.Reader;
import format.neko.VM;
import sys.FileSystem;
import sys.io.File;
import format.neko.Value.ValueTools.*;
import format.neko.Value;

/**
 * ...
 * @author waneck
 */

class Main 
{
	
	static function main() 
	{
		var d = new Reader(File.read("index.n")).read();
		var vm = new VM();
		
		var loader = vm.globalLoader();
		loader.fields.set(vm.hashField("args"), VArray(Sys.args().map(vm.wrap)));
		loop(d, vm, loader);
	}
	
	static function loop(d, vm:VM, loader )
	{
		var time = Sys.time();
		var md = vm.load(d, loader);
		trace(Sys.time() - time);
	}
	
}