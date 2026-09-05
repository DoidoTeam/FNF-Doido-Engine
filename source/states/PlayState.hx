package states;

import doido.utils.TweenUtil;
import shaders.ShaderCache;
import doido.objects.DoidoCamera;
import doido.utils.LerpUtil;
import flixel.FlxSprite;
import flixel.sound.FlxSound;
import flixel.math.FlxMath;
import doido.song.*;
import doido.song.SongHandler;
import doido.song.SongHandler.DoidoChart;
import doido.song.SongHandler.DoidoEvents;
import doido.utils.NoteUtil;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import hscript.iris.Iris;
import objects.*;
import objects.play.*;
import objects.ui.*;
import objects.ui.hud.*;
import objects.ui.notes.*;
import states.editors.*;
import substates.GameOverSubState;
import substates.PauseSubState;
import doido.song.Week.WeekData;
#if TOUCH_CONTROLS
import doido.objects.DoidoHitbox;
#end

using doido.utils.ScriptUtil;

class PlayState extends MusicBeatState implements Playable
{
	public static var SONG:DoidoSong;
	public static var startPos:Float = 0;
	public static var songDiff:String = "normal";

	// story mode
	public static var playList:Array<String> = [];
	public static var curWeek:String = '';
	public static var isStoryMode:Bool = false;
	public static var weekScore:Int = 0;

	// other statics
	public static var blueballed:Int = 0;
	public static var playedCutscene:Bool = false;

	public var playField:PlayField;
	public var hudClass:ClassHud;
	public var debugInfo:DebugInfo;

	public var camGame:DoidoCamera;
	public var camHUD:DoidoCamera;
	public var camStrum:DoidoCamera;
	public var camOther:DoidoCamera;
	public var shaders:ShaderCache;

	public var camFollow:LerpPoint;
	public var camDisplace:LerpPoint;
	public var defaultHudZoom:Float = 1.0;

	public var camZoom:Float = 0.9;
	public var beatCamZoom:Float = 0.0;

	public var beatRate:Int = 16;
	public var beatOffset:Int = 0;
	public var beatGame:Float = 0.035;
	public var beatHUD:Float = 0.02;
	public var beatStrum:Float = 0.02;

	public var curFocus:String = "";
	public var maxDisplace:DoidoPoint = {x: 0, y: 0};

	public var paused:Bool = false;
	public var canPause:Bool = true;

	public var audio:AudioHandler;
	public var countdownSfx:Array<FlxSound> = [];

	public var defaultSongSpeed:Float = 1.0;
	public var startedSong:Bool = false;
	public var startedCountdown:Bool = false;

	public var stageBuild:Stage;

	public var dad:CharGroup;
	public var bf:CharGroup;
	public var gf:CharGroup;
	public var characters:Array<CharGroup> = [];

	public var health:Float = 1;
	public var isDead:Bool = false;

	public var downscroll:Bool;
	public var middlescroll:Bool;
	public var validScore:Bool = true;
	public var practice:Bool = false;

	#if TOUCH_CONTROLS
	var pauseButton:DoidoHitbox;
	#end

	public var eventTweens:Map<String, FlxTween> = [];
	public var spawnEvents:Array<EventData> = [];
	public var curEventCount:Int = 0;

	public static var instance:PlayState;

	public static function loadSong(input:String, diff:String = "normal", story:Bool = false)
	{
		SONG = SongHandler.loadSong(input, diff);
		songDiff = diff;
		isStoryMode = story;
	}

	public static function loadWeek(week:WeekData, diff:String = "normal")
	{
		playList = [];
		for (song in week.songs)
			playList.push(song.song);

		curWeek = week.weekFile ?? "default";
		weekScore = 0;
		loadSong(playList[0], diff, true);
	}

	// resets static values related to current playthrough (score, etc)
	public static function resetStatics()
	{
		Timings.init();

		if (!isStoryMode)
		{
			weekScore = 0;
			curWeek = '';
			playList = [];
		}
	}

	// resets static values related to current song (blueballed count, etc)
	public static function resetSongStatics()
	{
		blueballed = 0;
		playedCutscene = false;
	}

