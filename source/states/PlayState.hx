package states;

import data.Discord.DiscordClient;
import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.addons.effects.FlxTrail;
import flixel.group.FlxGroup;
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
	public static var health:Float = 1;
	public static var blueballed:Int = 0;
	public static var assetModifier:String = "base";
	
	public static var countdownModifier:String = "base";
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
	
	var unspawnCount:Int = 0;
	public var unspawnNotes:Array<Note> = [];
	
	public static var botplay:Bool = false;
	public static var validScore:Bool = true;
	public var ghostTapping:Bool = true;

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

	public static var startedCountdown:Bool = false;
	public static var startedSong:Bool = false;
	
	public static var instance:PlayState;
	
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
		
		validScore = true;
		
		Timings.init();
		SplashNote.resetStatics();
		
		var pixelSongs:Array<String> = [
			'collision',
			'senpai',
			'roses',
			'thorns',
		];
		
		assetModifier = "base";
		countdownModifier = "base";
		startedCountdown = false;
		startedSong = false;
		
		if(SONG == null) return;
		if(pixelSongs.contains(SONG.song))
		{
			assetModifier = "pixel";
			if(!['collision'].contains(SONG.song))
				countdownModifier = "pixel";
		}
		if(FlxG.random.bool(0.01))
			assetModifier = "doido";
	}
	
	public static function resetSongStatics()
	{
		blueballed = 0;
	}

	override public function create()
	{
		super.create();
		instance = this;
		CoolUtil.playMusic();
		resetStatics();
		//if(SONG == null)
		//	SONG = SongData.loadFromJson("ugh");
		
		// preloading stuff
		/*Paths.preloadPlayStuff();
		Rating.preload(assetModifier);*/
		
		//trace('tu ta jogando na linguagem ${openfl.system.Capabilities.language}');
		
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
		// CHECK CHANGESTAGE TO CHANGE GF
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

		ghostTapping = SaveData.data.get('Ghost Tapping');
		var downscroll:Bool = SaveData.data.get("Downscroll");
		
		dadStrumline = new Strumline(0, dad, downscroll, false, true, assetModifier);
		dadStrumline.ID = 0;
		strumlines.add(dadStrumline);
		
		bfStrumline = new Strumline(0, boyfriend, downscroll, true, false, assetModifier);
		bfStrumline.ID = 1;
		strumlines.add(bfStrumline);
		
		if(SaveData.data.get("Middlescroll"))
		{
			/*dadStrumline.x -= strumPos[0]; // goes offscreen
			bfStrumline.x  -= strumPos[1]; // goes to the middle
			*/
			// the best thing ever
			/*var guitar = new DistantNoteShader();
			guitar.downscroll = downscroll;
			camStrum.setFilters([new openfl.filters.ShaderFilter(cast guitar.shader)]);*/
			/*for(strumline in strumlines.members)
				if(!strumline.isPlayer)
					for(strum in strumline.strumGroup)
						strum.visible = false;*/
		}
		
		for(strumline in strumlines.members)
		{
			strumline.x = setStrumlineDefaultX()[strumline.ID];
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

		unspawnNotes = ChartLoader.getChart(SONG);
		
		for(note in unspawnNotes)
		{
			var thisStrumline = dadStrumline;
			for(strumline in strumlines)
				if(note.strumlineID == strumline.ID)
					thisStrumline = strumline;
			
			var noteAssetMod:String = assetModifier;
			
			// the funny
			/*noteAssetMod = ["base", "pixel"][FlxG.random.int(0, 1)];
			if(note.isHold && note.parentNote != null)
				noteAssetMod = note.parentNote.assetModifier;*/
			
			note.reloadNote(note.songTime, note.noteData, note.noteType, noteAssetMod);
			note.setSongOffset();
			
			// oop
			
			thisStrumline.addSplash(note);
			
			//thisStrumline.unspawnNotes.push(note);
			
			/*if(!note.isHold)
				note.noteAngle = FlxG.random.int(-5, 5);*/
		}
		
		// Updating Discord Rich Presence and making notes invisible before the countdown
		for(strumline in strumlines.members)
		{
			var strumMult:Int = (strumline.downscroll ? 1 : -1);
			for(strum in strumline.strumGroup)
			{
				strum.y += CoolUtil.noteWidth() * 0.6 * strumMult;
				strum.alpha = 0.0001;
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
							CoolUtil.flash(camHUD, 0.6, 0xFFff1b31, true);
							//camHUD.flash(0xFFff1b31, 0.6, null, true);
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
						// dad's notes spawn backwards
						var strumMult:Int = (strumline.isPlayer ? strum.strumData : 3 - strum.strumData);
						// actual tween
						FlxTween.tween(strum, {y: strum.initialPos.y, alpha: 0.9}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeOut,
							startDelay: Conductor.crochet / 2 / 1000 * strumMult,
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
				
				var soundPath:String = countdownModifier;
				if(!Paths.fileExists('sounds/countdown/$soundPath/intro$soundName.ogg'))
					soundPath = 'base';
				
				FlxG.sound.play(Paths.sound('countdown/$soundPath/intro$soundName'));
				
				if(daCount >= 1)
				{
					var countName:String = ["ready", "set", "go"][daCount - 1];
					
					var spritePath:String = countdownModifier;
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
			syncSong();
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
	
	var singAnims:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];
	
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
		else
			note.setAlpha();

		if(note.mustMiss) return;

		thisStrum.playAnim("confirm", true);

		// when the player hits notes
		vocals.volume = 1;
		if(strumline.isPlayer)
		{
			popUpRating(note, strumline, false);
			if(!note.isHold && SaveData.data.get("Hitsounds") != "OFF")
				FlxG.sound.play(
					Paths.sound('hitsounds/${SaveData.data.get("Hitsounds")}'),
					SaveData.data.get("Hitsound Volume") / 10
				);
		}
		
		//if(!['default', 'none'].contains(note.noteType))
		//	trace('noteType: ${note.noteType}');

		if(!note.isHold)
		{
			var noteDiff:Float = Math.abs(note.songTime - Conductor.songPos);
			if(noteDiff <= Timings.getTimings("sick")[1] || strumline.botplay)
			{
				strumline.playSplash(note);
			}
		}

		if(thisChar != null && !note.isHold)
		{
			if(note.noteType != "no animation")
			{
				thisChar.playAnim(singAnims[note.noteData], true);
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
		
		// put stuff inside if(onlyOnce)
		var onlyOnce:Bool = false;
		if(!note.isHold)
			onlyOnce = true;
		else
		{
			if(note.isHoldEnd && note.holdHitLength > 0)
				onlyOnce = true;
		}
		// onlyOnce is to prevent the game punishing you for missing a bunch of hold notes pieces
		if(onlyOnce)
		{
			vocals.volume = 0;
			
			FlxG.sound.play(Paths.sound('miss/missnote' + FlxG.random.int(1, 3)), 0.55);
			
			if(thisChar != null && note.noteType != "no animation")
			{
				thisChar.playAnim(singAnims[note.noteData] + 'miss', true);
				thisChar.holdTimer = 0;
			}
			
			// when the player misses notes
			if(strumline.isPlayer)
			{
				popUpRating(note, strumline, true);
				switch(note.noteType)
				{
					case "EX Note":
						startGameOver();
						return;
				}
				
				switch(SONG.song)
				{
					case 'defeat':
						if(Timings.misses > 5) {
							startGameOver();
							return;
						}
				}
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
		thisStrum.playAnim("confirm", true);
		
		// DIE!!!
		if(note.mustMiss)
			health -= 0.005;
		
		if(note.gotHit) return;
		
		if(note.noteType != "no animation")
		{
			thisChar.playAnim(singAnims[note.noteData], true);
			thisChar.holdTimer = 0;
		}
	}

	var prevRating:Rating = null;
	
	public function popUpRating(note:Note, strumline:Strumline, miss:Bool = false)
	{
		// return;
		var noteDiff:Float = Math.abs(note.songTime - Conductor.songPos);
		if(strumline.botplay)
			noteDiff = 0;

		if(note.isHold && !miss)
		{
			noteDiff = Timings.minTiming;
			var holdPercent:Float = (note.holdHitLength / note.holdLength);
			for(timing in Timings.holdTimings)
			{
				if(holdPercent >= timing[0] && noteDiff > timing[1])
					noteDiff = timing[1];
			}
		}

		var rating:String = Timings.diffToRating(noteDiff);
		var judge:Float = Timings.diffToJudge(noteDiff);
		if(miss)
		{
			rating = "miss";
			judge = Timings.getTimings("miss")[2];
		}
		
		var healthJudge:Float = 0.05 * judge;
		if(judge < 0)
			healthJudge *= 2;

		if(healthJudge < 0)
		{
			if(songDiff == "easy")
				healthJudge *= 0.5;
			if(songDiff == "normal")
				healthJudge *= 0.8;
		}

		// handling stuff
		health += healthJudge;
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
			
			// regains your health only if you hold it entirely
			if(note.isHold)
				health += 0.05 * (note.holdHitLength / note.holdLength);
			
			if(rating == "shit")
			{
				//note.onMiss();
				// forces a miss anyway
				onNoteMiss(note, strumline);
			}
		}
		
		hudBuild.updateText();
		
		var daRating = new Rating(rating, Timings.combo, note.assetModifier);

		if(SaveData.data.get("Single Rating"))
		{
			if(prevRating != null)
				prevRating.kill();
			
			prevRating = daRating;
		}
		
		if(SaveData.data.get("Ratings on HUD"))
		{
			hudBuild.ratingGrp.add(daRating);
			
			for(item in daRating.members)
				item.cameras = [camHUD];
			
			var daX:Float = (FlxG.width / 2);
			if(SaveData.data.get("Middlescroll"))
				daX -= FlxG.width / 4;

			daRating.setPos(daX, SaveData.data.get('Downscroll') ? FlxG.height - 100 : 100);
		}
		else
		{
			add(daRating);

			daRating.setPos(
				boyfriend.x + boyfriend.ratingsOffset.x,
				boyfriend.y + boyfriend.ratingsOffset.y
			);
		}
	}
	
	var pressed:Array<Bool> 	= [];
	var justPressed:Array<Bool> = [];
	var released:Array<Bool> 	= [];
	
	var playerSinging:Bool = false;
	
	//var sidewayShit:Bool = false;
	var hoverStrum:StrumNote = null;
	var holdStrum:StrumNote = null;
	var isBroken:Array<Bool> = [false,false,false,false];
	var fakeStrums:Array<FlxSprite> = [];
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		var followLerp:Float = cameraSpeed * 5 * elapsed;
		if(followLerp > 1) followLerp = 1;
		
		CoolUtil.dumbCamPosLerp(camGame, camFollow, followLerp);
		
		if(Controls.justPressed("PAUSE"))
			pauseSong();

		if(Controls.justPressed("RESET"))
			startGameOver();

		/*if(!FlxG.mouse.visible) FlxG.mouse.visible = true;
		
		if(FlxG.keys.pressed.SPACE)
		{
			//FlxG.stage.window.warpMouse(20, 20);
			FlxG.stage.window.cursor = POINTER;
		}*/
		
		/*if(FlxG.keys.justPressed.SPACE)
			hudBuild.healthBar.flipIcons = !hudBuild.healthBar.flipIcons;
		
		if(FlxG.keys.justPressed.H)
		{
			hudBuild.changeIcon(
				FlxG.random.int(0, 1),
				CoolUtil.charList()[FlxG.random.int(0, CoolUtil.charList().length - 1)]
			);
		}*/
		
		// no turning back you gotta restart now sorry
		if(botplay && startedSong)
			validScore = false;

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
		
		/*if(FlxG.keys.justPressed.H)
		{
			sidewayShit = !sidewayShit;
			for(strum in dadStrumline.strumGroup)
			{
				var off:Float = (sidewayShit ? -FlxG.width : 0);
				FlxTween.tween(strum, {x: strum.initialPos.x + off, y: strum.initialPos.y}, 0.8, {
					ease: FlxEase.cubeInOut,
					startDelay: (0.05) * (sidewayShit ? strum.strumData : 3 - strum.strumData)
				});
			}
			
			var daAngle:Float = (sidewayShit ? -90 : 0);
			for(strum in bfStrumline.strumGroup)
			{
				var daPos = new FlxPoint(strum.initialPos.x, strum.initialPos.y);
				if(sidewayShit)
				{
					daPos.x = (bfStrumline.downscroll ? 100 : FlxG.width - 100);
					daPos.y = FlxG.height / 2;
					daPos.y += CoolUtil.noteWidth() * strum.strumData;
					daPos.y -= (CoolUtil.noteWidth() * 3) / 2;
				}
				
				var daCheck:Bool = !sidewayShit;
				if(bfStrumline.downscroll)
					daCheck = !daCheck;
				
				FlxTween.tween(strum, {x: daPos.x, y: daPos.y, angle: -daAngle, strumAngle: daAngle}, 0.8, {
					ease: FlxEase.cubeInOut,
					startDelay: (0.05) * (daCheck ? strum.strumData : 3 - strum.strumData)
				});
			}
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
			Controls.pressed("RIGHT"),
		];
		justPressed = [
			Controls.justPressed("LEFT"),
			Controls.justPressed("DOWN"),
			Controls.justPressed("UP"),
			Controls.justPressed("RIGHT"),
		];
		released = [
			Controls.released("LEFT"),
			Controls.released("DOWN"),
			Controls.released("UP"),
			Controls.released("RIGHT"),
		];
		
		playerSinging = false;
		
		// adding notes to strumlines
		if(unspawnCount < unspawnNotes.length)
		{
			var unsNote = unspawnNotes[unspawnCount];
			
			var thisStrumline = dadStrumline;
			for(strumline in strumlines)
				if(unsNote.strumlineID == strumline.ID)
					thisStrumline = strumline;
			
			var spawnTime:Int = 3200;
			if(thisStrumline.scrollSpeed <= 1.5)
				spawnTime *= 2;
			
			if(unsNote.songTime - Conductor.songPos <= spawnTime)
			{
				unsNote.y = FlxG.height * 4;
				//unsNote.spawned = true;
				thisStrumline.addNote(unsNote);
				unspawnCount++;
			}
		}
		
		// strumline handler!!
		for(strumline in strumlines.members)
		{
			if(strumline.isPlayer)
				strumline.botplay = botplay;
			
			for(strum in strumline.strumGroup)
			{
				// no botplay animations
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
				else // how botplay handles it
				{
					if(strum.animation.curAnim.name == "confirm"
					&& strum.animation.curAnim.finished)
						strum.playAnim("static");
				}
			}
			
			for(note in strumline.allNotes)
			{
				var despawnTime:Int = 300;
				
				if(Conductor.songPos >= note.songTime + note.holdLength + Conductor.crochet + despawnTime)
				{
					if(!note.gotHit && !note.missed && !note.mustMiss && !strumline.botplay)
						onNoteMiss(note, strumline);
					
					note.clipRect = null;
					strumline.removeNote(note);
					note.destroy();
					continue;
				}
				
				note.setAlpha();
				note.updateHitbox();
				note.offset.x += note.frameWidth * note.scale.x / 2;
				if(note.isHold)
				{
					note.offset.y = 0;
					note.origin.y = 0;
				}
				else
					note.offset.y += note.frameHeight * note.scale.y / 2;
			}

			// downscroll
			//var downMult:Int = (strumline.downscroll ? -1 : 1);

			for(note in strumline.noteGroup)
			{
				var thisStrum = strumline.strumGroup.members[note.noteData];
				
				// follows the strum
				var offsetX = note.noteOffset.x;
				var offsetY = (note.songTime - Conductor.songPos) * (strumline.scrollSpeed * 0.45);
				// offsetY *= downMult;
				
				var noteAngle:Float = (note.noteAngle + thisStrum.strumAngle);
				if(strumline.downscroll)
					noteAngle += 180;
				
				note.angle = thisStrum.angle;
				CoolUtil.setNotePos(note, thisStrum, noteAngle, offsetX, offsetY);
				
				// alings the hold notes
				for(hold in note.children)
				{
					var offsetX = note.noteOffset.x;
					var offsetY = hold.noteCrochet * (strumline.scrollSpeed * 0.45) * hold.ID;
					
					hold.angle = -noteAngle;
					CoolUtil.setNotePos(hold, note, noteAngle, offsetX, offsetY);
				}
				
				if(strumline.botplay)
				{
					// hitting notes automatically
					if(note.songTime - Conductor.songPos <= 0 && !note.gotHit && !note.mustMiss)
						checkNoteHit(note, strumline);
				}
				else
				{
					// missing notes automatically
					if(Conductor.songPos >= note.songTime + Timings.getTimings("good")[1]
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
							hold.noteCrochet * (strumline.scrollSpeed * 0.45) + 1
						];
						
						if(SaveData.data.get("Split Holds"))
							newHoldSize[1] -= 20;
						
						hold.setGraphicSize(
							Math.floor(newHoldSize[0]),
							Std.int(newHoldSize[1])
						);
					}
					
					hold.updateHitbox();
				}
				
				var holdParent = hold.parentNote;
				if(holdParent != null)
				{
					var thisStrum = strumline.strumGroup.members[hold.noteData];
					
					if(holdParent.gotHeld && !hold.missed)
					{
						hold.gotHeld = true;
						
						hold.holdHitLength = (Conductor.songPos - hold.songTime);
							
						var daRect = new FlxRect(
							0, 0,
							hold.frameWidth,
							hold.frameHeight
						);
						
						var holdID:Float = hold.ID;
						if(hold.isHoldEnd)
							holdID -= 0.4999; // 0.5
						
						if(SaveData.data.get("Split Holds"))
							holdID -= 0.2;
						
						// calculating the clipping by how much you held the note
						var minSize:Float = hold.holdHitLength - (hold.noteCrochet * holdID);
						var maxSize:Float = hold.noteCrochet;
						if(minSize > maxSize)
							minSize = maxSize;
						
						if(minSize > 0)
							daRect.y = (minSize / maxSize) * hold.frameHeight;
						
						hold.clipRect = daRect;
						
						//if(hold.holdHitLength >= holdParent.holdLength - Conductor.stepCrochet)
						var notPressed = (!pressed[hold.noteData] && !strumline.botplay && strumline.isPlayer);
						var holdPercent:Float = (hold.holdHitLength / holdParent.holdLength);

						if(hold.isHoldEnd && !notPressed)
							onNoteHold(hold, strumline);
						
						if(notPressed || holdPercent >= 1.0)
						{
							if(holdPercent > 0.3)
							{
								if(hold.isHoldEnd && !hold.gotHit)
									onNoteHit(hold, strumline);
								hold.missed = false;
								hold.gotHit = true;
							}
							else
							{
								onNoteMiss(hold, strumline);
							}
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
							
							var minTiming:Float = Timings.minTiming;
							if(note.mustMiss)
								minTiming = Timings.getTimings("good")[1];
							
							if(noteDiff <= minTiming && !note.missed && !note.gotHit && note.noteData == i)
							{
								if(note.mustMiss
								&& Conductor.songPos >= note.songTime + Timings.getTimings("sick")[1])
								{
									continue;
								}
								
								possibleHitNotes.push(note);
								canHitNote = note;
							}
						}
						
						// if the note actually exists then you got it
						if(canHitNote != null)
						{
							for(note in possibleHitNotes)
							{
								if(note.songTime < canHitNote.songTime)
									canHitNote = note;
							}

							checkNoteHit(canHitNote, strumline);
						}
						else // you ghost tapped lol
						{
							if(!ghostTapping && startedCountdown)
							{
								vocals.volume = 0;

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
					//if(!note.gotHeld) // 5
					note.noteAngle = Math.sin((Conductor.songPos - note.songTime) / 100) * 10 * (strumline.isPlayer ? 1 : -1);
				}
			}
		}
		
		for(char in characters)
		{
			if(char.holdTimer != Math.NEGATIVE_INFINITY)
			{
				if(char.holdTimer < char.holdLength)
					char.holdTimer += elapsed;
				else
				{
					if(char.isPlayer && playerSinging)
						continue;
					
					char.holdTimer = Math.NEGATIVE_INFINITY;
					char.dance();
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
			startGameOver();
		
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

		if(curBeat % 4 == 0)
		{
			zoomCamera(0.05, 0.025);
		}
		for(char in characters)
		{
			if(curBeat % 2 == 0 || char.quickDancer)
			{
				var canIdle = (char.holdTimer == Math.NEGATIVE_INFINITY);
				
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
		DiscordClient.changePresence("Playing: " + SONG.song.toUpperCase().replace("-", " "), null);
		stageBuild.stepHit(curStep);
		syncSong();
	}

	public function syncSong():Void
	{
		if(!startedSong) return;
		
		if(!inst.playing && Conductor.songPos > 0 && !paused)
			endSong();
		
		if(inst.playing)
		{
			// syncs the conductor
			if(Math.abs(Conductor.songPos - inst.time) >= 40 && Conductor.songPos - inst.time <= 5000)
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
		
		// checks if the song is allowed to end
		if(Conductor.songPos >= songLength)
			endSong();
	}
	
	// ends it all
	var endedSong:Bool = false;
	public function endSong()
	{
		if(endedSong) return;
		endedSong = true;
		resetSongStatics();
		
		if(validScore)
		{
			Highscore.addScore(SONG.song.toLowerCase() + '-' + songDiff, {
				score: 		Timings.score,
				accuracy: 	Timings.accuracy,
				misses: 	Timings.misses,
			});
		}
		
		weekScore += Timings.score;
		
		if(playList.length <= 0)
		{
			if(isStoryMode && validScore)
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
		
		health = 0;
		isDead = true;
		blueballed++;
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

	// options substate
	public function updateOption(option:String):Void
	{
		if(['Middlescroll', 'Downscroll'].contains(option))
		{
			for(strumline in strumlines.members)
			{
				strumline.x = setStrumlineDefaultX()[strumline.ID];
				strumline.downscroll = SaveData.data.get('Downscroll');
				strumline.updateHitbox();
			}
			for(note in unspawnNotes)
			{
				var thisStrumline = dadStrumline;
				for(strumline in strumlines)
					if(note.strumlineID == strumline.ID)
						thisStrumline = strumline;
				
				if(!thisStrumline.isPlayer)
					note.visible = !SaveData.data.get('Middlescroll');
			}
			hudBuild.updateHitbox(bfStrumline.downscroll);
			update(0);
		}

		switch(option)
		{
			case 'Song Offset':
				for(note in unspawnNotes)
					note.setSongOffset();

			case 'Antialiasing':
				function loopGroup(group:FlxGroup):Void
				{
					if(group == null) return;
					for(item in group.members)
					{
						if(item == null) continue;
						if(Std.isOfType(item, FlxGroup))
							loopGroup(cast item);
						
						if(Std.isOfType(item, FlxSprite))
						{
							var sprite:FlxSprite = cast item;
							sprite.antialiasing = (sprite.isPixelSprite ? false : FlxSprite.defaultAntialiasing);
						}
					}
				}
				loopGroup(this);
			
			case 'Song Timer':
				hudBuild.timeTxt.visible = SaveData.data.get('Song Timer');
		}
	}

	public function setStrumlineDefaultX():Array<Float>
	{
		for(strumline in strumlines.members)
			if(!strumline.isPlayer)
				for(strum in strumline.strumGroup)
					strum.visible = !SaveData.data.get('Middlescroll');

		var strumPos:Array<Float> = [FlxG.width / 2, FlxG.width / 4];

		if(SaveData.data.get('Middlescroll'))
			return [-strumPos[0], strumPos[0]];
		else
			return [strumPos[0] - strumPos[1], strumPos[0] + strumPos[1]];
	}
	
	// substates also use this
	public static function sendToMenu()
	{
		CoolUtil.playMusic();
		resetSongStatics();
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