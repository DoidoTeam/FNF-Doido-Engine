package;

import doido.objects.ui.*;
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
    //later we should have the window size options be determined automatically, probably
    var gameWidth:Int = 1280;
    var gameHeight:Int = 720;
    var framerate:Int = 60;
    var skipSplash:Bool = true;

    public static final savePath:String = "DiogoTV/DEPudim";
    public static final internalVer:String = "Pre-Alpha";
    public static var fpsCounter:FPSCounter;
    public static var globalFont:String;

    public function new()
    {
        super();
        initGame();
        addChild(fpsCounter = new FPSCounter(5, 3));
        fixes();
    }

    function initGame() {
        // adding the crash handler
        openfl.Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(
            UncaughtErrorEvent.UNCAUGHT_ERROR, onUncaughtError
        );

        Logs.init(); // custom logging shit

        var game:FlxGame = new FlxGame(gameWidth, gameHeight, Init, framerate, framerate, skipSplash);
        globalFont = Assets.font("vcr"); // we need to initialize this before the font ever gets used, otherwise it wont be found
        @:privateAccess
        game._customSoundTray = SoundTray;
        addChild(game);
    }

    function onUncaughtError(e:UncaughtErrorEvent):Void {
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
		//CoolUtil.playMusic();

		MusicBeat.skipTrans = true;
		MusicBeat.switchState(
            new doido.system.CrashHandler(
                'Crash log created at: "${normalPath}"\n\n' + stackTraceString
            )
        );
	}

    function fixes() {
        // shader coords fix
		FlxG.signals.focusGained.add(resetCamCache);
		FlxG.signals.gameResized.add((w,h) -> {resetCamCache();});
		
        // fullscreen bind fix
		FlxG.stage.addEventListener(openfl.events.KeyboardEvent.KEY_DOWN, fullscreen, false, 100);
    }

    function fullscreen(e:openfl.events.KeyboardEvent) {
        if (e.keyCode == FlxKey.F11)
            FlxG.fullscreen = !FlxG.fullscreen;
        
        if (e.keyCode == FlxKey.ENTER && e.altKey)
            e.stopImmediatePropagation();
    }

    function resetCamCache() {
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

@:deprecated("Paths was moved to Assets")
typedef Paths = doido.Assets;