	override function create()
	{
		super.create();
		instance = this;
		DiscordIO.changePresence("Playing - " + CHART.song);
		persistentDraw = true;
		persistentUpdate = false;
		MusicBeat.stopMusic();

		var scriptPaths:Array<String> = Assets.getScriptArray(CHART.song);
		for (path in scriptPaths)
			loadScript(path);
		setScript("playState", instance);
		callScript("create");

		Conductor.initialBPM = CHART.bpm;
		Conductor.mapBPMChanges(EVENTS.events);
		Conductor.songPos = -(Conductor.crochet * 5);
		resetStatics();

		downscroll = (#if TOUCH_CONTROLS Save.data.modernControls #else false #end ?true:Save.data.downscroll);
		middlescroll = (#if TOUCH_CONTROLS Save.data.modernControls #else false #end ?true:Save.data.middlescroll);

		spawnEvents = EVENTS.events;

		audio = new AudioHandler(CHART.song, CHART.postfix);

		camGame = new DoidoCamera(false, true);
		camHUD = new DoidoCamera(true, false);
		camStrum = new DoidoCamera(true, false);
		camOther = new DoidoCamera(true, false);

		shaders = new ShaderCache();
		camFollow = new LerpPoint();
		camDisplace = new LerpPoint();

		stageBuild = new Stage(this);

		bf = new CharGroup(true);
		bf.addChar(META.player1, true);
		bf.zIndex = 10;

		dad = new CharGroup(false);
		dad.addChar(META.player2, true);
		dad.zIndex = 9;

		gf = new CharGroup(false);
		gf.addChar(META.gf, true);
		gf.zIndex = 8;

		characters.push(gf);
		characters.push(dad);
		characters.push(bf);

		for (char in characters)
		{
			add(char);
		}

		// temporary caching
		for (i in 0...4)
		{
			countdownSfx.push(FlxG.sound.load(Assets.sound("countdown/base/intro" + ["3", "2", "1", "Go"][i])));
		}

		hudClass = switch (META.assets.hudType)
		{
			case "vslice": new VSliceHud(this);
			default: new BaseHud(this);
		}
		hudClass.alpha = 0;
		add(hudClass);

		for (event in spawnEvents)
			preloadEvent(event.name, event.data);

		changeStage(META.stage);

		playField = new PlayField(CHART.notes, CHART.speed, downscroll, middlescroll, META.assets);
		playField.cameras = [camStrum];
		add(playField);

		bf.strumline = playField.bfStrumline;
		dad.strumline = playField.dadStrumline;

		hudClass.init();
		hudClass.cameras = [camHUD];
		setUpInput();

		debugInfo = new DebugInfo(this);
		debugInfo.cameras = [camStrum];
		add(debugInfo);

		#if TOUCH_CONTROLS
		pauseButton = new DoidoHitbox(0, 0, 100, 100, 0.4);
		pauseButton.cameras = [camOther];
		add(pauseButton);
		#end

		callScript("createPost");

		// TO-DO: account for events
		if (startPos > Conductor.crochet * 8)
		{
			var startOffset:Float = Conductor.crochet * 4;
			Conductor.songPos = startPos - startOffset;
			startPos = 0;

			audio.play(Conductor.songPos);
			startedSong = true;
			startedCountdown = true;
			updateStep();

			for (note in CHART.notes)
			{
				if (note.stepTime < (curStepFloat + Conductor.getStepAtTime(startOffset)))
					playField.curSpawnNote++;
			}
			hudClass.alpha = 1;
		}
		else
		{
			startPos = 0;
			for (strumline in playField.strumlines)
			{
				if (strumline.hasModchart)
					continue;
				var strumMult:Int = (strumline.downscroll ? 1 : -1);
				for (strum in strumline.strums)
				{
					strum.y += NoteUtil.noteWidth(false) * 0.6 * strumMult;
					strum.alpha = 0.0001;
				}
			}
		}

		followCamera("dad");
		camFollow.get(1);

		camGame.zoom = camZoom;
		for (cam in [camHUD, camStrum])
			cam.zoom = defaultHudZoom;
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
				if (note.missed)
					health -= 0.04;
			}
			else
			{
				Timings.addScore(note, noteDiff);
				rating = Timings.addAccuracyDiff(noteDiff);
				hudClass.popUpCombo(Timings.combo, META.assets.ratings);

				if (!note.missed)
					Timings.notesHit++;

				var judge = Timings.getTiming(rating).judge;
				var healthJudge:Float = 0.05 * judge;
				if (judge < 0)
					healthJudge *= 2;
				health += healthJudge;
			}

			if (rating != "miss")
				hudClass.popUpRating(rating, META.assets.ratings);
			hudClass.updateScoreTxt();
		}

		function muteVoices()
		{
			if (Timings.combo >= 10)
			{
				if (gf.animExists("sad"))
				{
					gf.resetSingStep();
					gf.playAnim("sad");
				}
			}

			NoteUtil.playMissSound();
			audio.muteVoices = true;
		}

		playField.onNoteHit = (note, strumline) ->
		{
			if (note.isHold && !note.isHoldEnd)
				return;

			if (!note.isHold || note.missed)
			{
				switch (note.data.type)
				{
					case "no animation":
						//
					case "gf note":
						gf.playSingAnim(note.data.lane, note.missed);
					default:
						for (char in characters)
						{
							if (char.strumline == strumline)
								char.playSingAnim(note.data.lane, note.missed);
						}
				}
			}

			if (strumline.isPlayer)
			{
				if (note.missed)
					muteVoices();
				else
					audio.muteVoices = false;

				updateScore(note, playField.noteDiff(note.data));

				// cool thingy
				if (Timings.combo > 0 && Timings.combo % 50 == 0)
				{
					// nene weekend 1 support
					if (Timings.combo % 200 == 0 && gf.animExists("horny"))
					{
						gf.resetSingStep();
						gf.playAnim("horny");
					}
					else if (gf.animExists("cheer")) // gf cheer
					{
						gf.resetSingStep();
						gf.playAnim("cheer");
					}
				}
			}
			else
			{
				if (audio.voicesOpp == null)
					audio.muteVoices = false;
			}
			callScript("onNoteHit", [note, strumline]);
		};
		playField.onNoteMiss = (note, strumline) ->
		{
			if (note.isHold && !note.isHoldEnd)
				return;

			switch (note.data.type)
			{
				case "no animation":
					//
				case "gf note":
					gf.playSingAnim(note.data.lane, true);
				default:
					for (char in characters)
					{
						if (char.strumline == strumline)
							char.playSingAnim(note.data.lane, true);
					}
			}

			if (strumline.isPlayer)
			{
				muteVoices();
				updateScore(note, Timings.getTiming("miss").diff);
			}
			callScript("onNoteMiss", [note, strumline]);
		};
		playField.onNoteHold = (note, strumline) ->
		{
			switch (note.data.type)
			{
				case "no animation":
					//
				case "gf note":
					// weird formatter bug here sorry...
					if (gf.singType == LAST)
					{
						gf.resetSingStep();
					}
					else if (gf.curAnimFrame == gf.singLoop || gf.singType == FIRST)
					{
						gf.playSingAnim(note.data.lane);
					}
				default:
					for (char in characters)
					{
						if (char.strumline == strumline)
						{
							if (char.singType == LAST)
								char.resetSingStep();
							else if (char.curAnimFrame == char.singLoop || char.singType == FIRST)
								char.playSingAnim(note.data.lane);
						}
					}
			}

			if (strumline.isPlayer)
				health += FlxG.elapsed * 0.25;

			callScript("onNoteHold", [note, strumline]);
		};

		// doing this so it doesn't update when you change the setting mid-song
		var ghostTapping:String = Save.data.ghostTapping.toLowerCase();

		playField.onGhostTap = (lane, strumline) ->
		{
			if (!startedCountdown)
				return;

			var punished:Bool = false;
			if (ghostTapping == "off" || (ghostTapping == "idle" && !strumline.ghostTappingIdle))
			{
				punished = true;
				health -= 0.08;

				Timings.score -= 100;
				Timings.addAccuracy(Timings.getTiming("bad").judge);

				Timings.addCombo(-1);
				NoteUtil.playMissSound();
				for (char in characters)
				{
					if (char.strumline == strumline)
					{
						char.playSingAnim(lane, true);
					}
				}
				hudClass.updateScoreTxt();
			}
			callScript("onGhostTap", [lane, strumline, punished]);

			// Logs.print("GHOST TAPPED " + lane, WARNING);
		};
	}

