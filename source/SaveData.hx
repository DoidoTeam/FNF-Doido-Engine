package;

import flixel.FlxG;
import flixel.FlxSprite;
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
			true,
			CHECKMARK,
			"Whether a splash appear when you hit a note perfectly."
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

	public static var keyControls:Map<String, Array<FlxKey>> = [
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
	
	public static var saveFile:FlxSave;
	public static function init()
	{
		saveFile = new FlxSave();
		saveFile.bind("settings",	"Doido-Engine-FNF"); // use these for settings
		FlxG.save.bind("save-data", "Doido-Engine-FNF"); // these are for other stuff
		load();

		var diogoPlaying:Bool = true;
		if(diogoPlaying)
		{
			keyControls.get('LEFT')[0] = FlxKey.Z;
			keyControls.get('DOWN')[0] = FlxKey.X;
			keyControls.get('UP')[0] 	= FlxKey.NUMPADTWO;
			keyControls.get('RIGHT')[0]= FlxKey.NUMPADTHREE;

			keyControls.get('LEFT')[2] = FlxKey.D;
			keyControls.get('DOWN')[2] = FlxKey.F;
			keyControls.get('UP')[2] 	= FlxKey.J;
			keyControls.get('RIGHT')[2]= FlxKey.K;
		}
	}
	
	public static function load()
	{
		if(saveFile.data.settings == null || Lambda.count(displaySettings) != Lambda.count(saveFile.data.settings))
		{
			for(key => values in displaySettings)
				data[key] = values[0];
			
			saveFile.data.settings = data;
		}
		if(saveFile.data.keyControls == null || Lambda.count(keyControls) != Lambda.count(saveFile.data.keyControls))
		{
			saveFile.data.keyControls = keyControls;
		}
		
		data 		= saveFile.data.settings;
		keyControls = saveFile.data.keyControls;
		save();
	}
	
	public static function save()
	{
		saveFile.data.settings = data;
		saveFile.data.keyControls = keyControls;
		saveFile.flush();
		update();
	}

	public static function update()
	{
		Main.changeFramerate(data.get("Framerate Cap"));

		FlxSprite.defaultAntialiasing = data.get("Antialiasing");
	}
}