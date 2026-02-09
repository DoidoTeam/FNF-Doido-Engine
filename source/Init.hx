package;

import doido.Cache;
import doido.MusicBeat.MusicBeatState;
import doido.system.Discord.DiscordIO;
import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import states.*;

class Init extends MusicBeatState
{
	override function create()
	{
		super.create();
		Save.init();
		Controls.load();
		DiscordIO.check();
		
		FlxG.fixedTimestep = false;
		FlxG.mouse.useSystemCursor = true;
		FlxG.mouse.visible = false;
		
		FlxGraphic.defaultPersist = true;
		openfl.Assets.cache.enabled = false;
		Cache.initCache();
		flagState();
	}

	/*
	* A function to call some of the engines build flags from
	* other states.
	*/
	public static function flagState()
	{
		MusicBeat.switchState(new DebugMenu());
	}
}