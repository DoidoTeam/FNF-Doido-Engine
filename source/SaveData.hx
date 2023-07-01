package;

import flixel.FlxG;
import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;

enum SettingType
{
	CHECKMARK;
	SELECTOR;
}
class SaveData
{
	public static var data:Map<String, Dynamic> = [];
	public static var displaySettings:Map<String, Dynamic> = [
		"Antialiasing" => [true, CHECKMARK],
	];
	
	public static var saveFile:FlxSave;
	public static function init()
	{
		saveFile = new FlxSave();
		saveFile.bind("settings",	"Doido-Engine-FNF"); // use these for settings
		FlxG.save.bind("save-data", "Doido-Engine-FNF"); // these are for other stuff
		load();
		save();
	}
	
	public static function load()
	{
		if(saveFile.data.settings == null || Lambda.count(displaySettings) != Lambda.count(saveFile.data.settings))
		{
			for(key => values in displaySettings)
				data[key] = values[0];
			
			saveFile.data.settings = data;
		}
		
		data = saveFile.data.settings;
	}
	
	public static function save()
	{
		saveFile.data.settings = data;
		saveFile.flush();
	}

	public static var gameControls:Map<String, Array<FlxKey>> = [
		'LEFT' 		=> 	[A, FlxKey.LEFT],
		'DOWN' 		=> 	[S, FlxKey.DOWN],
		'UP' 		=>	[W, FlxKey.UP],
		'RIGHT' 	=> 	[D, FlxKey.RIGHT],

		'UI_LEFT' 	=>	[A, FlxKey.LEFT],
		'UI_DOWN' 	=>	[S, FlxKey.DOWN],
		'UI_UP' 	=> 	[W, FlxKey.UP],
		'UI_RIGHT'	=>	[D, FlxKey.RIGHT],

		'ACCEPT' 	=> 	[FlxKey.SPACE, 	FlxKey.ENTER],
		'BACK' 		=>	[X,				FlxKey.BACKSPACE,	FlxKey.ESCAPE],
		'PAUSE' 	=> 	[P,				FlxKey.ENTER,		FlxKey.ESCAPE],
		'RESET' 	=> 	[R, 			FlxKey.NONE],
	];
}