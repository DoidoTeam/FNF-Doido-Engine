package;

import data.*;
import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxGame;
import openfl.display.Sprite;
import data.FPSCounter;
import lime.app.Application;
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import openfl.Lib;
import data.Discord.DiscordClient;

using StringTools;

class Main extends Sprite
{
	public static var fpsVar:FPSCounter;

	public function new()
	{
		super();
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);

		#if DISCORD_RPC
		if (!DiscordClient.isInitialized) {
			DiscordClient.initialize();
			Application.current.window.onClose.add(function() {
				DiscordClient.shutdown();
			});
		}
		#end

		addChild(new FlxGame(0, 0, Init, 120, 120, true));

		#if desktop
		fpsVar = new FPSCounter(10, 3, 0xFFFFFF);
		addChild(fpsVar);
		#end
	}

	public static var gFont:String = Paths.font("vcr.ttf");
	
	public static var skipTrans:Bool = true; // starts on but it turns false inside Init
	public static function switchState(?target:FlxState):Void
	{
		var trans = new GameTransition(false);
		trans.finishCallback = function()
		{
			if(target != null)		
				FlxG.switchState(target);
			else
				FlxG.resetState();
		}

		if(skipTrans)
		{
			trans.finishCallback();
			return;
		}
		
		FlxG.state.openSubState(trans);
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

	function onCrash(e:UncaughtErrorEvent):Void
	{
		var errMsg:String = "";
		var path:String;
		var callStack:Array<StackItem> = CallStack.exceptionStack(true);
		var dateNow:String = Date.now().toString();

		dateNow = dateNow.replace(" ", "_");
		dateNow = dateNow.replace(":", "'");

		path = "./crash/" + "DoidoEngine_" + dateNow + ".txt";

		for (stackItem in callStack)
		{
			switch (stackItem)
			{
				case FilePos(s, file, line, column):
					errMsg += file + " (line " + line + ")\n";
				default:
					Sys.println(stackItem);
			}
		}

		errMsg += "Uncaught Error: " + e.error + "\nPlease report this error to the developers! Crash Handler written by: sqirra-rng";

		if (!FileSystem.exists("./crash/"))
			FileSystem.createDirectory("./crash/");

		File.saveContent(path, errMsg + "\n");

		Sys.println(errMsg);
		Sys.println("Crash dump saved in " + Path.normalize(path));

		Application.current.window.alert(errMsg, "Error!");
		DiscordClient.shutdown();
		Sys.exit(1);
	}
}