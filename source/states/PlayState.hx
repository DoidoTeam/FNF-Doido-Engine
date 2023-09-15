package states;

import data.Discord.DiscordClient;
import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.addons.effects.FlxTrail;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import data.*;
import data.SongData.SwagSong;
import data.SongData.SwagSection;
import data.chart.*;
import data.GameData.MusicBeatState;
import gameObjects.*;
import gameObjects.hud.*;
import gameObjects.hud.note.*;
import gameObjects.Dialogue.DialogueData;
import shaders.*;
import states.editors.*;
import states.menu.*;
import subStates.*;

using StringTools;

class PlayState extends MusicBeatState
{
	// song stuff
	public static var SONG:SwagSong;
	public static var songDiff:String = "normal";
	// more song stuff
	public var inst:FlxSound;
	public var vocals:FlxSound;
	public var musicList:Array<FlxSound> = [];
	
	public static var songLength:Float = 0;
	
	// story mode stuff
	public static var playList:Array<String> = [];
	public static var curWeek:String = '';
	public static var isStoryMode:Bool = false;
	public static var weekScore:Int = 0;

	// extra stuff
	public static var assetModifier:String = "base";
	public static var health:Float = 1;
	// score, misses, accuracy and other stuff
	// are on the Timings.hx class!!

	// objects
	public var stageBuild:Stage;

	public var characters:Array<Character> = [];
	public var dad:Character;
	public var boyfriend:Character;
	public var gf:Character;

	// strumlines
	public var strumlines:FlxTypedGroup<Strumline>;
	public var bfStrumline:Strumline;
	public var dadStrumline:Strumline;

	// hud
	public var hudBuild:HudClass;

	// cameras!!
	public var camGame:FlxCamera;
	public var camHUD:FlxCamera;
	public var camStrum:FlxCamera;
	public var camOther:FlxCamera; // used so substates dont collide with camHUD.alpha or camHUD.visible
	
	public static var cameraSpeed:Float = 1.0;
	public static var defaultCamZoom:Float = 1.0;
	public static var extraCamZoom:Float = 0.0;
	public static var forcedCamPos:Null<FlxPoint>;

	public static var camFollow:FlxObject = new FlxObject();
	
	// paused
	public static var paused:Bool = false;

	public static function resetStatics()
	{
		health = 1;
		cameraSpeed = 1.0;
		defaultCamZoom = 1.0;
		extraCamZoom = 0.0;
		forcedCamPos = null;
		paused = false;
		
		Timings.init();
		SplashNote.resetStatics();
		
		var pixelSongs:Array<String> = [
			'collision',
			'senpai',
			'roses',
			'thorns',
		];
		
		assetModifier = "base";
		
		if(SONG == null) return;
		if(pixelSongs.contains(SONG.song))
			assetModifier = "pixel";
	}

	override public function create()
	{
		super.create();
		CoolUtil.playMusic();
		resetStatics();
		//if(SONG == null)
		//	SONG = SongData.loadFromJson("ugh");
		
		// preloading stuff
		/*Paths.preloadPlayStuff();
		Rating.preload(assetModifier);*/
		
		// adjusting the conductor
		Conductor.setBPM(SONG.bpm);
		Conductor.mapBPMChanges(SONG);
		
		// setting up the cameras
		camGame = new FlxCamera();
		
		camHUD = new FlxCamera();
		camHUD.bgColor.alphaFloat = 0;
		
		camStrum = new FlxCamera();
		camStrum.bgColor.alpha = 0;
		
		camOther = new FlxCamera();
		camOther.bgColor.alpha = 0;
		
		// adding the cameras
		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camStrum, false);
		FlxG.cameras.add(camOther, false);
		
		// default camera
		FlxG.cameras.setDefaultDrawTarget(camGame, true);
		
		//camGame.zoom = 0.6;
		
		stageBuild = new Stage();
		stageBuild.reloadStageFromSong(SONG.song);
		add(stageBuild);
		
		camGame.zoom = defaultCamZoom + extraCamZoom;
		hudBuild = new HudClass();
		hudBuild.setAlpha(0);
		
		/*
		*	if you want to change characters
		*	use changeChar(charVar, "new char");
		*	remember to put false for non-singers (like gf)
		*	so it doesnt reload the icons
		*/
		gf = new Character();
		// check changeStage to change gf
		//changeChar(gf, "gf", false);
		
		dad = new Character();
		changeChar(dad, SONG.player2);
		
		boyfriend = new Character();
		boyfriend.isPlayer = true;
		changeChar(boyfriend, SONG.player1);
		
		// also updates the characters positions
		changeStage(stageBuild.curStage);
		
		characters.push(gf);
		characters.push(dad);
		characters.push(boyfriend);
		
		// basic layering ig
		var addList:Array<FlxBasic> = [];
		
		for(char in characters)
		{
			if(char.curChar == gf.curChar && char != gf && gf.visible)
			{
				changeChar(char, gf.curChar);
				char.setPosition(gf.x, gf.y);
				gf.visible = false;
			}
			
			addList.push(char);
		}
		addList.push(stageBuild.foreground);
		