	public function changeStage(curStage:String)
	{
		if (curStage != stageBuild.curStage)
		{
			for (item in stageBuild.stageItems)
				remove(item);

			stageBuild.reloadStage(curStage);
			for (item in stageBuild.stageItems)
				add(item);
		}

		clearTween("camZoom");
		camZoom = stageBuild.camZoom;

		if (stageBuild.gfVersion != "")
			gf.setActive(stageBuild.gfVersion);
		else
			gf.setActive(META.gf);

		dad.setPos(stageBuild.dadPos.x, stageBuild.dadPos.y);
		bf.setPos(stageBuild.bfPos.x, stageBuild.bfPos.y);
		gf.setPos(stageBuild.gfPos.x, stageBuild.gfPos.y);

		dad.setScrollFactor(stageBuild.dadScrollFactor.x, stageBuild.dadScrollFactor.y);
		bf.setScrollFactor(stageBuild.bfScrollFactor.x, stageBuild.bfScrollFactor.y);
		gf.setScrollFactor(stageBuild.gfScrollFactor.x, stageBuild.gfScrollFactor.y);
	}

	public function changeChar(char:CharGroup, newChar:String = "bf", ?iconToo:Bool = true)
	{
		char.setActive(newChar);
		if (iconToo)
			hudClass.changeIcon(char.curChar, char.isPlayer ? PLAYER : ENEMY);
	}

