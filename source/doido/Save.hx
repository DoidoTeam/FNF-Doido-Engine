package doido;

import flixel.util.FlxSave;

@:keep
@:structInit
class SaveVariables
{
	// gameplay
	public var test:String = 'bullshit';
	// visuals
	public var fpsCounter:Bool = #if desktop true #else false #end;
	// graphics
	public var fps:Int = 60;
	public var gpuCaching:Bool = false;
	public var antialiasing:Bool = true;
	// sound
	public var volume:Float = 1;
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
		if(file == null)
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
		
		flixel.FlxSprite.defaultAntialiasing = data.antialiasing;
		
		if (Main.fpsCounter != null)
			Main.fpsCounter.visible = data.fpsCounter;
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