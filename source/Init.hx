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
		data.Discord.DiscordClient.prepare();
				
		FlxG.fixedTimestep = false;
		FlxG.mouse.useSystemCursor = true;
		FlxG.mouse.visible = false;
		FlxGraphic.defaultPersist = true;
		
		for(i in 0...Paths.dumpExclusions.length)
			Paths.preloadGraphic(Paths.dumpExclusions[i].replace('.png', ''));

		#if html5
		Main.switchState(new WarningState());
		#else
		if(FlxG.save.data.beenWarned == null)
			Main.switchState(new WarningState());
		else
			Main.switchState(new TitleState());
		#end
	}
}