	override function draw()
	{
		members.sort(ZIndex.sortAscending);
		super.draw();
	}

	var cameraSpeed:Float = 1.0;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if ((botplay || practice) && startedSong)
			validScore = false;

		var followLerp:Float = FlxMath.bound((cameraSpeed * 5 * elapsed), 0, 1);

		updateDisplace();
		camGame.moveCam([
			camFollow.get(followLerp),
			camDisplace.get(followLerp),
			{x: -FlxG.width / 2, y: -FlxG.height / 2}
		]);

		camGame.zoom = camZoom + beatCamZoom;
		beatCamZoom = FlxMath.lerp(beatCamZoom, 0, elapsed * 6);
		for (cam in [camHUD, camStrum])
			cam.zoom = FlxMath.lerp(cam.zoom, defaultHudZoom, elapsed * 6);

		health = FlxMath.bound(health, 0, 2);
		if (Controls.justPressed(RESET) || (health <= 0 && !practice))
			startGameOver();

		if (Save.data.developerMode)
			debugKeys();

		if (canPause)
		{
			if (Controls.justPressed(PAUSE) #if TOUCH_CONTROLS || pauseButton.justPressed #end)
				pauseSong();

			// gamepad disconnected
			if (Controls.lastInput == GAMEPAD && FlxG.gamepads.lastActive == null)
				pauseSong(true);
		}

		if (!paused)
		{
			audio.sync(elapsed);
			FlxG.animationTimeScale = audio.speed;
			if (!startedSong)
			{
				for (snd in countdownSfx)
					if (snd.playing)
						snd.pitch = audio.speed;
			}
		}

		if (curEventCount < spawnEvents.length)
		{
			for (i in 0...spawnEvents.length)
			{
				if (i < curEventCount)
					continue;

				var eventData = spawnEvents[curEventCount];
				if ((eventData.stepTime + (Conductor.musicOffset / Conductor.stepCrochet) - curStepFloat) <= 0)
				{
					playEvent(eventData.name, eventData.data);
					curEventCount++;
				}
			}
		}

		playField.updateNotes(curStepFloat);
		callScript("updatePost", [elapsed]);
	}

	function debugKeys()
	{
		if (FlxG.keys.justPressed.SEVEN)
			MusicBeat.switchState(new ChartingState(SONG));

		if (FlxG.keys.justPressed.EIGHT)
		{
			var char = dad;
			if (FlxG.keys.pressed.SHIFT)
				char = bf;
			if (FlxG.keys.pressed.CONTROL)
				char = gf;

			MusicBeat.switchState(new CharacterEditor(char.curChar, char == bf, true));
		}

		if (FlxG.keys.justPressed.ONE)
			endSong();
		if (FlxG.keys.justPressed.NINE)
			camZoom = 0.2;
		if (FlxG.keys.justPressed.F9)
			audio.speed = 10;
		if (FlxG.keys.justReleased.F9)
			audio.speed = defaultSongSpeed;
	}

	function preloadEvent(name:String, data:Array<Dynamic>)
	{
		switch (name)
		{
			case 'Change Character':
				strToChar(data[0]).addChar(data[1], false);
			case 'Change Stage':
				stageBuild.reloadStage(data[0]);
				if (stageBuild.gfVersion != "")
					gf.addChar(stageBuild.gfVersion, false);
		}
	}

