package;

//import backend.game.*;
import backend.system.FPSCounter;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import flixel.input.keyboard.FlxKey;
import haxe.CallStack;
import haxe.io.Path;
import openfl.Lib;
import openfl.display.Sprite;
//import openfl.events.UncaughtErrorEvent;
//import flixel.util.typeLimit.NextState;

#if desktop
import backend.system.ALSoftConfig;
#end

#if !html5
import sys.FileSystem;
import sys.io.File;
#end

class Main extends Sprite
{
	public static var fpsCounter:FPSCounter;

	// Use these to customize your mod further!
	public static final savePath:String = "DiogoTV/DoidoEngine4";
	public static var globalFont:String;

	public function new()
	{
		super();
		// thanks @sqirradotdev
		//Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onUncaughtError);

		/*var ws:Array<String> = SaveData.displaySettings.get("Window Size")[0].split("x");
		var windowSize:Array<Int> = [Std.parseInt(ws[0]),Std.parseInt(ws[1])];*/

		addChild(new FlxGame(1280, 720, Init, 60, 60, true));
		globalFont = Assets.font("vcr");

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
}