		for(item in addList)
			add(item);
		
		hudBuild.cameras = [camHUD];
		add(hudBuild);
		
		// strumlines
		strumlines = new FlxTypedGroup();
		strumlines.cameras = [camStrum];
		add(strumlines);
		
		//strumline.scrollSpeed = 4.0; // 2.8
		var strumPos:Array<Float> = [FlxG.width / 2, FlxG.width / 4];
		var downscroll:Bool = SaveData.data.get("Downscroll");
		
		dadStrumline = new Strumline(strumPos[0] - strumPos[1], dad, downscroll, false, true, assetModifier);
		dadStrumline.ID = 0;
		strumlines.add(dadStrumline);
		
		bfStrumline = new Strumline(strumPos[0] + strumPos[1], boyfriend, downscroll, true, false, assetModifier);
		bfStrumline.ID = 1;
		strumlines.add(bfStrumline);
		
		if(SaveData.data.get("Middlescroll"))
		{
			dadStrumline.x -= strumPos[0]; // goes offscreen
			bfStrumline.x  -= strumPos[1]; // goes to the middle
			
			// the best thing ever
			/*var guitar = new DistantNoteShader();
			guitar.downscroll = downscroll;
			camStrum.setFilters([new openfl.filters.ShaderFilter(cast guitar.shader)]);*/
		}
		
		for(strumline in strumlines.members)
		{
			strumline.scrollSpeed = SONG.speed;
			strumline.updateHitbox();
		}

		hudBuild.updateHitbox(bfStrumline.downscroll);
		
		/*for(strumline in strumlines.members)
		{
			strumline.isPlayer = !strumline.isPlayer;
			strumline.botplay = !strumline.botplay;
			if(!strumline.isPlayer)
			{
				strumline.downscroll = !strumline.downscroll;
				strumline.scrollSpeed = 1.0;
			}
			strumline.updateHitbox();
		}*/

		var daSong:String = SONG.song.toLowerCase();

		inst = new FlxSound();
		inst.loadEmbedded(Paths.inst(daSong), false, false);

		vocals = new FlxSound();
		if(SONG.needsVoices)
		{
			vocals.loadEmbedded(Paths.vocals(daSong), false, false);
		}

		songLength = inst.length;
		function addMusic(music:FlxSound):Void
		{
			FlxG.sound.list.add(music);

			if(music.length > 0)
			{
				musicList.push(music);

				if(music.length < songLength)
					songLength = music.length;
			}

			music.play();
			music.stop();
		}

		addMusic(inst);
		addMusic(vocals);

		//Conductor.setBPM(160);
		Conductor.songPos = -Conductor.crochet * 5;
		
		// setting up the camera following
		//followCamera(dad);
		followCamSection(SONG.notes[0]);
		//FlxG.camera.follow(camFollow, LOCKON, 1); // broken on lower/higher fps than 120
		FlxG.camera.focusOn(camFollow.getPosition());

		var unspawnNotesAll:Array<Note> = ChartLoader.getChart(SONG);

		for(note in unspawnNotesAll)
		{
			var thisStrumline = dadStrumline;
			for(strumline in strumlines)
			{
				if(note.strumlineID == strumline.ID)
					thisStrumline = strumline;
			}

			/*var thisStrum = thisStrumline.strumGroup.members[note.noteData];
			var thisChar = thisStrumline.character;*/

			var noteAssetMod:String = assetModifier;
			
			// the funny
			/*noteAssetMod = ["base", "pixel"][FlxG.random.int(0, 1)];
			if(note.isHold && note.parentNote != null)
				noteAssetMod = note.parentNote.assetModifier;*/

			note.reloadNote(note.songTime, note.noteData, note.noteType, noteAssetMod);

			// oop

			thisStrumline.addSplash(note);

			thisStrumline.unspawnNotes.push(note);
		}
		
		// sliding notes
		/*for(strumline in strumlines)
		{
			strumline._update = function(elapsed:Float)
			{
				var sinStrum = Math.sin((Conductor.songPos / Conductor.crochet) / 2);
				
				for(strum in strumline.strumGroup)
				{
					strum.screenCenter(Y);
					strum.y += sinStrum * FlxG.height * 0.4;
				}
				
				strumline.downscroll = (sinStrum > 0);
				
				var daSpeed:Float = SONG.speed * Math.abs(sinStrum);
				if(daSpeed <= 0) daSpeed = 0.01;
				strumline.scrollSpeed = daSpeed;
			}
		}*/

