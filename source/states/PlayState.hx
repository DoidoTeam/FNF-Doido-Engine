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

#if TOUCH_CONTROLS
import doido.mobile.DoidoButton;
#end

class PlayState extends MusicBeatState
{
	public static var SONG:DoidoSong;
	public static var skip:Bool = false;

	public var playField:PlayField;
	public var debugInfo:DebugInfo;
	
	var paused:Bool = true;

	var audio:AudioHandler;
	var defaultSpeed:Float = 1.0;

	#if TOUCH_CONTROLS
	var pauseButton:DoidoButton;
	#end

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
		
		playField = new PlayField(SONG.notes, SONG.speed, Save.data.downscroll, Save.data.middlescroll);
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

		#if TOUCH_CONTROLS
		pauseButton = new DoidoButton(0,0,100,100,0.4);
		add(pauseButton);
		#end

		if(skip) {
			audio.play();
			audio.pause();
			audio.time = 50000;
			updateStep();
			for(note in SONG.notes)
			{
				if (note.stepTime <= curStepFloat)
					playField.curSpawnNote++;
			}
		}

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

		if (FlxG.keys.pressed.F9)
			audio.speed = 10;
		if (FlxG.keys.justReleased.F9)
			audio.speed = defaultSpeed;
		
		var pause:Bool = Controls.justPressed(PAUSE);
		#if TOUCH_CONTROLS
		pause = Controls.justPressed(PAUSE) || pauseButton.justPressed;
		#end
		if(pause) {
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