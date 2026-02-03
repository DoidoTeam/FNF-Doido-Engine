package backend.game;

import flixel.util.FlxSave;

@:keep
@:structInit
class SaveVariables
{
	public var test:String = 'bullshit';
	
	public var fps:Int = 60;
	
	public var fpsCounter:Bool = false;
}

class Save
{
	public static var data:SaveVariables = {};
	public static var defaultData:SaveVariables = {};
	
	public static function init()
	{
		load();
	}
	
	public static function save()
	{
		var file = new FlxSave();
		file.bind("settings");
		
		for (key in Reflect.fields(data))
			Reflect.setField(file.data, key, Reflect.field(data, key));

		file.close();
		update();
	}
	
	public static function load()
	{
		var file = new FlxSave();
		file.bind("settings");

		if (file != null && file.data != null)
		{
			for (key in Reflect.fields(data))
			{
				if (Reflect.hasField(file.data, key))
					Reflect.setField(data, key, Reflect.field(file.data, key));
			}
		}
		file.close();
		save();
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
		
		/*if (Main.fpsVar != null)
			Main.fpsVar.visible = data.showFPS;

		if (file.data.framerate == null)
			data.framerate = Std.int(FlxMath.bound(FlxG.stage.application.window.displayMode.refreshRate, 60, 240));
		*/
	}
}
