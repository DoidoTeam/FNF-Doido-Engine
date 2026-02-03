package states;

import backend.game.MusicBeat.MusicBeatState;
import flixel.FlxSprite;
import backend.assets.Cache;
import backend.assets.Assets;
import flixel.graphics.FlxGraphic;

class PlayState extends MusicBeatState
{
	override function create()
	{
		super.create();

		var bg = new FlxSprite().loadGraphic(Assets.image('menuInvert'));
		add(bg);

		trace(Assets.fileExists("fonts/vcr", FONT));
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if(Controls.justPressed(ACCEPT))
			MusicBeat.switchState(new states.PlayState());
		
		/*if (Controls.justPressed(UI_LEFT))
		{
			Logs.print('LEFT !!', WARNING);
			//Save.data.fps = (Save.data.fps == 0 ? 144 : 0);
			//Save.save();
			
			//Logs.print(Std.string(Save.data.test));
		}
		if (Controls.justPressed(UI_RIGHT))
			Logs.print('RIGHT !!', WARNING);*/
	}
}