	function playEvent(name:String, data:Array<Dynamic>)
	{
		callScript("playEvent", [name, data]);
		switch (name)
		{
			case "Play Animation":
				var char = strToChar(data[0]);
				char.playAnim(data[1], true);
				char.specialAnim = switch (data[2])
				{
					case "IGNORE IDLE": IGNORE_IDLE;
					case "IGNORE NOTES": IGNORE_NOTES;
					case "OVERRIDE ALL": OVERRIDE_ALL;
					default: NONE;
				};

			case "Change Character":
				var char = strToChar(data[0]);
				changeChar(char, data[1], (char != gf));

			case "Freeze Notes":
				var affected:Array<Strumline> = playField.strumlines.copy();
				switch (data[1])
				{
					case "dad": affected.remove(playField.bfStrumline);
					case "bf": affected.remove(playField.dadStrumline);
				}
				for (strumline in affected)
					strumline.pauseNotes = data[0];

			case "Change Note Speed":
				for (strumline in playField.strumlines)
					setTween("scrollSpeed" + strumline.ID, strumline, {scrollSpeed: data[0]}, data[1], data[2], data[3]);

			case "Change Cam Zoom":
				setTween("camZoom", this, {camZoom: data[0]}, data[1], data[2], data[3]);

			case "Change Cam Angle":
				setTween("camAngle" + data[0], strToCam(data[0]), {angle: data[1]}, data[2], data[3], data[4]);

			case "Beat Screen":
				beatCamera(data[0], data[1], data[2]);

			case "Auto Beat Screen":
				beatRate = data[0];
				beatOffset = data[1];
				beatGame = data[2];
				beatHUD = data[3];
				beatStrum = data[4];

			case "Flash Screen":
				MusicBeat.flash(strToCam(data[2]), Conductor.getStepDuration(curStepFloat, data[0]), SpriteUtil.getColor(data[1]));

			case 'Fade Screen':
				strToCam(data[3]).fade(SpriteUtil.getColor(data[2]), Conductor.getStepDuration(curStepFloat, data[1]), data[0]);

			case 'Shake Screen':
				strToCam(data[2]).shake(data[0], Conductor.getStepDuration(curStepFloat, data[1]));

			case "Change Stage":
				changeStage(data[0]);

			case "Camera Focus":
				followCamera(data[0], data[1] ?? 4, data[2] ?? "classic", data[3] ?? "inout", {x: data[4] ?? 0, y: data[5] ?? 0});

			case "Camera Position":
				followCamera("", data[2], data[3], data[4], {x: data[0], y: data[1]});
		}
	}

	public function clearTween(name:String)
	{
		var tween = eventTweens.get(name);
		if (tween != null)
			tween.cancel();
	}

	public function setTween(name:String, object:Dynamic, values:Dynamic, duration:Float = 1, ease:String = "linear", modifier:String = "in", clear:Bool = true):FlxTween
	{
		if (clear)
			clearTween(name);

		duration = Conductor.getStepDuration(curStepFloat, duration);
		if (duration <= 0)
		{
			for (field in Reflect.fields(values))
				Reflect.setField(object, field, Reflect.field(values, field));
			return null;
		}
		else
		{
			var tween = FlxTween.tween(object, values, duration, {
				ease: TweenUtil.fromString(ease, modifier),
			});
			eventTweens.set(name, tween);
			return tween;
		}
	}

	public function followCamera(charStr:String = "", duration:Float = 4, ease:String = "classic", modifier:String = "inout", ?offset:DoidoPoint):LerpPoint
	{
		offset = MathUtil.addPoint(offset ?? {x: 0, y: 0}, switch (charStr)
		{
			case "dad": stageBuild.dadCam;
			case "bf": stageBuild.bfCam;
			case "gf": stageBuild.gfCam;
			default: {x: 0, y: 0};
		});

		var char = strToChar(charStr, true);
		curFocus = charStr;

		var target:DoidoPoint = {x: 0, y: 0};
		if (char != null)
		{
			var playerMult:Int = (char.isPlayer ? -1 : 1);

			target = {
				x: char.getMidpoint().x + ((200 + char.cameraOffset.x) * playerMult),
				y: char.getMidpoint().y - 20 + char.cameraOffset.y
			};
		}
		target = MathUtil.addPoint(target, offset);

		if (ease == "classic")
			camFollow.set(target);
		else
			camFollow.tweenTo(target, Conductor.getStepDuration(curStepFloat, duration), ease, modifier);

		return camFollow;
	}

