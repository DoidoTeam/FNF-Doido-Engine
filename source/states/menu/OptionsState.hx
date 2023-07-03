package states.menu;

import flixel.FlxG;
import flixel.FlxSprite;
import data.GameData.MusicBeatState;

class OptionsState extends MusicBeatState
{
	var optionShit:Map<String, Dynamic> =
	[
		"main" => [
			"gameplay",
			"appearence",
			"controls",
		],
		"gameplay" => [
			"Ghost Tapping",
			"Downscroll",
			"Middlescroll",
		],
		"appearence" => [
			"Antialiasing",
			"Note Splashes",
			"Ratings on HUD",
		],
	];

	public static var curCategory:String = "";

	var curSelected:Int = 0;
	static var storedSelected:Map<String, Int> = [];

	// objects
	var bg:FlxSprite;

	override function create()
	{
		super.create();
		bg = new FlxSprite().loadGraphic('menu/backgrounds/menuDesat');
		bg.scale.set(1.2,1.2); bg.updateHitbox();
		bg.screenCenter();
		add(bg);
	}
}