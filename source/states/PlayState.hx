package states;

import data.Discord.DiscordClient;
import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import data.*;
import data.SongData.SwagSong;
import data.chart.*;
import data.GameData.MusicBeatState;
import gameObjects.*;
import gameObjects.hud.*;
import gameObjects.hud.note.*;
import subStates.*;

using StringTools;

class PlayState extends MusicBeatState
{
	// song stuff
	public static var SONG:SwagSong;
	public var inst:FlxSound;
	public var vocals:FlxSound;
	public var musicList:Array<FlxSound> = [];

	// 
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
	public var camOther:FlxCamera; // used so substates dont collide with camHUD.alpha or camHUD.visible
	public static var defaultCamZoom:Float = 1.0;

	public var camFollow:FlxObject = new FlxObject();

	public static var paused:Bool = false;

	function resetStatics()
	{
		health = 1;
		defaultCamZoom = 1.0;
		assetModifier = "base";
		SplashNote.resetStatics();
		Timings.init();
		paused = false;
	}

	override public function create()
	{
		super.create();
		resetStatics();

		if(SONG == null)
			SONG = SongData.loadFromJson("ugh");

		if(SONG.song.toLowerCase() == "collision")
			assetModifier = "pixel";

		Conductor.setBPM(SONG.bpm);
		Conductor.mapBPMChanges(SONG);

		// setting up the cameras
		camGame = new FlxCamera();
		
		camHUD = new FlxCamera();
		camHUD.bgColor.alphaFloat = 0;

		camOther = new FlxCamera();
		camOther.bgColor.alpha = 0;

		// adding the cameras
		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);

		// default camera
		FlxG.cameras.setDefaultDrawTarget(camGame, true);

		//camGame.zoom = 0.6;

		stageBuild = new Stage();
		stageBuild.reloadStageFromSong(SONG.song);
		add(stageBuild);

		camGame.zoom = defaultCamZoom;

		dad = new Character();
		dad.reloadChar(SONG.player2, false);
		dad.setPosition(50, 700);
		dad.y -= dad.height;

		boyfriend = new Character();
		boyfriend.reloadChar(SONG.player1, true);
		boyfriend.setPosition(850, 700);
		boyfriend.y -= boyfriend.height;

		characters.push(dad);
		characters.push(boyfriend);

		for(char in characters)
		{
			char.x += char.globalOffset.x;
			char.y += char.globalOffset.y;
		}

		var addList:Array<FlxBasic> = [dad, boyfriend];

		for(item in addList)
			add(item);

		followCamera(dad);

		FlxG.camera.follow(camFollow, LOCKON, 1);
		FlxG.camera.focusOn(camFollow.getPosition());

		hudBuild = new HudClass();
		hudBuild.cameras = [camHUD];
		add(hudBuild);

