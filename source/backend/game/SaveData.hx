package backend.game;

import flixel.FlxSprite;
import flixel.util.FlxSave;
import openfl.system.Capabilities;
import backend.song.Conductor;
import backend.song.Highscore;

/*
	Save data such as options and other things.
*/

enum SettingType
{
	CHECKMARK;
	SELECTOR;
}
class SaveData
{
	public static var data:Map<String, Dynamic> = [];
	public static var displaySettings:Map<String, Dynamic> = [
		/*
		*
		* PREFERENCES
		* 
		*/
		"Window Size" => [
			"1280x720",
			SELECTOR,
			"Change the game's resolution if it doesn't fit your monitor",
			["640x360","854x480","960x540","1024x576","1152x648","1280x720","1366x768","1600x900","1920x1080", "2560x1440", "3840x2160"],
		],
		'Flashing Lights' => [
			"ON",
			SELECTOR,
			"Whether to show flashing lights and colors",
			["ON", "REDUCED", "OFF"]
		],
		"Cutscenes" => [
			"ON",
			SELECTOR,
			"Decides if the song cutscenes should play",
			["ON", "FREEPLAY OFF", "OFF"],
		],
		"FPS Counter" => [
			false,
			CHECKMARK,
			"Whether you want a counter showing your framerate and memory usage counter in the corner of the game",
		],
		'Unfocus Pause' => [
			true,
			CHECKMARK,
			"Pauses the game when the window is unfocused",
		],
		"Countdown on Unpause" => [
			true,
			CHECKMARK,
			"Whether you want to have a countdown when unpausing the game",
		],
		'Discord RPC' => [
			#if DISCORD_RPC
			true,
			#else
			false,
			#end
			CHECKMARK,
			"Whether to use Discord's game activity.",
		],
		"Shaders" => [
			true,
			CHECKMARK,
			"Fancy graphical effects. Disable this if you get GPU related crashes."
		],
		"Low Quality" => [
			false,
			CHECKMARK,
			"Disables extra assets that might make very low end computers lag."
		],
		/*
		*
		* GAMEPLAY
		* 
		*/
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
		"Framerate Cap"	=> [
			60, // 120
			SELECTOR,
			"Self explanatory",
			[30, 360]
		],
		'Hitsounds' => [
			"OFF",
			SELECTOR,
			"Whether to play hitsounds whenever you hit a note",
			["OFF", "OSU", "NSWITCH", "CD"]
		],
		'Hitsound Volume' => [
			100,
			SELECTOR,
			"Only works when Hitsounds aren't off",
			[0, 100]
		],
		/*
		*
		* APPEARANCE
		* 
		*/
		"Note Splashes" => [
			"ON",
			SELECTOR,
			"Whether a splash appears when you hit a note perfectly.\nDisable if it distracts you.",
			["ON", "PLAYER ONLY", "OFF"],
		],
		"Hold Splashes" => [
			true,
			CHECKMARK,
			"Whether a splash appears when you completely press a hold note.\nDisable if it distracts you. (Only works if Note Splashes is enabled)."
		],
		"Antialiasing" => [
			true,
			CHECKMARK,
			"Disabling it might increase the fps at the cost of smoother sprites"
		],
		"Split Holds" => [
			false,
			CHECKMARK,
			"Cuts the end of each hold note like classic engines did"
		],
		"Static Hold Anim" => [
			true,
			CHECKMARK,
			"Whether the character stays static when playing a hold note."
		],
		"Single Rating" => [
			false,
			CHECKMARK,
			"Makes only one rating appear at a time",
		],
		"Ratings on HUD" => [
			true,
			CHECKMARK,
			"Makes the ratings stick on the HUD"
		],
		"Song Timer" => [
			true,
			CHECKMARK,
			"Makes the song timer visible"
		],
		/*
		*
		* EXTRA STUFF
		* 
		*/
		"Song Offset" => [
			0,
			SELECTOR,
			"no one is going to see this anyway whatever",
			[-100, 100],
		],
		"Input Offset" => [
			0,
			SELECTOR,
			"same xd",
			[-100, 100],
		],
	];
	
	public static var saveSettings:FlxSave = new FlxSave();
	public static var saveControls:FlxSave = new FlxSave();
	public static function init()
	{
		saveSettings.bind("settings"); // use these for settings
		saveControls.bind("controls"); // controls :D
		FlxG.save.bind("save-data"); // these are for other stuff, not recquiring to access the SaveData class
		
		load();
		Controls.load();
		Highscore.load();
		subStates.editors.ChartAutoSaveSubState.load(); // uhhh
		updateWindowSize();
	}
	
	public static function load()
	{
		if(saveSettings.data.volume != null)
			FlxG.sound.volume = saveSettings.data.volume;
		if(saveSettings.data.muted != null)
			FlxG.sound.muted  = saveSettings.data.muted;

		if(saveSettings.data.settings == null)
		{
			for(key => values in displaySettings)
				data[key] = values[0];
			
			saveSettings.data.settings = data;
		}
		else
		{
			var freeze:Null<Bool> = saveSettings.data.settings.get("Unfocus Freeze");
			if(freeze != null) {
				saveSettings.data.settings.set("Unfocus Pause", freeze);
				saveSettings.data.settings.remove("Unfocus Freeze");
			}
		}
		
		if(Lambda.count(displaySettings) != Lambda.count(saveSettings.data.settings)) {
			data = saveSettings.data.settings;
			
			for(key => values in displaySettings) {
				if(data[key] == null)
					data[key] = values[0];
			}

			for(key => values in data) {
				if(displaySettings[key] == null)
					data.remove(key);
			}

			saveSettings.data.settings = data;
		}
		
		for(hitsound in Paths.readDir('sounds/hitsounds', [".ogg"], true))
			if(!displaySettings.get("Hitsounds")[3].contains(hitsound))
				displaySettings.get("Hitsounds")[3].insert(1, hitsound);
		
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
		
		if(Main.fpsCounter != null)
			Main.fpsCounter.visible = data.get("FPS Counter");

		FlxSprite.defaultAntialiasing = data.get("Antialiasing");

		FlxG.autoPause = data.get('Unfocus Pause');

		Conductor.musicOffset = data.get('Song Offset');
		Conductor.inputOffset = data.get('Input Offset');

		DiscordIO.check();
	}

	public static function updateWindowSize()
	{
		if(FlxG.fullscreen) return;
		var ws:Array<String> = data.get("Window Size").split("x");
        	var windowSize:Array<Int> = [Std.parseInt(ws[0]),Std.parseInt(ws[1])];
        	FlxG.stage.window.width = windowSize[0];
        	FlxG.stage.window.height= windowSize[1];
		
		// centering the window
		FlxG.stage.window.x = Math.floor(Capabilities.screenResolutionX / 2 - windowSize[0] / 2);
		FlxG.stage.window.y = Math.floor(Capabilities.screenResolutionY / 2 - (windowSize[1] + 16) / 2);
	}
}
