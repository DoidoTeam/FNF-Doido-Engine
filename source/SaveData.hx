package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import data.Highscore;

enum SettingType
{
	CHECKMARK;
	SELECTOR;
}
class SaveData
{
	public static var data:Map<String, Dynamic> = [];
	public static var displaySettings:Map<String, Dynamic> = [
		"Ghost Tapping" => [
			true,
			CHECKMARK,
			"Makes you able to press keys freely without missing notes."
		],
		"Downscroll" => [
			false,
			CHECKMARK,
			"Makes the notes go down instead of up."
		],
		"Middlescroll" => [
			false,
			CHECKMARK,
			"Disables the opponent's notes and moves yours to the middle."
		],
		"Antialiasing" => [
			true,
			CHECKMARK,
			"Disabling it might increase the fps at the cost of smoother sprites."
		],
		"Note Splashes" => [
			"ON",
			SELECTOR,
			"Whether a splash appear when you hit a note perfectly.",
			["ON", "PLAYER", "OFF"],
		],
		"Ratings on HUD" => [
			true,
			CHECKMARK,
			"Makes the ratings stick on the HUD."
		],
		"Framerate Cap"	=> [
			120,
			SELECTOR,
			"Self explanatory.",
			[30, 360]
		],

		// this one doesnt actually appear at the regular options menu
		"Song Offset" => [
			0,
			[-500, 500]
		],
	];

	/*public static var keyControls:Map<String, Array<FlxKey>> = [
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
	];*/
	
	public static var saveFile:FlxSave;
	public static function init()
	{
		saveFile = new FlxSave();
		saveFile.bind("settings",	"Doido-Engine-FNF"); // use these for settings
		FlxG.save.bind("save-data", "Doido-Engine-FNF"); // these are for other stuff
		load();

		Controls.load();
		Highscore.load();
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
		save();
	}
	
	public static function save()
	{
		saveFile.data.settings = data;
		saveFile.flush();
		update();
	}

	public static function update()
	{
		Main.changeFramerate(data.get("Framerate Cap"));

		FlxSprite.defaultAntialiasing = data.get("Antialiasing");
	}
}