package states;

import animate.FlxAnimate;
import doido.song.*;
import doido.song.chart.Handler;
import doido.song.chart.Handler.DoidoSong;
import flixel.FlxSprite;
import flixel.sound.FlxSound;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import objects.*;
import objects.play.*;
import objects.ui.*;
import objects.ui.hud.*;
import objects.ui.notes.*;
import hscript.iris.Iris;
import flixel.FlxCamera;

#if TOUCH_CONTROLS
import doido.objects.DoidoButton.ButtonHitbox;
#end

using doido.utils.CameraUtil;

class PlayState extends MusicBeatState
{
	public static var SONG:DoidoSong;
	public static var skip:Bool = false;

	public var playField:PlayField;
	public var hudClass:BaseHud;
	public var debugInfo:DebugInfo;

	var camGame:FlxCamera;
	var camHUD:FlxCamera;
	
	var paused:Bool = true;

	var audio:AudioHandler;
	var defaultSpeed:Float = 1.0;

	#if TOUCH_CONTROLS
	var pauseButton:ButtonHitbox;
	#end

	public static var instance:PlayState;
	public var loadedScripts:Array<Iris> = [];

	public static function loadSong(jsonInput:String, ?diff:String = "normal")
	{
		SONG = Handler.loadSong(jsonInput, diff);
	}

	public function resetStatics()
	{
		Timings.init();	
	}
	
	override function create()
	{
		super.create();
		instance = this;
		DiscordIO.changePresence("Playing - " + SONG.song);

		var scriptPaths:Array<String> = Assets.getScriptArray(SONG.song);
		for(path in scriptPaths) {
			var newScript:Iris = new Iris(Assets.script('$path'), instance, {name: path, autoRun: true, autoPreset: true});
			loadedScripts.push(newScript);
		}
		//setScript("this", instance); //hopefully we wont be needing THIS anymore!

		Conductor.songPos = 0;
		Conductor.setBPM(SONG.bpm);
		resetStatics();
		
		audio = new AudioHandler(SONG.song);

		camGame = new FlxCamera().createCam(false, true);
		camHUD = new FlxCamera().createCam(true, false);
		
		var bg = new FlxSprite().loadGraphic(Assets.image('menuInvert'));
		//bg.zIndex = 500;
		add(bg);

		hudClass = switch(SONG.song)
		{
			default: new DoidoHud();
		}
		hudClass.playState = this;
		add(hudClass);

		callScript("create");
		
		playField = new PlayField(SONG.notes, SONG.speed, Save.data.downscroll, Save.data.middlescroll);
		playField.cameras = [camHUD];
		add(playField);

		hudClass.init();
		setUpInput();
		
		debugInfo = new DebugInfo(this);
		add(debugInfo);

		#if TOUCH_CONTROLS
		pauseButton = new ButtonHitbox(0,0,100,100,0.4);
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

		callScript("createPost");
	}

	public function setUpInput()
	{
		function updateScore(note:Note, noteDiff:Float)
		{
			var rating = "sick";
			if (note.isHold)
			{
				Timings.addScoreHold(note);
				rating = Timings.addAccuracyHold(note.holdHitPercent);
			}
			else
			{
				Timings.addScore(note, noteDiff);
				rating = Timings.addAccuracyDiff(noteDiff);
				hudClass.popUpCombo(Timings.combo);
			}
			if (rating != "miss") hudClass.popUpRating(rating);
			hudClass.updateScoreTxt();
		}

		playField.onNoteHit = (note, strumline) ->
		{
			if (note.isHold && !note.isHoldEnd) return;

			if (strumline.isPlayer)
			{
				audio.muteVoices = false;
				updateScore(note, playField.noteDiff(note.data));
			}
			else
			{
				if (audio.voicesOpp == null) audio.muteVoices = false;
			}
		};
		playField.onNoteMiss = (note, strumline) ->
		{
			if (note.isHold && !note.isHoldEnd) return;
			
			if (strumline.isPlayer)
			{
				audio.muteVoices = true;
				updateScore(note, Timings.getTiming("miss").diff);
			}
		};
		
		playField.onGhostTap = (lane, direction) ->
		{
			//Logs.print("GHOST TAPPED " + direction.toUpperCase(), WARNING);
			hudClass.updateScoreTxt();
		};
	}

	override function update(elapsed:Float)
	{
		callScript("update", [elapsed]);
		super.update(elapsed);
		
		if(Controls.justPressed(RESET)) {
			MusicBeat.skipClearCache = true;
			MusicBeat.switchState(new states.PlayState());
		}
		
		if(Controls.justPressed(BACK)) {
			MusicBeat.switchState(new states.DebugMenu());
		}

		#if debug
		if (FlxG.keys.pressed.F9)
			audio.speed = 10;
		if (FlxG.keys.justReleased.F9)
			audio.speed = defaultSpeed;
		#end
		
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
			Conductor.songPos += elapsed * 1000 * audio.speed;
			
		playField.updateNotes(curStepFloat);
		callScript("updatePost", [elapsed]);
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
		playField.stepHit(curStep);
		audio.sync();

		if (curStep % 16 == 0)
		{
			FlxTween.cancelTweensOf(camHUD);
			camHUD.zoom *= 1.02;
			FlxTween.tween(camHUD, {zoom: 1.0}, Conductor.crochet / 1000 * 1, {
				ease: FlxEase.cubeOut
			});
		}
		
		if (curStep % 4 == 0)
			callScript("beatHit", [curStep / 4]); //compatibilidade?
		callScript("stepHit", [curStep]);
	}

	public function callScript(fun:String, ?args:Array<Dynamic>) {
		for(script in loadedScripts) {
			@:privateAccess {
				var ny: Dynamic = script.interp.variables.get(fun);
				try {
					if(ny != null && Reflect.isFunction(ny))
						script.call(fun, args);
				} catch(e) {
					Logs.print('error parsing script: ' + e, ERROR);
				}
			}
		}
	}
	
	public function setScript(name:String, value:Dynamic, allowOverride:Bool = true) {
		for(script in loadedScripts)
			script.set(name, value, allowOverride);
	}
}