		switch(SONG.song.toLowerCase())
		{
			case "disruption":
				// faz o dad voar só na disruption
				var initialPos = [dad.x - (dad.width / 2) + 100, dad.y - 100];
				var flyTime:Float = 0;
				dad._update = function(elapsed:Float)
				{
					flyTime += elapsed * Math.PI;
					dad.y = initialPos[1] + Math.sin(flyTime) * 100;
					dad.x = initialPos[0] + Math.cos(flyTime) * 100;
					
					if(startedSong)
					{
						for(strum in dadStrumline.strumGroup)
						{
							var fuckyoubambi:Int = ((strum.strumData % 2 == 0) ? -1 : 1);
						
							strum.x = strum.initialPos.x + Math.sin(flyTime / 2) * 20 * fuckyoubambi;
							strum.y = strum.initialPos.y + Math.cos(flyTime / 2) * 20 * fuckyoubambi;
							strum.scale.x = strum.strumSize + Math.sin(flyTime / 2) * 0.3;
							strum.scale.y = strum.strumSize - Math.sin(flyTime / 2) * 0.3;
						}
						for(uNote in dadStrumline.unspawnNotes)
						{
							if(uNote.visible)
							{
								var daStrum = dadStrumline.strumGroup.members[uNote.noteData];
								uNote.scale.x = daStrum.scale.x;
								if(!uNote.isHold)
									uNote.scale.y = daStrum.scale.y;
							}
						}
					}
				}
		}

		// Updating Discord Rich Presence
		DiscordClient.changePresence("Playing: " + SONG.song.toUpperCase().replace("-", " "), null);
		for(strumline in strumlines.members)
		{
			var strumMult:Int = (strumline.downscroll ? 1 : -1);
			for(strum in strumline.strumGroup)
			{
				strum.y += FlxG.height / 4 * strumMult;
			}
		}
		
