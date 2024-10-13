package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import data.GameData.MusicBeatState;
import states.*;

class Init extends MusicBeatState
{
	override function create()
	{
		super.create();
		SaveData.init();
		data.Discord.DiscordIO.initialize();

		#if android
		FlxG.android.preventDefaultKeys = [BACK];
		#end
				
		FlxG.fixedTimestep = false;
		FlxG.mouse.useSystemCursor = true;
		FlxG.mouse.visible = false;
		FlxGraphic.defaultPersist = true;
		
		for(i in 0...Paths.dumpExclusions.length)
			Paths.preloadGraphic(Paths.dumpExclusions[i].replace('.png', ''));

		data.MobileUtil.createVPad(BLANK, null);

		firstState();
	}

	function firstState()
	{
		#if html5
		Main.switchState(new WarningState());
		#elseif MENU
		Main.switchState(new states.menu.MainMenuState());
		#elseif FREEPLAY
		Main.switchState(new states.menu.FreeplayState());
		#else
		if(FlxG.save.data.beenWarned == null)
			Main.switchState(new WarningState());
		else
			Main.switchState(new TitleState());
		#end
	}
}