package ;

import haxe.Resource;
import haxe.Template;
import neko.Lib;
import sys.io.File;

/**
 * ...
 * @author Mike Almond - https://github.com/mikedotalmond
 * 
 * Wrap up compiled Haxe JS output for use as a self-contained module compatible with UMD (Universal Module Definition) patterns
 * 
 * Fields you have exposed with the @:expose metadata are available in the module
 * 
 * Creates modules for AMD (requirejs) and CommonJS, and will expose any exports in a named global object if none of those options are available.
 * 
 * If needed, `nekotools boot UMDWrap.n` will create an executable version of the tool.
 * 
 * Based on the templates at https://github.com/umdjs/umd
 */

using Main.VarNameCheck;
using StringTools;

class Main {
	
	// NOTE: Any source mapping will be broken by this process - sourceMappingURL is removed from the end, and line numbers are shifted down by 15
	// NOTE: Apply this process post-build, before any minification or obfuscation
	// NOTE: These begin/end pairs depend on the format of the Haxe JS compiler not changing.... so can break easily.
	
	static var Begin_NoExports = '(function ()';
	static var End_NoExports = ')();';
	
	static var Begin_WithExports = '(function ($$hx_exports)';
	static var End_WithExports = ')(typeof window != "undefined" ? window : exports);';
	
	
	static function main() {
		Sys.println('UMDWrap');
		Sys.println('-------');
		
		// read commandline argument pairs
		var args = getArgumentPairs();
		var inName = args.get('-in');
		var outName	= args.get('-out');
		
		if (inName == null || outName == null) {
			Sys.println('ERROR: You have to specify the input.js and output.js');
			instructions();
		}
		
		inName 	= inName.trim();
		outName = outName.trim();
		
		Sys.println('Loading "$inName"');
		
		var outJS = null;
		var inJS = null;
		
		// load js
		try {
			inJS = File.getContent(inName);
		} catch (err:Dynamic) {
			Sys.println('ERROR: Unable to read js file "$inName"');
			instructions();
		}
		
		// wrap
		if (StringTools.startsWith(inJS, Begin_NoExports)) {
			outJS = wrapModule(inJS, Begin_NoExports, End_NoExports);
		} else if (StringTools.startsWith(inJS, Begin_WithExports)) {
			outJS = wrapModule(inJS, Begin_WithExports, End_WithExports);
		}
		
		// save wrapped output
		if (outJS != null) {
			Sys.println('Saving module to $outName');
			try {
				File.saveContent(outName, outJS);
			} catch (err:Dynamic) {
				Sys.println('ERROR: Unable to save module to $outName');
				instructions();
			}
		} else {
			Sys.println('ERROR: Unexpected JS in $inName - Was is compiled by Haxe?');
			instructions();
		}
		
		// done
		Sys.println('');
	}
	
	
	static function getArgumentPairs() {
		
		var args = Sys.args();
		var map = new Map<String,String>();
		
		while (args.length > 1) map.set(args.shift(), args.shift());
		
		return map;
	}
	
	
	static function wrapModule(input:String, start:String, end:String) {
		
		var tpl = new Template(Resource.getString('template'));
		
		var haveExports = start == Begin_WithExports;
		
		// 
		var trimmed = input.substr(1); // trim the initial '('
		
		var i 	= trimmed.lastIndexOf(end);
		trimmed = trimmed.substr(0, i);
		
		return tpl.execute({
			haveExports:haveExports,
			factoryCode:trimmed,
		});
	}
	
	
	/**
	 * Show instructions and exit.
	 */
	static function instructions() {
		Sys.println('neko UMDWrap.n -in inFile -out outFile');
		Sys.println('');
		Sys.exit(1);
	}
}

class VarNameCheck {
	static function containsIllegals(test:String):Bool {
		return !(~/^[a-zA-Z_][a-zA-Z0-9_]*$/g.match(test)); // only allow a-Z 0-9 and underscore for var names
	}
}