	function updateDisplace()
	{
		if (maxDisplace.x == 0 && maxDisplace.y == 0)
			return;

		switch (strToChar(curFocus).curAnimName.split('-')[0])
		{
			case 'singLEFT':
				camDisplace.point = {x: -maxDisplace.x, y: 0};
			case 'singRIGHT':
				camDisplace.point = {x: maxDisplace.x, y: 0};
			case 'singUP':
				camDisplace.point = {x: 0, y: -maxDisplace.y};
			case 'singDOWN':
				camDisplace.point = {x: 0, y: maxDisplace.y};
			default:
				camDisplace.point = {x: 0, y: 0};
		}
	}

	public static var availableCharacters:Array<String> = ['dad', 'bf', 'gf'];

	function strToChar(str:String, nullable:Bool = false):CharGroup
	{
		return switch (str.toLowerCase())
		{
			default: nullable ? null : dad;
			case 'dad': dad;
			case 'bf' | 'boyfriend': bf;
			case 'gf' | 'girlfriend': gf;
		}
	}

	public static var availableCameras:Array<String> = ['Game', 'HUD', 'Strum', 'Other'];

	function strToCam(str:String):DoidoCamera
	{
		return switch (str.toLowerCase())
		{
			default: camGame;
			case 'camHUD' | 'hud' | 'ui': camHUD;
			case 'camStrum' | 'strum' | 'notes': camStrum;
			case 'camOther' | 'other' | 'camOthers' | 'others': camOther;
		}
	}

	public function startSong()
	{
		audio.play();
		startedSong = true;
	}

	public function pauseSong(?gamepadDisconnected:Bool = false)
	{
		paused = true;
		for (snd in FlxG.sound.list)
		{
			snd.pause();
		}
		audio.pause();
		audio.speed = 0.0;
		MusicBeat.activateTimers(false);
		openSubState(new PauseSubState(gamepadDisconnected));
	}

	public function unpauseSong()
	{
		paused = false;
		for (snd in FlxG.sound.list)
		{
			snd.resume();
		}
		MusicBeat.activateTimers(true);
		if (Conductor.songPos < audio.songLength)
		{
			if (Conductor.songPos >= 0)
				audio.play();

			FlxTween.cancelTweensOf(audio);
			if (Save.data.slowdownUnpause)
				FlxTween.tween(audio, {speed: defaultSongSpeed}, 0.6, {ease: FlxEase.sineIn});
			else
				audio.speed = defaultSongSpeed;
		}
		else
			audio.speed = defaultSongSpeed;
	}

	public function startGameOver()
	{
		if (isDead)
			return;

		isDead = true;
		paused = true;
		for (snd in FlxG.sound.list)
		{
			snd.stop();
		}
		audio.stop();
		MusicBeat.activateTimers(false);
		followCamera("boyfriend");
		persistentDraw = persistentUpdate = false;
		openSubState(new GameOverSubState(SONG.META.assets.gameOverPath, bf));
	}

	public function beatCamera(gameZoom:Float, hudZoom:Float, strumZoom:Float)
	{
		beatCamZoom += gameZoom;
		camHUD.zoom += hudZoom;
		camStrum.zoom += strumZoom;
	}

	var endedSong:Bool = false;

	public function endSong()
	{
		if (endedSong)
			return;

		endedSong = true;
		canPause = false;
		resetSongStatics();

		if (validScore)
		{
			Highscore.addScore(CHART.song.toLowerCase() + '-' + songDiff, {
				score: Timings.score,
				accuracy: Timings.accuracy,
				misses: Timings.misses,
			});
		}

		weekScore += Timings.score;
		playList.remove(playList[0]);

		if (playList.length <= 0)
		{
			if (isStoryMode && validScore)
			{
				Highscore.addScore('week-$curWeek-$songDiff', {
					score: weekScore,
					accuracy: 0,
					misses: 0,
				});
			}

			goToMenu();
		}
		else
		{
			loadSong(playList[0], songDiff, true);
			MusicBeat.switchState(new LoadingState());
		}
	}

	public function goToMenu()
	{
		MusicBeat.stopMusic();
		resetSongStatics();

		if (isStoryMode)
			MusicBeat.switchState(new states.menus.StoryMenuState());
		else
			MusicBeat.switchState(new states.menus.FreeplayState());
	}

	override function destroy()
	{
		instance = null;
		super.destroy();
	}

