package states;

import backend.song.Conductor;
import backend.assets.Cache;
import backend.assets.Assets;
import backend.game.MusicBeat.MusicBeatState;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.sound.FlxSound;
import objects.*;
import objects.play.*;
import objects.ui.*;

class PlayState extends MusicBeatState
{
	var playField:PlayField;
	var debugInfo:DebugInfo;
	
	var inst:FlxSound;
	
	override function create()
	{
		super.create();
		Conductor.setBPM(100);
		
		inst = FlxG.sound.load(Assets.inst("bopeebo"));
		
		var bg = new FlxSprite().loadGraphic(Assets.image('menuInvert'));
		add(bg);
		
		playField = new PlayField();
		add(playField);
		
		debugInfo = new DebugInfo();
		add(debugInfo);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if(Controls.justPressed(RESET))
			MusicBeat.switchState(new states.PlayState());
		if(Controls.justPressed(ACCEPT))
			if (inst.playing)
				inst.pause();
			else
				inst.play();
		
		if (inst.playing)
		{
			Conductor.songPos += elapsed * 1000;
		}
		
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
	
	public function syncSong()
	{
		if (Math.abs(inst.time - Conductor.songPos) >= 20)
		{
			inst.time = Conductor.songPos;
		}
	}
}