		// strumlines
		strumlines = new FlxTypedGroup();
		strumlines.cameras = [camHUD];
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
		}

		for(strumline in strumlines.members)
		{
			strumline.scrollSpeed = SONG.speed;
			strumline.updateHitbox();
		}

		hudBuild.updateHitbox(bfStrumline.downscroll);

		var daSong:String = SONG.song.toLowerCase();

		inst = new FlxSound();
		inst.loadEmbedded(Paths.inst(daSong), false, false);
		

		vocals = new FlxSound();
		if(SONG.needsVoices)
		{
			vocals.loadEmbedded(Paths.vocals(daSong), false, false);
		}

		FlxG.sound.list.add(inst);
		FlxG.sound.list.add(vocals);

		musicList.push(inst);
		musicList.push(vocals);

		for(music in musicList)
		{
			music.play();
			music.pause();
		}

		//Conductor.setBPM(160);
		Conductor.songPos = -Conductor.crochet * 5;

		var unspawnNotesAll:Array<Note> = ChartLoader.getChart(SONG);

		for(note in unspawnNotesAll)
		{
			var thisStrumline = dadStrumline;
			for(strumline in strumlines)
			{
				if(note.strumlineID == strumline.ID)
					thisStrumline = strumline;
			}

			//var direc = NoteUtil.getDirection(note.noteData);
			var thisStrum = thisStrumline.strumGroup.members[note.noteData];
			var thisChar = thisStrumline.character;

			note.reloadNote(note.songTime, note.noteData, note.noteType, assetModifier);

			note.onHit = function()
			{
				// when the player hits notes
				vocals.volume = 1;
				if(thisStrumline.isPlayer)
				{
					popUpRating(note, false);
				}

				if(!note.isHold)
				{
					var noteDiff:Float = Math.abs(note.songTime - Conductor.songPos);
					if(noteDiff <= Timings.timingsMap.get("sick")[0] || !thisStrumline.isPlayer)
					{
						thisStrumline.playSplash(note);
					}
				}

				// anything else
				note.gotHit = true;
				if(note.holdLength > 0)
					note.gotHold = true;

				if(!note.isHold)
				{
					//note.alpha = 0;
					note.visible = false;
					thisStrum.playAnim("confirm");
				}

				if(thisChar != null && !note.isHold)
				{
					thisChar.playAnim(thisChar.singAnims[note.noteData], true);
					thisChar.holdTimer = 0;

					/*if(note.noteType != 'none')
						thisChar.playAnim('hey');*/
				}
			};
			note.onMiss = function()
			{
				if(thisStrumline.botplay) return;

				vocals.volume = 0;

				note.gotHit = false;
				note.gotHold= false;
				note.canHit = false;
				note.alpha = 0.1;

				var onlyOnce:Bool = false;

				if(!note.isHold)
					onlyOnce = true;

				if(note.isHold && !note.isHoldEnd && note.parentNote.gotHit)
					onlyOnce = true;

				if(onlyOnce)
				{
					if(thisChar != null)
					{
						thisChar.playAnim(thisChar.missAnims[note.noteData], true);
						thisChar.holdTimer = 0;
					}

					// when the player misses notes
					if(thisStrumline.isPlayer)
					{
						popUpRating(note, true);
					}
				}
			};
			// only works on long notes!!
			note.onHold = function()
			{
				vocals.volume = 1;
				note.gotHold = true;

				// if not finished
				if(note.holdHitLength < note.holdLength - Conductor.stepCrochet)
				{
					thisStrum.playAnim("confirm");

					thisChar.playAnim(thisChar.singAnims[note.noteData], true);
					thisChar.holdTimer = 0;
				}
			}

			//if(thisStrumline.isPlayer)
			//{
				thisStrumline.addSplash(note);
			//}

			thisStrumline.unspawnNotes.push(note);
		}

		// Updating Discord Rich Presence
		DiscordClient.changePresence("Playing: " + SONG.song.toUpperCase().replace("-", " "), null);

		startCountdown();
	}

	public var startedSong:Bool = false;

	public function startCountdown()
	{
		var daCount:Int = 0;

		var countTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
		{
			Conductor.songPos = -Conductor.crochet * (4 - daCount);

			if(daCount == 4)
			{
				startSong();
			}

			if(daCount != 4)
			{
				FlxG.sound.play(Paths.sound("beep"));

				var hehe = new gameObjects.menu.Alphabet(0, 0, ["3", "2", "1", "GO"][daCount], true);
				hehe.cameras = [camHUD];
				hehe.screenCenter();
				add(hehe);

				new FlxTimer().start(Conductor.stepCrochet * 3.8 / 1000, function(tmr:FlxTimer)
				{
					hehe.destroy();
				});
			}

			//trace(daCount);

			daCount++;
		}, 5);
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

	public function popUpRating(note:Note, miss:Bool = false)
	{
		var noteDiff:Float = Math.abs(note.songTime - Conductor.songPos);
		if(note.isHold && !miss)
			noteDiff = 0;

		var judge:Float = Timings.diffToJudge(noteDiff);
		if(miss)
			judge = Timings.timingsMap.get('miss')[1];

		// handling stuff
		health += 0.05 * judge;
		Timings.score += Math.floor(100 * judge);
		Timings.addAccuracy(judge);

		if(miss)
		{
			Timings.misses++;
		}
		else
		{
			if(judge <= Timings.timingsMap.get('shit')[1])
			{
				//trace("that was shit");
				note.onMiss();
			}
		}

		hudBuild.updateText();
	}

	// if youre holding a note
	public var isSinging:Bool = false;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		camGame.followLerp = elapsed * 3;

		if(Controls.justPressed("PAUSE"))
		{
			pauseSong();
		}

		if(Controls.justPressed("RESET"))
			health = 0;

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
		Conductor.songPos += elapsed * 1000;

		var pressed:Array<Bool> = [
			Controls.pressed("LEFT"),
			Controls.pressed("DOWN"),
			Controls.pressed("UP"),
			Controls.pressed("RIGHT")
		];
		var justPressed:Array<Bool> = [
			Controls.justPressed("LEFT"),
			Controls.justPressed("DOWN"),
			Controls.justPressed("UP"),
			Controls.justPressed("RIGHT")
		];
		var released:Array<Bool> = [
			Controls.released("LEFT"),
			Controls.released("DOWN"),
			Controls.released("UP"),
			Controls.released("RIGHT")
		];

		isSinging = false;

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
						
						if(strum.animation.curAnim.name == "confirm")
							isSinging = true;
					}
					else
						strum.playAnim("static");
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
				var spawnTime:Float = 1000;

				if(unsNote.songTime - Conductor.songPos <= spawnTime
				&& unsNote.canHit && !unsNote.gotHit && !unsNote.gotHold)
					strumline.addNote(unsNote);
			}
			for(note in strumline.allNotes)
			{
				var despawnTime:Float = 300;

				if(Conductor.songPos >= note.songTime + note.holdLength /*+ Conductor.stepCrochet*/ + despawnTime)
				{
					if(!note.gotHit || !note.gotHold) note.canHit = false;

					strumline.removeNote(note);
				}
			}

			// downscroll
			var downMult:Int = (strumline.downscroll ? -1 : 1);

			for(note in strumline.noteGroup)
			{
				var thisStrum = strumline.strumGroup.members[note.noteData];

				note.x = thisStrum.x + note.noteOffset.x;
				note.y = thisStrum.y + (thisStrum.height / 12 * downMult) + (note.noteOffset.y * downMult);

				/*note.scale.set(
					1 + Math.sin(FlxG.game.ticks / 64) * 0.3,
					1 - Math.sin(FlxG.game.ticks / 64) * 0.3
				);*/
				//note.angle = flixel.math.FlxMath.lerp(note.angle, FlxG.random.int(-360, 360), elapsed * 8);

				note.y += downMult * ((note.songTime - Conductor.songPos) * (strumline.scrollSpeed * 0.45));

				if(Conductor.songPos >= note.songTime + Timings.timingsMap.get("good")[0] && !note.gotHit && note.canHit)
				{
					//trace("too late");
					note.onMiss();
				}

				if(strumline.botplay)
				{
					if(note.songTime - Conductor.songPos <= 0 && !note.gotHit)
						note.onHit();
				}

				// whatever
				if(note.scrollSpeed != strumline.scrollSpeed)
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
							(hold.holdLength - (Conductor.stepCrochet / 2)) * (strumline.scrollSpeed * 0.45)
						];

						hold.setGraphicSize(
							Math.floor(newHoldSize[0]),
							Math.floor(newHoldSize[1])
						);
					}

					hold.updateHitbox();
				}

				hold.flipY = strumline.downscroll;

				if(hold.parentNote != null)
				{
					var thisStrum = strumline.strumGroup.members[hold.noteData];
					var holdParent = hold.parentNote;

					if(!hold.isHoldEnd)
					{
						hold.x = (holdParent.x + holdParent.width / 2 - hold.width / 2) + hold.noteOffset.x;
						hold.y = holdParent.y + holdParent.height / 2;
					}
					else
					{
						hold.x = holdParent.x;
						hold.y = holdParent.y + (strumline.downscroll ? 0 : holdParent.height) + (-downMult * 0.5);
					}

					if(strumline.downscroll)
						hold.y -= hold.height;

					// input!!
					if(!holdParent.canHit && hold.canHit)
						hold.onMiss();

					var pressedCheck:Bool = (pressed[hold.noteData] && holdParent.gotHold && hold.canHit);

					if(!strumline.isPlayer || strumline.botplay)
						pressedCheck = (holdParent.gotHold && hold.canHit);

					if(hold.isHoldEnd)
						pressedCheck = (holdParent.gotHold && holdParent.canHit);

					if(pressedCheck)
					{
						hold.holdHitLength = Conductor.songPos - hold.songTime;
						//trace('${hold.holdHitLength} / ${hold.holdLength}');
						
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

						hold.onHold();
					}

					if(strumline.isPlayer && !strumline.botplay)
					{
						if(released.contains(true))
						{					
							if(released[hold.noteData] && hold.canHit && holdParent.gotHold && !hold.isHoldEnd)
							{
								thisStrum.playAnim("static");

								if(hold.holdHitLength >= hold.holdLength - Conductor.stepCrochet)
									hold.onHit();
								else
									hold.onMiss();
							}
						}
					}
					else
					{
						if(holdParent.gotHold && !hold.isHoldEnd)
						{
							if(hold.holdHitLength >= hold.holdLength - Conductor.stepCrochet)
								hold.onHit();
							else
							{
								hold.onHold();
								//thisStrum.playAnim("confirm");
							}
						}
					}
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

							if(noteDiff <= Timings.minTiming && note.canHit && !note.gotHit && note.noteData == i)
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
								if(note.songTime < canHitNote.songTime)
									canHitNote = note;
							}

							canHitNote.onHit();
						}
						else
						{
							// ghost tapped lol
							if(!SaveData.data.get("Ghost Tapping"))
							{
								vocals.volume = 0;
								var thisChar = strumline.character;
								if(thisChar != null)
								{
									thisChar.playAnim(thisChar.missAnims[i], true);
									thisChar.holdTimer = 0;
								}

								var missJudge:Float = Timings.timingsMap.get("miss")[1];
								health += 0.05 * missJudge;
								Timings.score += Math.floor(100 * missJudge);
								Timings.addAccuracy(missJudge);
								Timings.misses++;
								hudBuild.updateText();
							}
						}
					}
				}
			}

			// dumb stuff!!!
			if(SONG.song.toLowerCase() == "disruption")
			{
				for(strum in strumline.strumGroup)
				{
					var daTime:Float = (FlxG.game.ticks / 1000);

					var strumMult:Int = (strum.strumData % 2 == 0) ? 1 : -1;

					strum.x = strum.initialPos.x + Math.sin(daTime) * 20 * strumMult;
					strum.y = strum.initialPos.y + Math.cos(daTime) * 20 * strumMult;

					strum.scale.x = strum.strumSize + Math.sin(daTime) * 0.4;
					strum.scale.y = strum.strumSize - Math.sin(daTime) * 0.4;

					//strum.x -= strum.scaleOffset.x / 2;
				}
				for(note in strumline.allNotes)
				{
					var thisStrum = strumline.strumGroup.members[note.noteData];

					note.scale.x = thisStrum.scale.x;
					if(!note.isHold)
						note.scale.y = thisStrum.scale.y;
				}
			}
			/*else
			{
				var daPos = (Conductor.songPos);

				while(daPos > Conductor.crochet * 1.5)
				{
					daPos -= Conductor.crochet * 1.5;
				}

				var strumY:Float = strumline.downscroll ? FlxG.height : -NoteUtil.noteWidth();
				if(Conductor.songPos > 0)
					strumY += (daPos * downMult * (strumline.scrollSpeed * 0.45));

				for(strum in strumline.strumGroup)
				{
					strum.y = strumY;
				}
			}*/
		}

		var curSection = PlayState.SONG.notes[Std.int(curStep / 16)];
		if(curSection != null)
		{
			if(curSection.mustHitSection)
				followCamera(boyfriend);
			else
				followCamera(dad);
		}

		if(health <= 0)
		{
			activateTimers(false);
			persistentDraw = false;
			openSubState(new GameOverSubState(boyfriend));
		}

		camGame.zoom = FlxMath.lerp(camGame.zoom, defaultCamZoom, elapsed * 6);
		camHUD.zoom  = FlxMath.lerp(camHUD.zoom,  1.0, elapsed * 6);

		health = FlxMath.bound(health, 0, 2); // bounds the health
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
		hudBuild.beatHit(curBeat);

		if(curBeat % 4 == 0)
		{
			camGame.zoom += 0.05;
			camHUD.zoom += 0.025;
		}
		if(curBeat % 2 == 0)
		{
			for(char in characters)
			{
				var canIdle = (char.holdTimer >= char.holdLength);

				if(char.isPlayer)
				{
					if(isSinging)
						canIdle = false;
				}

				if(canIdle)
					char.dance();
			}
		}
	}

	override function stepHit()
	{
		super.stepHit();
		syncSong();
	}

	public function syncSong(?forced:Bool = false):Void
	{
		if(!startedSong) return;

		for(music in musicList)
		{
			if(music.playing && music.length > 0 && Conductor.songPos < music.length)
			{
				if(Math.abs(Conductor.songPos - music.time) >= 40 || forced)
				{
					// makes everyone sync to the instrumental
					trace("synced song");
					Conductor.songPos = inst.time;
					
					if(music != inst)
					{
						music.time = inst.time;
						music.play();
					}
				}
			}
		}

		checkEndSong();
	}

	public function checkEndSong():Void
	{
		var smallerLength:Float = inst.length;
		for(music in musicList)
		{
			if(music.length < smallerLength)
				smallerLength = music.length;
		}

		if(Conductor.songPos >= smallerLength)
		{
			Main.switchState(new MenuState());
		}
	}

	override public function onFocusLost():Void
	{
		if(!paused) pauseSong();
		super.onFocusLost();
	}

	public function pauseSong()
	{
		paused = true;
		activateTimers(false);
		openSubState(new PauseSubState());
	}
}