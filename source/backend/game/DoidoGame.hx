package backend.game;

import flixel.FlxGame;
import haxe.CallStack;
import haxe.io.Path;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

/**
 * FlxGame with error handling
 * 
 * thanks @crowplexus
 * thanks @crowplexus
 * thanks @crowplexus
 * thanks @crowplexus
 * thanks @crowplexus
**/
class DoidoGame extends FlxGame {
	var _viewingCrash:Bool = false;

	/**
	 * Used to instantiate the guts of the flixel game object once we have a valid reference to the root.
	 */
	override function create(_):Void {
		try
			super.create(_)
		catch (e:haxe.Exception)
			return exceptionCaught(e, 'create');
	}

	/**
	 * Called when the user on the game window
	 */
	override function onFocus(_):Void {
		try
			super.onFocus(_)
		catch (e:haxe.Exception)
			return exceptionCaught(e, 'onFocus');
	}

	/**
	 * Called when the user clicks off the game window
	 */
	override function onFocusLost(_):Void {
		try
			super.onFocusLost(_)
		catch (e:haxe.Exception)
			return exceptionCaught(e, 'onFocusLost');
	}

	/**
	 * Handles the `onEnterFrame` call and figures out how many updates and draw calls to do.
	 */
	override function onEnterFrame(_):Void {
		/*
			if (_viewingCrash)
				return;
		 */
		try
			super.onEnterFrame(_)
		catch (e:haxe.Exception)
			return exceptionCaught(e, 'onEnterFrame');
	}

	/**
	 * This function is called by `step()` and updates the actual game state.
	 * May be called multiple times per "frame" or draw call.
	 */
	override function update():Void {
		if (_viewingCrash)
			return;
		try
			super.update()
		catch (e:haxe.Exception)
			return exceptionCaught(e, 'update');
	}

	/**
	 * Goes through the game state and draws all the game objects and special effects.
	 */
	override function draw():Void {
		if (_viewingCrash)
			return;
		try
			super.draw()
		catch (e:haxe.Exception)
			return exceptionCaught(e, 'draw');
	}

	@:allow(flixel.FlxG)
	override function onResize(_):Void {
		if (_viewingCrash)
			return;
		super.onResize(_);
	}

	/**
	 * Catches an Exception that was caused by a function executed in-game
	 * 
	 * Code was entirely made by sqirra-rng for their fnf engine named "Izzy Engine", big props to them!!!
	 * very cool person for real they don't get enough credit for their work
	 */

	private function exceptionCaught(e:haxe.Exception, func:String = null) {
		if (_viewingCrash)
			return;

		var path:String;
		var callStack:Array<StackItem> = CallStack.exceptionStack(true);
		var fileStack:Array<String> = [];
		var dateNow:String = Date.now().toString();

		dateNow = StringTools.replace(dateNow, " ", "_");
		dateNow = StringTools.replace(dateNow, ":", "'");

		path = 'crash/DoidoEngine_${dateNow}.txt';

		for (stackItem in callStack) {
			switch (stackItem) {
				case CFunction:
					fileStack.push('Non-Haxe (C) Function');
				case Module(moduleName):
					fileStack.push('Module (${moduleName})');
				case FilePos(parent, file, line, col):
					switch (parent) {
						case Method(cla, func):
							fileStack.push('${file} ${cla.split(".").last()}.$func() - (line ${line})');
						case _:
							fileStack.push('${file} - (line ${line})');
					}
				case Method(className, method):
					fileStack.push('${className} (method ${method})');
				case LocalFunction(name):
					fileStack.push('Local Function (${name})');
				default:
					Logs.print(stackItem, ERROR, true, true, false, false);
			}
		}

		fileStack.insert(0, "Exception: " + e.message);

		final msg:String = fileStack.join('\n');

		#if sys
		if (!FileSystem.exists("crash/"))
			FileSystem.createDirectory("crash/");
		File.saveContent(path, '${msg}\n');
		#end

		final funcThrew:String = '${func != null ? ' thrown at "${func}" function' : ""}';

		Logs.print(msg + funcThrew, ERROR, true, true, false, false);
		Logs.print(e.message, ERROR, true, true, false, false);
		Logs.print('Crash dump saved in ${Path.normalize(path)}', WARNING, true, true, false, false);

		// make sure to not do ANYTHING flixel related as much as possible from this point onwards.

		FlxG.bitmap.dumpCache();
		FlxG.bitmap.clearCache();

		// this should hopefully cover sounds playing..
		CoolUtil.playMusic();
		//AssetHelper.destroyAllSounds();

		Main.instance.addChild(new CrashHandler(e.details(), Path.normalize(path)));
		_viewingCrash = true;
	}
}