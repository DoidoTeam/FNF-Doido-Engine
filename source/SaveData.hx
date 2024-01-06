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
			"Makes you able to press keys freely without missing notes"
		],
		"Downscroll" => [
			false,
			CHECKMARK,
			"Makes the notes go down instead of up"
		],
		"Middlescroll" => [
			false,
			CHECKMARK,
			"Disables the opponent's notes and moves yours to the middle"
		],
		"Antialiasing" => [
			true,
			CHECKMARK,
			"Disabling it might increase the fps at the cost of smoother sprites"
		],
		"Note Splashes" => [
			"ON",
			SELECTOR,
			"Whether a splash appear when you hit a note perfectly",
			["ON", "PLAYER ONLY", "OFF"],
		],
		"Ratings on HUD" => [
			true,
			CHECKMARK,
			"Makes the ratings stick on the HUD"
		],
		"Framerate Cap"	=> [
			120,
			SELECTOR,
			"Self explanatory",
			[30, 360]
		],
		"FPS Counter" => [
			true,
			CHECKMARK,
			"Whether you want a counter showing your framerate and memory usage counter in the corner of the game",
		],
		
		"Split Holds" => [
			false,
			CHECKMARK,
			"Cuts the end of each hold note like classic engines did"
		],
		"Smooth Healthbar" => [
			true,
			CHECKMARK,
			"Makes the healthbar go up and down smoothly"
		],
		"Song Timer" => [
			true,
			CHECKMARK,
			"Makes the song timer visible"
		],
		
		"Cutscenes" => [
			"ON",
			SELECTOR,
			"Decides if the song cutscenes should play",
			["ON", "FREEPLAY OFF", "OFF"],
		],

		// this one doesnt actually appear at the regular options menu
		"Song Offset" => [
			0,
			SELECTOR,
			"no one is going to see this anyway whatever",
			[-500, 500],
		],
	];
	
	public static var saveFile:FlxSave;
	public static function init()
	{
		saveFile = new FlxSave();
		saveFile.bind("settings",	"Doido-Engine-FNF"); // use these for settings
		FlxG.save.bind("save-data", "Doido-Engine-FNF"); // these are for other stuff
		load();

		Controls.load();
		Highscore.load();
		
		// uhhh
		subStates.editors.ChartAutoSaveSubState.load();
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
		
		if(Main.fpsCount != null)
			Main.fpsCount.visible = data.get("FPS Counter");

		FlxSprite.defaultAntialiasing = data.get("Antialiasing");
	}
}