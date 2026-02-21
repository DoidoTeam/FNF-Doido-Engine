package states;

import doido.song.AudioHandler;
import animate.FlxAnimate;
import doido.song.Conductor;
import doido.song.chart.Handler;
import doido.song.chart.Handler.DoidoSong;
import flixel.FlxSprite;
import flixel.sound.FlxSound;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import objects.*;
import objects.play.*;
import objects.ui.*;

typedef VoiceData = {
	var global:FlxSound; // default
	var opp:FlxSound; // if the opponent has a voices file, play them too
}
class PlayState extends MusicBeatState
{
	public static var SONG:DoidoSong;

	public var playField:PlayField;
	public var debugInfo:DebugInfo;
	
	var paused:Bool = true;
	var audio:AudioHandler;

	public static function loadSong(jsonInput:String, ?diff:String = "normal")
	{
		SONG = Handler.loadSong(jsonInput, diff);
	}
	
	override function create()
	{
		super.create();
		DiscordIO.changePresence("In the PlayState");

		Conductor.songPos = 0;
		Conductor.setBPM(100);
		
		audio = new AudioHandler(SONG.song);
		
		var bg = new FlxSprite().loadGraphic(Assets.image('menuInvert'));
		//bg.zIndex = 500;
		add(bg);
		
		playField = new PlayField(SONG.notes, SONG.speed, Save.data.downscroll);
		add(playField);

		playField.onNoteHit = (note) -> {
			audio.muteVoices = false;
		};
		playField.onNoteMiss = (note) -> {
			audio.muteVoices = true;
		};
		playField.onGhostTap = (lane, direction) -> {
			Logs.print("GHOST TAPPED " + direction.toUpperCase(), WARNING);
		};
		
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
			if (!paused)
				pauseSong();
			else
				unpauseSong();
		}
		
		if (audio.playing)
			Conductor.songPos += elapsed * 1000;
			
		playField.updateNotes(curStepFloat);
	}

	public function pauseSong()
	{
		paused = true;
		audio.pause();
	}

	public function unpauseSong()
	{
		paused = false;
		audio.play();
	}

	override function stepHit()
	{
		super.stepHit();
		audio.sync();
		
		if (curStep % 4 == 0) {
			FlxTween.cancelTweensOf(FlxG.camera);
			FlxG.camera.zoom *= 1.02;
			FlxTween.tween(FlxG.camera, {zoom: 1.0}, Conductor.crochet / 1000 * 1, {
				ease: FlxEase.cubeOut
			});
		}
	}
}