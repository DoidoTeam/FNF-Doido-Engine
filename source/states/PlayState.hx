package states;

import backend.game.MusicBeat.MusicBeatState;

class PlayState extends MusicBeatState
{
	override function create()
	{
		super.create();
		
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
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