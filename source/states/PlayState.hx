package states;

import animate.FlxAnimate;
import doido.song.Conductor;
import doido.song.SongData;
import doido.song.SongData.DoidoSong;
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
	var inst:FlxSound;
	var voices:VoiceData;

	public static function loadSong(jsonInput:String, ?diff:String = "normal")
	{
		SONG = SongData.loadJson(jsonInput, diff);
	}
	
	override function create()
	{
		super.create();
		DiscordIO.changePresence("In the PlayState");

		Conductor.songPos = 0;
		Conductor.setBPM(100);
		
		setUpAudio();
		
		var bg = new FlxSprite().loadGraphic(Assets.image('menuInvert'));
		//bg.zIndex = 500;
		add(bg);
		
		playField = new PlayField(SONG.notes, SONG.speed, false);
		add(playField);

		playField.onNoteHit = (note) -> {
			if (voices.global != null)
			{
				voices.global.volume = 1.0;
			}
		};
		playField.onNoteMiss = (note) -> {
			if (voices.global != null)
			{
				voices.global.volume = 0.0;
			}
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

	public function setUpAudio()
	{
		inst = FlxG.sound.load(Assets.inst(SONG.song));
		voices = {
			global: null,
			opp: null,
		};
		// global voices
		if (Assets.fileExists('songs/${SONG.song}/audio/Voices-player', SOUND))
			voices.global = FlxG.sound.load(Assets.voices(SONG.song, '-player'));
		else if (Assets.fileExists('songs/${SONG.song}/audio/Voices', SOUND))
			voices.global = FlxG.sound.load(Assets.voices(SONG.song));

		// opponent voices
		if (Assets.fileExists('songs/${SONG.song}/audio/Voices-opp', SOUND))
			voices.opp = FlxG.sound.load(Assets.voices(SONG.song, "-opp"));
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
		
		if (inst.playing)
			Conductor.songPos += elapsed * 1000;
			
		playField.updateNotes(curStepFloat);
	}

	public function pauseSong()
	{
		paused = true;
		updateMusic((snd) -> {
			snd.pause();
		});
	}

	public function unpauseSong()
	{
		paused = false;
		updateMusic((snd) -> {
			snd.play();
		});
	}

	public function updateMusic(func:(snd:FlxSound)->Void)
	{
		func(inst);
		if (voices.global != null) func(voices.global);
		if (voices.opp != null) func(voices.opp);
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
		updateMusic((snd) -> {
			if (snd == inst) return;
			if (Math.abs(Conductor.songPos - snd.time) >= 25)
			{
				Conductor.songPos = inst.time;
				Logs.print('FIXING DELAYED MUSIC: ${snd.time} > ${Conductor.songPos}', WARNING);
				updateMusic((fixSnd) -> {
					fixSnd.time = Conductor.songPos;
				});
			}
		});
	}
}