	override function stepHit()
	{
		super.stepHit();
		playField.stepHit(curStep);

		if (startedSong && !endedSong)
		{
			if (Conductor.songPos >= audio.songLength)
				endSong();
		}

		if ((curStep + beatOffset) % beatRate == 0)
			beatCamera(beatGame, beatHUD, beatStrum);

		hudClass.stepHit(curStep);
	}

	public function countDown(count:Int)
	{
		if (!startedCountdown)
			startedCountdown = true;

		switch (count)
		{
			case 0:
				noteIntro();
			case 2:
				FlxTween.tween(hudClass, {alpha: 1.0}, Conductor.crochet * 2 / 1000);
			case 4:
				startSong();
		}

		if (count < 4) // countdown
		{
			countdownSfx[count].play();

			// BIG WIP!
			if (count >= 1)
			{
				var countName:String = ["ready", "set", "go"][count - 1];
				var countSprite = new FlxSprite();
				countSprite.loadImage('ui/countdown/${META.assets.countdown}/$countName');
				if (META.assets.countdown == "pixel")
				{
					countSprite.scale.set(6.5, 6.5);
					countSprite.antialiasing = false;
				}
				else
					countSprite.scale.set(0.65, 0.65);
				countSprite.updateHitbox();
				countSprite.screenCenter();
				countSprite.cameras = [camHUD];
				hudClass.add(countSprite);

				FlxTween.tween(countSprite, {alpha: 0}, Conductor.stepCrochet * 2.8 / 1000, {
					startDelay: Conductor.stepCrochet * 1 / 1000,
					onComplete: function(twn:FlxTween)
					{
						countSprite.destroy();
					}
				});
			}
		}
	}

	public function noteIntro()
	{
		for (strumline in playField.strumlines)
		{
			if (strumline.hasModchart)
				continue;

			for (strum in strumline.strums)
			{
				// actual tween
				FlxTween.tween(strum, {y: strum.initialPos.y, alpha: 0.9}, (Conductor.crochet / 1000) * 2, {
					ease: FlxEase.circOut,
					startDelay: 0.2 + (0.15 * strum.lane),
				});
			}
		}
	}

	override function beatHit()
	{
		super.beatHit();
		if (curBeat < -4)
			return;

		// COUNTDOWN AND SONG START
		if (curBeat <= 0)
			countDown(curBeat + 4);

		for (char in characters)
		{
			if ((curBeat % 2 == 0 || char.quickDancer) && (char.singStep <= 0))
			{
				if (char.isPlayer)
				{
					if (!playField.playerHolding)
						char.dance();
				}
				else
					char.dance();
			}
		}

		hudClass.beatHit(curBeat);
	}

	override public function callScript(fun:String, ?args:Array<Dynamic>):Dynamic
	{
		var retValues:Array<Dynamic> = super.callScript(fun, args);
		if (retValues == null)
			retValues = [];
		if (stageBuild != null)
			retValues.push(stageBuild.callScript(fun, args));
		return retValues;
	}

	public var player1(get, never):String;

	public function get_player1():String
		return bf.curChar;

	public var player2(get, never):String;

	public function get_player2():String
		return dad.curChar;

	public var songLength(get, never):Float;

	public function get_songLength():Float
		return audio.songLength;

	public var botplay(default, set):Bool;

	public function set_botplay(b:Bool):Bool
	{
		botplay = b;
		playField.bfStrumline.botplay = b;
		return botplay;
	}

	public static var CHART(get, never):DoidoChart;

	public static function get_CHART():DoidoChart
		return SONG.CHART;

	public static var EVENTS(get, never):DoidoEvents;

	public static function get_EVENTS():DoidoEvents
		return SONG.EVENTS;

	public static var META(get, never):DoidoMeta;

	public static function get_META():DoidoMeta
		return SONG.META;

	override private function resetState()
	{
		if (FlxG.keys.pressed.CONTROL)
			loadSong(CHART.song, songDiff, isStoryMode);
		super.resetState();
	}
}

interface Playable
{
	var health:Float;
	var downscroll:Bool;
	var middlescroll:Bool;
	var validScore:Bool;
	var botplay(default, set):Bool;
	var songLength(get, never):Float;
	var player1(get, never):String;
	var player2(get, never):String;

	var curStep:Int;
	var curStepFloat:Float;
	var curBeat:Int;
}
