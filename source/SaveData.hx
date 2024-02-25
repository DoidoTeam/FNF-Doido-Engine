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
		"Single Rating" => [
			false,
			CHECKMARK,
			"Makes only one rating appear at a time",
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
			60, // 120
			SELECTOR,
			"Self explanatory",
			[30, 360]
		],
		"FPS Counter" => [
			false,
			CHECKMARK,
			"Whether you want a counter showing your framerate and memory usage counter in the corner of the game",
		],
		"Countdown on Unpause" => [
			true,
			CHECKMARK,
			"Whether you want to have a countdown when unpausing the game",
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
		'Flashing Lights' => [
			"ON",
			SELECTOR,
			"Whether to show flashing lights and colors",
			["ON", "REDUCED", "OFF"]
		],
		'Unfocus Freeze' => [
			true,
			CHECKMARK,
			"Freezes the game when unfocusing the window",
		],
		'Hitsounds' => [
			"OFF",
			SELECTOR,
			"Whether to play hitsounds whenever you hit a note",
			["OSU", "OFF"]
		],
		'Hitsound Volume' => [
			10,
			SELECTOR,
			"Only works when Hitsounds is enabled",
			[0, 10]
		],

		// this one doesnt actually appear at the regular options menu
		"Song Offset" => [
			0,
			SELECTOR,
			"no one is going to see this anyway whatever",
			[-500, 500],
		]
	];
	
	public static var saveSettings:FlxSave = new FlxSave();
	public static var saveControls:FlxSave = new FlxSave();
	public static function init()
	{
		saveSettings.bind("settings",	Main.savePath); // use these for settings
		saveControls.bind("controls", 	Main.savePath); // controls :D
		FlxG.save.bind("save-data", 	Main.savePath); // these are for other stuff
		
		load();
		Controls.load();
		Highscore.load();
		subStates.editors.ChartAutoSaveSubState.load(); // uhhh
	}
	
	public static function load()
	{
		if(saveSettings.data.volume != null)
			FlxG.sound.volume = saveSettings.data.volume;
		if(saveSettings.data.muted != null)
			FlxG.sound.muted  = saveSettings.data.muted;

		if(saveSettings.data.settings == null || Lambda.count(displaySettings) != Lambda.count(saveSettings.data.settings))
		{
			for(key => values in displaySettings)
				data[key] = values[0];
			
			saveSettings.data.settings = data;
		}
		
		data = saveSettings.data.settings;
		save();
	}
	
	public static function save()
	{
		saveSettings.data.settings = data;
		saveSettings.flush();
		update();
	}

	public static function update()
	{
		Main.changeFramerate(data.get("Framerate Cap"));
		
		if(Main.fpsCount != null)
			Main.fpsCount.visible = data.get("FPS Counter");

		FlxSprite.defaultAntialiasing = data.get("Antialiasing");

		FlxG.autoPause = data.get('Unfocus Freeze');
	}
}