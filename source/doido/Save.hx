package doido;

import doido.song.Conductor;
import doido.system.Discord.DiscordIO;
import flixel.util.FlxSave;

@:keep
@:structInit
class SaveVariables
{
	// add custom saves here!!
	public var test:String = 'bullshit';
	public var modData:Map<String, Dynamic> = [];

	// gameplay
	public var downscroll:Bool = false;
	public var middlescroll:Bool = false;
	public var quantNotes:Bool = false;
	public var slowdownUnpause:Bool = true;
	
	// input
	public var ghostTapping:String = "idle";
	public var musicOffset:Int = 0;
	public var inputOffset:Int = 0;
	public var gamepadDeadzone:Float = 0.15;

	// preferences
	public var darkMode:Bool = true;
	public var discordRPC:Bool = #if DISCORD_RPC true #else false #end;
	public var fpsCounter:Bool = #if desktop true #else false #end;
	public var fasterTransitions:Bool = false;
	public var hitsound:String = "OFF";
	public var hitsoundVolume:Float = 0.4;
	public var flashingLights:String = "ON";
	public var splashNotes:String = "ALWAYS";
	public var developerMode:Bool = false;

	// graphics
	public var fps:Int = 60;
	public var windowSize:String = '${Main.gameWidth}x${Main.gameHeight}';
	public var gpuCaching:Bool = false;
	public var antialiasing:Bool = true;
	public var lowQuality:Bool = false;
	public var shaders:Bool = true;

	// mobile
	public var modernControls:Bool = #if TOUCH_CONTROLS true #else false #end;
	public var invertX:Bool = false;
	public var invertY:Bool = false;

	// sound
	public var volume:Float = 1.0;
	public var muted:Bool = false;
}

class Save
{
	public static var data:SaveVariables = {};
	public static var defaultData:SaveVariables = {};

	public static function init()
	{
		load();

		FlxG.sound.volume = data.volume;
		FlxG.sound.muted = data.muted;
	}

	public static function save(?file:DoidoSave)
	{
		if (file == null)
			file = new DoidoSave("settings");

		for (key in Reflect.fields(data))
			Reflect.setField(file.data, key, Reflect.field(data, key));

		file.close();
		update();
	}

	public static function load()
	{
		var file = new DoidoSave("settings");

		if (file != null && file.data != null)
		{
			for (key in Reflect.fields(data))
			{
				if (Reflect.hasField(file.data, key))
					Reflect.setField(data, key, Reflect.field(file.data, key));
			}
		}
		save(file);
	}

	private static function update()
	{
		if (data.fps > FlxG.drawFramerate)
		{
			FlxG.updateFramerate = data.fps;
			FlxG.drawFramerate = data.fps;
		}
		else
		{
			FlxG.drawFramerate = data.fps;
			FlxG.updateFramerate = data.fps;
		}

		if (Main.fpsCounter != null)
			Main.fpsCounter.visible = data.fpsCounter;

		Conductor.musicOffset = data.musicOffset;
		Conductor.inputOffset = data.inputOffset;

		DiscordIO.check();
	}
}

class DoidoSave extends FlxSave
{
	public function new(name:String)
	{
		super();
		bind(name, Main.savePath);
	}
}
