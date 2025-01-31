package;

import backend.game.*;
import backend.system.FPSCounter;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import flixel.input.keyboard.FlxKey;
import haxe.CallStack;
import haxe.io.Path;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.UncaughtErrorEvent;
import flixel.util.typeLimit.NextState;

#if desktop
import backend.system.ALSoftConfig;
#end

#if !html5
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

class Main extends Sprite
{
	public static var fpsCounter:FPSCounter;

	// Use these to customize your mod further!
	public static final savePath:String = "DiogoTV/DoidoEngine";
	public static var gFont:String = Paths.font("vcr.ttf");

	public function new()
	{
		super();
		// thanks @sqirradotdev
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onUncaughtError);

		var ws:Array<String> = SaveData.displaySettings.get("Window Size")[0].split("x");
		var windowSize:Array<Int> = [Std.parseInt(ws[0]),Std.parseInt(ws[1])];

		addChild(new FlxGame(windowSize[0], windowSize[1], Init, 120, 120, true));

		#if android
		FlxG.android.preventDefaultKeys = [BACK];
		#elseif desktop
		addChild(fpsCounter = new FPSCounter(5, 3));
		#end

		#if ENABLE_PRINTING
		Logs.init();
		#end

		// shader coords fix
		FlxG.signals.focusGained.add(function() {
			resetCamCache();
		});
		FlxG.signals.gameResized.add(function(w, h) {
			resetCamCache();
		});
		// Prevent flixel from listening to key inputs when switching fullscreen mode
		// also lets you fullscreen with F11
		// thanks @nebulazorua, @crowplexus, @diogotvv
		FlxG.stage.addEventListener(openfl.events.KeyboardEvent.KEY_DOWN, (e) ->
		{
			if (e.keyCode == FlxKey.F11)
				FlxG.fullscreen = !FlxG.fullscreen;
			
			if (e.keyCode == FlxKey.ENTER && e.altKey)
				e.stopImmediatePropagation();
		}, false, 100);
	}
	
	function resetCamCache()
	{
		if(FlxG.cameras != null) {
			for(cam in FlxG.cameras.list) {
				if(cam != null && cam.filters != null)
					resetSpriteCache(cam.flashSprite);
			}
		}
		if(FlxG.game != null)
			resetSpriteCache(FlxG.game);
	}

	static function resetSpriteCache(sprite:Sprite):Void {
		@:privateAccess {
			sprite.__cacheBitmap 	 = null;
			sprite.__cacheBitmapData = null;
		}
	}

	function onUncaughtError(e:UncaughtErrorEvent):Void
	{
		e.preventDefault();
		e.stopImmediatePropagation();

		var path:String;
		var exception:String = 'Exception: ${e.error}\n';
		var stackTraceString = exception + StringTools.trim(CallStack.toString(CallStack.exceptionStack(true)));
		var dateNow:String = Date.now().toString().replace(" ", "_").replace(":", "'");

		path = 'crash/DoidoEngine_${dateNow}.txt';

		#if sys
		if (!FileSystem.exists("crash/"))
			FileSystem.createDirectory("crash/");
		File.saveContent(path, '${stackTraceString}\n');
		#end

		var normalPath:String = Path.normalize(path);

		Logs.print(stackTraceString, ERROR, true, true, false, false);
		Logs.print('Crash dump saved in $normalPath', WARNING, true, true, false, false);

		// byebye
		#if (flixel < "6.0.0")
		FlxG.bitmap.dumpCache();
		#end

		FlxG.bitmap.clearCache();
		CoolUtil.playMusic();

		Main.skipTrans = true;
		Main.switchState(new CrashHandlerState(stackTraceString + '\n\nCrash log created at: "${normalPath}"'));
	}
	
	public static var activeState:FlxState;
	
	public static var skipClearMemory:Bool = false; // dont
	public static var skipTrans:Bool = true; // starts on but it turns false inside Init
	public static var lastTransition:String = '';
	public static function switchState(?target:NextState, transition:String = 'funkin'):Void
	{
		lastTransition = transition;
		var trans = new GameTransition(false, transition);
		trans.finishCallback = function()
		{
			if(target != null)		
				FlxG.switchState(target);
			else
				FlxG.resetState();
		};

		if(skipTrans)
			return trans.finishCallback();
		
		//FlxG.state.openSubState(trans);
		if(activeState != null)
			activeState.openSubState(trans);
	}
	
	// you could just do Main.switchState() but whatever
	public static function resetState(transition:String = 'funkin'):Void
		return switchState(null, transition);

	// so you dont have to type it every time
	public static function skipStuff(?ohreally:Bool = true):Void
	{
		skipClearMemory = ohreally;
		skipTrans = ohreally;
	}

	public static function changeFramerate(rawFps:Float = 120)
	{
		var newFps:Int = Math.floor(rawFps);

		if(newFps > FlxG.updateFramerate)
		{
			FlxG.updateFramerate = newFps;
			FlxG.drawFramerate   = newFps;
		}
		else
		{
			FlxG.drawFramerate   = newFps;
			FlxG.updateFramerate = newFps;
		}
	}
}