		if(hasCutscene())
		{
			switch(SONG.song)
			{
				case 'senpai'|'roses':
					CoolUtil.playMusic('dialogue/lunchbox');
					startDialogue(DialogueUtil.loadFromSong(SONG.song));
					
					if(SONG.song == 'roses')
						FlxG.sound.play(Paths.sound('dialogue/senpai/roses_sfx'));
				
				case 'thorns':
					CoolUtil.playMusic('dialogue/lunchbox-scary');
					Paths.preloadSound('sounds/dialogue/senpai/senpai_dies');
					var red = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
					red.cameras = [camHUD];
					red.scrollFactor.set();
					red.screenCenter();
					add(red);
					
					var spirit = new FlxSprite();
					spirit.frames = Paths.getSparrowAtlas('cutscenes/thorns/senpaiCrazy');
					spirit.animation.addByPrefix('dies', 'Senpai Pre Explosion', 24, false);
					spirit.antialiasing = false;
					spirit.scale.set(5,5);
					spirit.updateHitbox();
					spirit.cameras = [camHUD];
					spirit.scrollFactor.set();
					spirit.screenCenter();
					spirit.x += 80;
					spirit.y -= 20;
					add(spirit);
					
					spirit.alpha = 0;
					
					new FlxTimer().start(0.6, function(tmr:FlxTimer)
					{
						spirit.animation.play('dies');
						FlxTween.tween(spirit, {alpha: 1}, 0.5);
						FlxTween.tween(spirit, {alpha: 0}, 1.0, {startDelay: 3.2});
						
						FlxG.sound.play(Paths.sound('dialogue/senpai/senpai_dies'), 1, false, null, true, function()
						{
							camHUD.flash(0xFFff1b31, 0.6, null, true);
							remove(red);
							remove(spirit);
							
							new FlxTimer().start(0.8, function(tmr:FlxTimer)
							{
								startDialogue(DialogueUtil.loadFromSong('thorns'));
							});
						});
					});
					
				default:
					startCountdown();
			}
		}
		else
			startCountdown();
	}
	
	public var startedCountdown:Bool = false;
	public var startedSong:Bool = false;

	public function startCountdown()
	{
		var daCount:Int = 0;
		
		var countTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
		{
			Conductor.songPos = -Conductor.crochet * (4 - daCount);
			
			if(daCount == 0)
			{
				startedCountdown = true;
				for(strumline in strumlines.members)
				{
					for(strum in strumline.strumGroup)
					{
						var strumData:Int = (strumline.isPlayer ? strum.strumData : 3 - strum.strumData);
						FlxTween.tween(strum, {y: strum.initialPos.y}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeOut,
							startDelay: Conductor.crochet / 2 / 1000 * strumData,
						});
					}
				}
			}
			
			// when the girl say "one" the hud appears
			if(daCount == 2)
			{
				hudBuild.setAlpha(1, Conductor.crochet * 2 / 1000);
			}

			if(daCount == 4)
			{
				startSong();
			}

			if(daCount != 4)
			{
				var soundName:String = ["3", "2", "1", "Go"][daCount];
				
				var soundPath:String = assetModifier;
				if(!Paths.fileExists('sounds/countdown/$soundPath/intro$soundName.ogg'))
					soundPath = 'base';
				
				FlxG.sound.play(Paths.sound('countdown/$soundPath/intro$soundName'));
				
				if(daCount >= 1)
				{
					var countName:String = ["ready", "set", "go"][daCount - 1];
					
					var spritePath:String = assetModifier;
					if(!Paths.fileExists('images/hud/$spritePath/$countName.png'))
						spritePath = 'base';

					var countSprite = new FlxSprite();
					countSprite.loadGraphic(Paths.image('hud/$spritePath/$countName'));
					switch(spritePath)
					{
						case "pixel":
							countSprite.scale.set(6.5,6.5);
							countSprite.antialiasing = false;
						default:
							countSprite.scale.set(0.65,0.65);
					}
					countSprite.updateHitbox();
					countSprite.screenCenter();
					countSprite.cameras = [camHUD];
					hudBuild.add(countSprite);

					FlxTween.tween(countSprite, {alpha: 0}, Conductor.stepCrochet * 2.8 / 1000, {
						startDelay: Conductor.stepCrochet * 1 / 1000,
						onComplete: function(twn:FlxTween)
						{
							countSprite.destroy();
						}
					});
				}
			}

			//trace(daCount);

			daCount++;
		}, 5);
	}
	
	public function startDialogue(dialData:DialogueData)
	{
		new FlxTimer().start(0.45, function(tmr:FlxTimer)
		{
			var dial = new Dialogue();
			dial.finishCallback = function() {
				CoolUtil.playMusic();
				startCountdown();
				remove(dial);
			};
			dial.cameras = [camHUD];
			dial.load(dialData);
			add(dial);
		});
	}
	
	public function hasCutscene():Bool
	{
		return switch(SaveData.data.get('Cutscenes'))
		{
			default: true;
			case "FREEPLAY OFF": isStoryMode;
			case "OFF": false;
		}
	}

	public function startSong()
	{
		startedSong = true;
		for(music in musicList)
		{
			music.stop();
			music.play();

			if(paused) {
				music.pause();
			}
		}
	}

	override function openSubState(state:FlxSubState)
	{
		super.openSubState(state);
		if(startedSong)
		{
			for(music in musicList)
			{
				music.pause();
			}
		}
	}

	override function closeSubState()
	{
		activateTimers(true);
		super.closeSubState();
		if(startedSong)
		{
			for(music in musicList)
			{
				music.play();
			}
			syncSong(true);
		}
	}

	// for pausing timers and tweens
	function activateTimers(apple:Bool = true)
	{
		FlxTimer.globalManager.forEach(function(tmr:FlxTimer)
		{
			if(!tmr.finished)
				tmr.active = apple;
		});

		FlxTween.globalManager.forEach(function(twn:FlxTween)
		{
			if(!twn.finished)
				twn.active = apple;
		});
	}

	// check if you actually hit it
	public function checkNoteHit(note:Note, strumline:Strumline)
	{
		if(!note.mustMiss)
			onNoteHit(note, strumline);
		else
			onNoteMiss(note, strumline);
	}
	
	// actual note functions
	function onNoteHit(note:Note, strumline:Strumline)
	{
		var thisStrum = strumline.strumGroup.members[note.noteData];
		var thisChar = strumline.character;

		// anything else
		note.gotHeld = true;
		note.gotHit = true;
		note.missed = false;
		if(!note.isHold)
			note.visible = false;
		
		if(note.mustMiss) return;

		thisStrum.playAnim("confirm");

		// when the player hits notes
		vocals.volume = 1;
		if(strumline.isPlayer)
		{
			popUpRating(note, strumline, false);
		}
		
		//if(['default', 'none'].contains(note.noteType))
		//	trace('noteType: ${note.noteType}');

		if(!note.isHold)
		{
			var noteDiff:Float = Math.abs(note.songTime - Conductor.songPos);
			if(noteDiff <= Timings.timingsMap.get("sick")[0] || strumline.botplay)
			{
				strumline.playSplash(note);
			}
		}

		if(thisChar != null && !note.isHold)
		{
			if(note.noteType != "no animation")
			{
				thisChar.playAnim(thisChar.singAnims[note.noteData], true);
				thisChar.holdTimer = 0;

				/*if(note.noteType != 'none')
					thisChar.playAnim('hey');*/
			}
		}
	}
	function onNoteMiss(note:Note, strumline:Strumline)
	{
		var thisStrum = strumline.strumGroup.members[note.noteData];
		var thisChar = strumline.character;

		note.gotHit = false;
		note.missed = true;
		note.setAlpha();

		// put stuff inside onlyOnce
		var onlyOnce:Bool = false;
		if(!note.isHold)
			onlyOnce = true;
		else
		{
			if(note.parentNote.gotHit)
				onlyOnce = true;
		}

		if(onlyOnce)
		{
			vocals.volume = 0;

			FlxG.sound.play(Paths.sound('miss/missnote' + FlxG.random.int(1, 3)), 0.55);

			if(thisChar != null && note.noteType != "no animation")
			{
				thisChar.playAnim(thisChar.missAnims[note.noteData], true);
				thisChar.holdTimer = 0;
			}

			// when the player misses notes
			if(strumline.isPlayer)
			{
				popUpRating(note, strumline, true);
			}
		}
	}
	function onNoteHold(note:Note, strumline:Strumline)
	{
		// runs until you hold it enough
		if(note.holdHitLength > note.holdLength) return;
		
		var thisStrum = strumline.strumGroup.members[note.noteData];
		var thisChar = strumline.character;
		
		vocals.volume = 1;
		thisStrum.playAnim("confirm");
		
		// DIE!!!
		if(note.mustMiss)
			health -= 0.005;

		if(note.noteType != "no animation")
		{
			thisChar.playAnim(thisChar.singAnims[note.noteData], true);
			thisChar.holdTimer = 0;
		}
	}

	public function popUpRating(note:Note, strumline:Strumline, miss:Bool = false)
	{
		var noteDiff:Float = Math.abs(note.songTime - Conductor.songPos);
		if(note.isHold && !miss)
			noteDiff = 0;

		var rating:String = Timings.diffToRating(noteDiff);
		var judge:Float = Timings.diffToJudge(noteDiff);
		if(miss)
		{
			rating = "miss";
			judge = Timings.timingsMap.get('miss')[1];
		}

		// handling stuff
		health += 0.05 * judge;
		Timings.score += Math.floor(100 * judge);
		Timings.addAccuracy(judge);

		if(miss)
		{
			Timings.misses++;

			if(Timings.combo > 0)
				Timings.combo = 0;
			Timings.combo--;
		}
		else
		{
			if(Timings.combo < 0)
				Timings.combo = 0;
			Timings.combo++;

			if(rating == "shit")
			{
				//note.onMiss();
				// forces a miss anyway
				onNoteMiss(note, strumline);
			}
		}

		var daRating = new Rating(rating, Timings.combo, note.assetModifier);

		if(SaveData.data.get("Ratings on HUD"))
		{
			hudBuild.add(daRating);
			
			for(item in daRating.members)
				item.cameras = [camHUD];

			var daX:Float = (FlxG.width / 2) - 64;
			if(SaveData.data.get("Middlescroll"))
				daX -= FlxG.width / 4;

			daRating.setPos(daX, FlxG.height / 2);
		}
		else
		{
			add(daRating);

			daRating.setPos(
				boyfriend.x + boyfriend.ratingsOffset.x,
				boyfriend.y + boyfriend.ratingsOffset.y
			);
		}

		hudBuild.updateText();
	}
	
	var pressed:Array<Bool> 	= [];
	var justPressed:Array<Bool> = [];
	var released:Array<Bool> 	= [];
	
	var playerSinging:Bool = false;
	
	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		if(!paused)
		{
			var followLerp:Float = cameraSpeed * 5 * elapsed;
			if(followLerp > 1) followLerp = 1;
			
			CoolUtil.dumbCamPosLerp(camGame, camFollow, followLerp);
			/*camGame.followLerp = followLerp;*/
		}

		if(Controls.justPressed("PAUSE"))
		{
			pauseSong();
		}

		if(Controls.justPressed("RESET"))
			startGameOver();

		if(FlxG.keys.justPressed.SEVEN)
		{
			if(ChartingState.SONG.song != SONG.song)
				ChartingState.curSection = 0;
			
			ChartingState.songDiff = songDiff;

			ChartingState.SONG = SONG;
			Main.switchState(new ChartingState());
		}
		if(FlxG.keys.justPressed.EIGHT)
		{
			var char = dad;
			if(FlxG.keys.pressed.SHIFT)
				char = boyfriend;

			Main.switchState(new CharacterEditorState(char.curChar));
		}

		/*if(FlxG.keys.justPressed.SPACE)
		{
			for(strumline in strumlines.members)
			{
				strumline.downscroll = !strumline.downscroll;
				strumline.updateHitbox();
			}
			hudBuild.updateHitbox(bfStrumline.downscroll);
		}*/

		//strumline.scrollSpeed = 2.8 + Math.sin(FlxG.game.ticks / 500) * 1.5;

		//if(song.playing)
		//	Conductor.songPos = song.time;
		// syncSong
		if(startedCountdown)
			Conductor.songPos += elapsed * 1000;

		pressed = [
			Controls.pressed("LEFT"),
			Controls.pressed("DOWN"),
			Controls.pressed("UP"),
			Controls.pressed("RIGHT")
		];
		justPressed = [
			Controls.justPressed("LEFT"),
			Controls.justPressed("DOWN"),
			Controls.justPressed("UP"),
			Controls.justPressed("RIGHT")
		];
		released = [
			Controls.released("LEFT"),
			Controls.released("DOWN"),
			Controls.released("UP"),
			Controls.released("RIGHT")
		];
		
		playerSinging = false;
		
		// strumline handler!!
		for(strumline in strumlines.members)
		{
			for(strum in strumline.strumGroup)
			{
				if(strumline.isPlayer && !strumline.botplay)
				{
					if(pressed[strum.strumData])
					{
						if(!["pressed", "confirm"].contains(strum.animation.curAnim.name))
							strum.playAnim("pressed");
					}
					else
						strum.playAnim("static");
					
					if(strum.animation.curAnim.name == "confirm")
						playerSinging = true;
				}
				else
				{
					// how botplay handles it
					if(strum.animation.curAnim.name == "confirm"
					&& strum.animation.curAnim.finished)
						strum.playAnim("static");
				}
			}

			for(unsNote in strumline.unspawnNotes)
			{
				var spawnTime:Int = 1000;
				if(strumline.scrollSpeed <= 1.5)
					spawnTime = 5000;

				if(unsNote.songTime - Conductor.songPos <= spawnTime && !unsNote.spawned)
				{
					unsNote.y = FlxG.height * 4;
					unsNote.spawned = true;
					strumline.addNote(unsNote);
				}
			}
			for(note in strumline.allNotes)
			{
				var despawnTime:Int = 300;
				
				if(Conductor.songPos >= note.songTime + note.holdLength + Conductor.crochet + despawnTime)
				{
					if(!note.gotHit && !note.missed && !note.mustMiss && !strumline.botplay)
						onNoteMiss(note, strumline);
					
					strumline.removeNote(note);
				}
			}

			// downscroll
			var downMult:Int = (strumline.downscroll ? -1 : 1);

			for(note in strumline.noteGroup)
			{
				var thisStrum = strumline.strumGroup.members[note.noteData];
				
				// follows the strum
				note.x = thisStrum.x + note.noteOffset.x;
				note.y = thisStrum.y + (thisStrum.height / 12 * downMult) + (note.noteOffset.y * downMult);
				
				// adjusting according to the song position
				note.y += downMult * ((note.songTime - Conductor.songPos) * (strumline.scrollSpeed * 0.45));
				
				
				if(strumline.botplay)
				{
					// hitting notes automatically
					if(note.songTime - Conductor.songPos <= 0 && !note.gotHit && !note.mustMiss)
					{
						checkNoteHit(note, strumline);
					}
				}
				else
				{
					// missing notes automatically
					if(Conductor.songPos >= note.songTime + Timings.timingsMap.get("good")[0]
					&& !note.gotHit && !note.missed && !note.mustMiss)
					{
						onNoteMiss(note, strumline);
					}
				}

				// doesnt actually do anything
				if (note.scrollSpeed != strumline.scrollSpeed)
					note.scrollSpeed = strumline.scrollSpeed;
			}
			
			for(hold in strumline.holdGroup)
			{
				if(hold.scrollSpeed != strumline.scrollSpeed)
				{
					hold.scrollSpeed = strumline.scrollSpeed;

					if(!hold.isHoldEnd)
					{
						var newHoldSize:Array<Float> = [
							hold.frameWidth * hold.scale.x,
							hold.noteCrochet * (strumline.scrollSpeed * 0.45)
						];
						
						if(SaveData.data.get("Split Holds"))
							newHoldSize[1] -= 20;

						hold.setGraphicSize(
							Math.floor(newHoldSize[0]),
							Math.floor(newHoldSize[1])
						);
					}

					hold.updateHitbox();
				}

				hold.flipY = strumline.downscroll;
				if(hold.assetModifier == "base")
					hold.flipX = hold.flipY;
				
				var holdParent = hold.parentNote;
				if(holdParent != null)
				{
					var thisStrum = strumline.strumGroup.members[hold.noteData];
					
					hold.x = holdParent.x;
					hold.y = holdParent.y;
					if(!holdParent.isHold)
					{
						hold.x += holdParent.width / 2 - hold.width / 2;
						hold.y = holdParent.y + holdParent.height / 2;
						if(strumline.downscroll)
							hold.y -= hold.height;
					}
					else
					{
						if(strumline.downscroll)
							hold.y -= hold.height;
						else
							hold.y += holdParent.height;
					}
					
					if(SaveData.data.get('Split Holds'))
						hold.y += 20 * downMult;
					
					if(holdParent.gotHeld && !hold.missed)
					{
						hold.gotHeld = true;
						
						hold.holdHitLength = (Conductor.songPos - hold.songTime);
							
						var daRect = new FlxRect(
							0,
							0,
							hold.frameWidth,
							hold.frameHeight
						);
						
						var center:Float = (thisStrum.y + thisStrum.height / 2);
						if(!strumline.downscroll)
						{
							if(hold.y < center)
								daRect.y = (center - hold.y) / hold.scale.y;
						}
						else
						{
							if(hold.y + hold.height > center)
								daRect.y = ((hold.y + hold.height) - center) / hold.scale.y;
						}
						hold.clipRect = daRect;
						
						if(hold.isHoldEnd)
							onNoteHold(hold, strumline);
						
						if(hold.holdHitLength >= holdParent.holdLength - Conductor.stepCrochet)
						{
							if(hold.isHoldEnd && !hold.gotHit)
								onNoteHit(hold, strumline);
							hold.missed = false;
							hold.gotHit = true;
						}
						else if(!pressed[hold.noteData] && !strumline.botplay && strumline.isPlayer)
						{
							onNoteMiss(hold, strumline);
						}
					}
					
					if(holdParent.missed && !hold.missed)
						onNoteMiss(hold, strumline);
				}
			}

			if(justPressed.contains(true) && !strumline.botplay && strumline.isPlayer)
			{
				for(i in 0...justPressed.length)
				{
					if(justPressed[i])
					{
						var possibleHitNotes:Array<Note> = []; // gets the possible ones
						var canHitNote:Note = null;
						
						for(note in strumline.noteGroup)
						{
							var noteDiff:Float = (note.songTime - Conductor.songPos);
							
							if(noteDiff <= Timings.minTiming && !note.missed && !note.gotHit && note.noteData == i)
							{
								possibleHitNotes.push(note);
								canHitNote = note;
							}
						}
						
						// if the note actually exists then you got it
						if(canHitNote != null)
						{
							for(note in possibleHitNotes)
							{
								if(note.songTime < Conductor.songPos && note.mustMiss)
									continue;
								
								if(note.songTime < canHitNote.songTime)
									canHitNote = note;
							}

							checkNoteHit(canHitNote, strumline);
						}
						else
						{
							// you ghost tapped lol
							if(!SaveData.data.get("Ghost Tapping") && startedCountdown)
							{
								vocals.volume = 0;
								var thisChar = strumline.character;
								if(thisChar != null)
								{
									thisChar.playAnim(thisChar.missAnims[i], true);
									thisChar.holdTimer = 0;
								}

								var note = new Note();
								note.reloadNote(0, i, "none", assetModifier);
								onNoteMiss(note, strumline);
							}
						}
					}
				}
			}
			
			if(SONG.song == "exploitation")
			{
				for(note in strumline.allNotes)
				{
					//var noteSine:Float = (Conductor.songPos / 1000);
					//hold.scale.x = 0.7 + Math.sin(noteSine) * 0.8;
					if(!note.gotHeld)
					note.x += Math.sin((Conductor.songPos - note.songTime) / 100) * 80 * (strumline.isPlayer ? 1 : -1);
				}
			}
		}
		
		if(startedCountdown)
		{
			var lastSteps:Int = 0;
			var curSect:SwagSection = null;
			for(section in SONG.notes)
			{
				if(curStep >= lastSteps)
					curSect = section;

				lastSteps += section.lengthInSteps;
			}
			if(curSect != null)
			{
				followCamSection(curSect);
			}
		}
		// stuff
		if(forcedCamPos != null)
			camFollow.setPosition(forcedCamPos.x, forcedCamPos.y);

		if(health <= 0)
		{
			startGameOver();
		}
		
		function lerpCamZoom(daCam:FlxCamera, target:Float = 1.0, speed:Int = 6)
			daCam.zoom = FlxMath.lerp(daCam.zoom, target, elapsed * speed);
			
		lerpCamZoom(camGame, defaultCamZoom + extraCamZoom);
		lerpCamZoom(camHUD);
		lerpCamZoom(camStrum);
		
		health = FlxMath.bound(health, 0, 2); // bounds the health
	}
	
	public function followCamSection(sect:SwagSection):Void
	{
		followCamera(dadStrumline.character);
		
		if(sect != null)
		{
			if(sect.mustHitSection)
				followCamera(bfStrumline.character);
			
			switch(SONG.song)
			{
				case "tutorial":
					// shakes the camera a little when zooming
					FlxTween.tween(PlayState, {extraCamZoom: (sect.mustHitSection ? 0 : 0.5)}, Conductor.crochet / 1000, {
						ease: !sect.mustHitSection ? FlxEase.cubeOut : FlxEase.cubeInOut
					});
			}
		}
	}

	public function followCamera(?char:Character, ?offsetX:Float = 0, ?offsetY:Float = 0)
	{
		camFollow.setPosition(0,0);

		if(char != null)
		{
			var playerMult:Int = (char.isPlayer ? -1 : 1);

			camFollow.setPosition(char.getMidpoint().x + (200 * playerMult), char.getMidpoint().y - 20);

			camFollow.x += char.cameraOffset.x * playerMult;
			camFollow.y += char.cameraOffset.y;
		}

		camFollow.x += offsetX;
		camFollow.y += offsetY;
	}

	override function beatHit()
	{
		super.beatHit();
		for(change in Conductor.bpmChangeMap)
		{
			if(curStep >= change.stepTime && Conductor.bpm != change.bpm)
				Conductor.setBPM(change.bpm);
		}
		hudBuild.beatHit(curBeat);
		
		// hey!!
		switch(SONG.song)
		{
			case "tutorial":
				if([30, 46].contains(curBeat))
				{
					dad.holdTimer = 0;
					dad.playAnim('cheer', true);
				}
			case 'bopeebo':
				if(curBeat % 8 == 7 && curBeat > 0)
				{
					boyfriend.holdTimer = 0;
					boyfriend.playAnim("hey");
				}
		}
		
		/*if(curBeat >= 8)
		{
			Conductor.songPos = 0;
			for(music in musicList)
				music.time = 0;
			
			for(strumline in strumlines)
				for(uNote in strumline.unspawnNotes)
					uNote.resetNote();
		}*/

		if(curBeat % 4 == 0)
		{
			zoomCamera(0.05, 0.025);
		}
		for(char in characters)
		{
			if(curBeat % 2 == 0 || char.quickDancer)
			{
				var canIdle = (char.holdTimer >= char.holdLength);
				
				if(char.isPlayer && playerSinging)
					canIdle = false;

				if(canIdle)
					char.dance();
			}
		}
	}

	override function stepHit()
	{
		super.stepHit();
		stageBuild.stepHit(curStep);
		syncSong();
	}

	public function syncSong(?forced:Bool = false):Void
	{
		if(!startedSong) return;
		
		if(inst.playing)
		{
			// syncs the conductor
			if(Math.abs(Conductor.songPos - inst.time) >= 40 || forced)
			{
				trace('synced song ${Conductor.songPos} to ${inst.time}');
				Conductor.songPos = inst.time;
			}
			
			// syncs the other music to the inst
			for(music in musicList)
			{
				if(music == inst) return;
				
				if(music.playing)
				{
					if(Math.abs(music.time - inst.time) >= 40)
					{
						music.time = inst.time;
						//music.play();
					}
				}
			}
		}
		
		if(!inst.playing && Conductor.songPos > 0 && !paused)
			endSong();
		
		// checks if the song is allowed to end
		if(Conductor.songPos >= songLength)
			endSong();
	}
	
	// ends it all
	public function endSong()
	{
		Highscore.addScore(SONG.song.toLowerCase() + '-' + songDiff, {
			score: 		Timings.score,
			accuracy: 	Timings.accuracy,
			misses: 	Timings.misses,
		});
		
		weekScore += Timings.score;
		
		if(playList.length <= 0)
		{
			if(isStoryMode)
			{
				Highscore.addScore('week-$curWeek-$songDiff', {
					score: 		weekScore,
					accuracy: 	0,
					misses: 	0,
				});
			}
			
			sendToMenu();
		}
		else
		{
			SONG = SongData.loadFromJson(playList[0], songDiff);
			playList.remove(playList[0]);
			
			//trace(playList);
			//Main.switchState(new PlayState());
			Main.switchState(new LoadSongState());
		}
	}

	override function onFocusLost():Void
	{
		pauseSong();
		super.onFocusLost();
	}

	public function pauseSong()
	{
		if(!startedCountdown || paused || isDead) return;
		
		paused = true;
		activateTimers(false);
		openSubState(new PauseSubState());
	}
	
	public var isDead:Bool = false;
	
	public function startGameOver()
	{
		if(isDead || !startedCountdown) return;
		
		isDead = true;
		activateTimers(false);
		persistentDraw = false;
		openSubState(new GameOverSubState(boyfriend));
	}

	public function zoomCamera(gameZoom:Float = 0, hudZoom:Float = 0)
	{
		camGame.zoom += gameZoom;
		camHUD.zoom += hudZoom;
		camStrum.zoom += hudZoom;
	}
	
	// funny thingy
	public function changeChar(char:Character, newChar:String = "bf", ?iconToo:Bool = true)
	{
		// gets the original position
		var storedPos = new FlxPoint(
			char.x - char.globalOffset.x,
			char.y + char.height - char.globalOffset.y
		);
		// changes the character
		char.reloadChar(newChar);
		// returns it to the correct position
		char.setPosition(
			storedPos.x + char.globalOffset.x,
			storedPos.y - char.height + char.globalOffset.y
		);

		if(iconToo)
		{
			// updating icons
			var daID:Int = (char.isPlayer ? 1 : 0);
			hudBuild.changeIcon(daID, char.curChar);
		}
		
		var evilTrail = char._dynamic["evilTrail"];
		if(evilTrail != null)
		{
			remove(evilTrail);
			evilTrail = null;
		}
		switch(newChar)
		{
			case 'spirit':
				evilTrail = new FlxTrail(char, null, 4, 24, 0.3, 0.069);
				add(evilTrail);
		}
	}

	// funny thingy
	public function changeStage(newStage:String = "stage")
	{
		stageBuild.reloadStage(newStage);
		
		// gfpos
		if(stageBuild.gfVersion == "") {
			changeChar(gf, "gf", false);
			gf.visible = false;
		} else {
			changeChar(gf, stageBuild.gfVersion, false);
			gf.setPosition(stageBuild.gfPos.x, stageBuild.gfPos.y);
			gf.x -= gf.width / 2;
			gf.y -= gf.height;
			gf.visible = true;
		}

		dad.setPosition(stageBuild.dadPos.x, stageBuild.dadPos.y);
		dad.y -= dad.height;

		boyfriend.setPosition(stageBuild.bfPos.x, stageBuild.bfPos.y);
		boyfriend.y -= boyfriend.height;

		for(char in [gf, dad, boyfriend])
		{
			char.x += char.globalOffset.x;
			char.y += char.globalOffset.y;
		}
		
		switch(newStage)
		{
			default:
				// add your custom stuff here
		}
	}
	
	// substates also use this
	public static function sendToMenu()
	{
		CoolUtil.playMusic();
		if(isStoryMode)
		{
			isStoryMode = false;
			Main.switchState(new StoryMenuState());
		}
		else
		{
			Main.switchState(new FreeplayState());
		}
	}
}