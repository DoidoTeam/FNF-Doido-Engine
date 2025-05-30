package;

import backend.game.GameData.MusicBeatState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import states.*;

class Init extends MusicBeatState
{
	var openWarningMenu:Bool = false;
	override function create()
	{
		super.create();
		SaveData.init();
		DiscordIO.check();
				
		FlxG.fixedTimestep = false;
		FlxG.mouse.useSystemCursor = true;
		FlxG.mouse.visible = false;
		FlxGraphic.defaultPersist = true;
		
		for(i in 0...Paths.dumpExclusions.length)
			Paths.preloadGraphic(Paths.dumpExclusions[i].replace('.png', ''));

		firstState();
	}

	function firstState()
	{
		#if html5
		openWarningMenu = true;
		#end
		if(FlxG.save.data.beenWarned == null || openWarningMenu)
			Main.switchState(new WarningState());
		else
			Main.switchState(new TitleState());
	}
	/*
	A function to call some of the engines build flags from
	other states.
	*/
	public static function flagStates()
	{
		#if MENU
		Main.switchState(new states.menu.MainMenuState());
		#elseif FREEPLAY
		Main.switchState(new states.menu.FreeplayState());
		#else
			Main.switchState(new TitleState());
		#end
	}
}