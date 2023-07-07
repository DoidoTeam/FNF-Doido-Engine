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
				
		FlxG.fixedTimestep = false;
		FlxG.mouse.useSystemCursor = true;
		//FlxG.mouse.visible = false;
		FlxGraphic.defaultPersist = true;
		
		Main.switchState(new MenuState());
	}
}