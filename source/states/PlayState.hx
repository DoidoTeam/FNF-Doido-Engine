package states;

import backend.game.MusicBeat.MusicBeatState;
import flixel.FlxSprite;
import backend.assets.Cache;
import backend.assets.Assets;
import flixel.graphics.FlxGraphic;
import objects.*;
import objects.play.*;
import objects.ui.*;

class PlayState extends MusicBeatState
{
	var playField:PlayField;
	
	override function create()
	{
		super.create();

		var bg = new FlxSprite().loadGraphic(Assets.image('menuInvert'));
		add(bg);
		
		playField = new PlayField();
		add(playField);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		/*if(Controls.justPressed(ACCEPT))
			MusicBeat.switchState(new states.PlayState());*/
		
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