package;

import doido.objects.system.*;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.input.keyboard.FlxKey;
import haxe.CallStack;
import haxe.io.Path;
import openfl.display.Sprite;
import openfl.events.UncaughtErrorEvent;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

class Main extends Sprite
{
	public static var game:FlxGame;

	public static var gameWidth:Int = 1280;
	public static var gameHeight:Int = 720;

	var framerate:Int = 60;
	var skipSplash:Bool = true;

	public static final sysPath:String = "DoidoEngine";
	public static final savePath:String = "DiogoTV/DEPudim";
	public static final internalVer:String = "Alpha 1";
	public static var fpsCounter:FPSCounter;
	public static var globalFont:String;

	public function new()
	{
		super();
		#if android initAndroid(); #end
		initGame();
		#if desktop addChild(fpsCounter = new FPSCounter()); #end
		fixes();
	}

	function initGame()
	{
		// adding the crash handler
		openfl.Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onUncaughtError);
		Logs.init(); // custom logging shit

		game = new FlxGame(gameWidth, gameHeight, Init, framerate, framerate, skipSplash);
		globalFont = Assets.font("vcr"); // we need to initialize this before the font ever gets used, otherwise it wont be found
		@:privateAccess
		game._customSoundTray = SoundTray;
		addChild(game);
	}

	#if android
	function initAndroid()
	{
		#if EXTERNAL_PATH
		var launched:Bool = false;
		while (!extension.androidtools.os.Environment.isExternalStorageManager())
		{
			if (!launched)
			{
				launched = true;
				extension.androidtools.Settings.requestSetting('MANAGE_APP_ALL_FILES_ACCESS_PERMISSION');
			}
		}

		var path = '${extension.androidtools.os.Environment.getExternalStorageDirectory()}/$sysPath';
		Assets.createDir(path);
		Sys.setCwd(path);
		#else
		Sys.setCwd(haxe.io.Path.addTrailingSlash(extension.androidtools.content.Context.getExternalFilesDir()));
		#end
	}
	#end

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
		MusicBeat.stopMusic();
		doido.Cache.clearCache();

		MusicBeat.skipTrans = true;
		MusicBeat.switchState(new doido.system.CrashHandler('Crash log created at: "${normalPath}"\n\n' + stackTraceString));
	}

	function fixes()
	{
		// shader coords fix
		FlxG.signals.focusGained.add(resetCamCache);
		FlxG.signals.gameResized.add((w, h) ->
		{
			resetCamCache();
			scaleFps();
		});

		#if debug
		FlxG.debugger.toggleKeys = [];
		#end

		// fullscreen bind fix
		FlxG.stage.addEventListener(openfl.events.KeyboardEvent.KEY_DOWN, keyDown, false, 100);

		// PLUGINS!!
		FlxG.plugins.addPlugin(new InputDelayHandler());
		#if SCREENSHOT_FEATURE
		FlxG.plugins.addPlugin(new doido.system.Screenshot());
		#end
	}

	function keyDown(e:openfl.events.KeyboardEvent)
	{
		if (e.keyCode == FlxKey.F3)
		{
			Save.data.fpsCounter = !Save.data.fpsCounter;
			fpsCounter.visible = Save.data.fpsCounter;
			Save.save();
		}

		if (e.keyCode == FlxKey.F11)
			FlxG.fullscreen = !FlxG.fullscreen;

		if (e.keyCode == FlxKey.ENTER && e.altKey)
			e.stopImmediatePropagation();

		#if debug
		if (e.keyCode == FlxKey.F2 && e.shiftKey)
			FlxG.debugger.visible = !FlxG.debugger.visible;
		#end
	}

	function resetCamCache()
	{
		if (FlxG.cameras != null)
		{
			for (cam in FlxG.cameras.list)
			{
				if (cam != null && cam.filters != null)
					resetSpriteCache(cam.flashSprite);
			}
		}
		if (FlxG.game != null)
			resetSpriteCache(FlxG.game);
	}

	static function resetSpriteCache(sprite:Sprite):Void
	{
		@:privateAccess {
			sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}

	public static var fpsX(default, set):Float = 5;
	public static var fpsY(default, set):Float = 5;
	public static var fpsWidth(get, never):Float;
	public static var fpsHeight(get, never):Float;

	public static function set_fpsX(f:Float)
	{
		fpsX = f;
		scaleFps();
		return f;
	}

	public static function set_fpsY(f:Float)
	{
		fpsY = f;
		scaleFps();
		return f;
	}

	public static function get_fpsWidth():Float
		return fpsCounter?.bgWidth ?? 80;

	public static function get_fpsHeight():Float
		return fpsCounter?.bgHeight ?? 50;

	public static function setFpsPos(x:Float, y:Float)
	{
		if (fpsCounter == null)
			return;

		@:bypassAccessor {
			fpsX = x;
			fpsY = y;
		}
		scaleFps();
	}

	public static function scaleFps()
	{
		if (fpsCounter == null)
			return;

		var scaleX:Float = FlxG.stage.window.width / FlxG.width;
		var scaleY:Float = FlxG.stage.window.height / FlxG.height;
		var scale:Float = Math.min(scaleX, scaleY);

		fpsCounter.scaleX = scale;
		fpsCounter.scaleY = scale;
		fpsCounter.x = game.x + (fpsX * scale);
		fpsCounter.y = game.y + (fpsY * scale);
	}

	public static var windowSizes(get, never):Array<String>;
	public static var windowScales:Array<Float> = [0.5, 2 / 3, 0.75, 0.8, 0.9, 1, 16 / 15, 1.25, 1.5, 2, 3];

	public static function get_windowSizes():Array<String>
	{
		var out:Array<String> = [];

		for (s in windowScales)
			out.push('${Math.ceil(gameWidth * s)}x${Math.ceil(gameHeight * s)}');

		return (out);
	}

	public static function setWindowSize(key:String):Void
	{
		#if desktop
		var size:Array<String> = key.split("x");
		if (size.length != 2)
			return;

		var w:Null<Int> = Std.parseInt(size[0]);
		var h:Null<Int> = Std.parseInt(size[1]);
		if (w == null || h == null)
			return;

		var window = lime.app.Application.current.window;

		var centerX = window.x + window.width / 2;
		var centerY = window.y + window.height / 2;
		window.resize(w, h);

		window.x = Std.int(centerX - w / 2);
		window.y = Std.int(centerY - h / 2);
		#end
	}

	public static function alert(?message:String, ?title:String)
	{
		#if android
		extension.androidtools.Tools.showAlertDialog(title, message, {name: "Ok", func: null});
		#else
		var window = lime.app.Application.current.window;
		window.alert(message, title);
		#end
	}
}

@:deprecated("Paths was moved to Assets")
typedef Paths = doido.Assets;
