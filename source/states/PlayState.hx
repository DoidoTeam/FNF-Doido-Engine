package states;

import backend.game.MusicBeat.MusicBeatState;
import flixel.FlxSprite;
import backend.assets.Cache;

class PlayState extends MusicBeatState
{
	override function create()
	{
		super.create();
		
		var bg = new FlxSprite().loadGraphic(Paths.image('menuInvert'));
		add(bg);
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