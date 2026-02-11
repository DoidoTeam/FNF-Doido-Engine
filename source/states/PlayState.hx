package states;

import flixel.graphics.tile.FlxDrawTrianglesItem.DrawData;
import animate.FlxAnimate;
import doido.song.Conductor;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.sound.FlxSound;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxStrip;
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
		DiscordIO.changePresence("In the PlayState");

		Conductor.songPos = 0;
		Conductor.setBPM(100);
		
		inst = FlxG.sound.load(Assets.inst("bopeebo"));
		
		var bg = new FlxSprite().loadGraphic(Assets.image('menuInvert'));
		//bg.zIndex = 500;
		add(bg);
		
		playField = new PlayField();
		add(playField);
		
		debugInfo = new DebugInfo(this);
		add(debugInfo);


		//friend
		/*var sprite = new FlxAnimate();
		sprite.frames = Assets.animate("face");
		add(sprite);*/
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if(Controls.justPressed(RESET)) {
			MusicBeat.skipClearCache = true;
			MusicBeat.switchState(new states.PlayState());
		}
		
		if(Controls.justPressed(BACK)) {
			MusicBeat.switchState(new states.DebugMenu());
		}
		
		if(Controls.justPressed(ACCEPT)) {
			if (inst.playing)
				inst.pause();
			else
				inst.play();
		}
		
		if (inst.playing)
			Conductor.songPos += elapsed * 1000;
			
		playField.updateNotes(curStepFloat);
	}
	
	override function stepHit()
	{
		super.stepHit();
		syncSong();
		
		if (curStep % 4 == 0) {
			FlxTween.cancelTweensOf(FlxG.camera);
			FlxG.camera.zoom *= 1.02;
			FlxTween.tween(FlxG.camera, {zoom: 1.0}, Conductor.crochet / 1000 * 1, {
				ease: FlxEase.cubeOut
			});
		}
	}
	
	public function syncSong()
	{
		if (Math.abs(Conductor.songPos - inst.time) >= 20)
		{
			Logs.print('FIXING DELAYED MUSIC: ${inst.time} > ${Conductor.songPos}', WARNING);
			inst.time = Conductor.songPos;
		}
	}
}