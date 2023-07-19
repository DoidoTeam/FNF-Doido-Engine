package states.editors;

import data.Discord.DiscordClient;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import data.*;
import data.SongData.SwagSong;
import data.SongData.SwagSection;
import data.chart.*;
import data.GameData.MusicBeatState;
import gameObjects.*;
import gameObjects.hud.*;
import gameObjects.hud.note.*;
import subStates.*;

using StringTools;

class ChartTestState extends MusicBeatState
{
	// song stuff
	public static var SONG:SwagSong;
	public var inst:FlxSound;
	public var vocals:FlxSound;
	public var musicList:Array<FlxSound> = [];

	// 
	public static var assetModifier:String = "base";

	var behindGroup:FlxGroup;
	var infoTxt:FlxText;

	// strumlines
	public var strumlines:FlxTypedGroup<Strumline>;
	public var bfStrumline:Strumline;
	public var dadStrumline:Strumline;

	public static var startConductor:Float = 0;

	function resetStatics()
	{
		assetModifier = PlayState.assetModifier;
		Timings.init();
	}

	override public function create()
	{
		super.create();
		CoolUtil.playMusic();
		resetStatics();
		if(SONG == null)
			SONG = SongData.loadFromJson("ugh");

		// preloading stuff
		Paths.preloadPlayStuff();
		Rating.preload(assetModifier);
		SplashNote.resetStatics();

		// adjusting the conductor
		Conductor.setBPM(SONG.bpm);
		Conductor.mapBPMChanges(SONG);

		Conductor.songPos = startConductor;

		behindGroup = new FlxGroup();
		add(behindGroup);

		var bg = new FlxSprite().loadGraphic(Paths.image("menu/backgrounds/menuDesat"));
		bg.screenCenter();
		bg.scrollFactor.set();
		bg.alpha = 0.35; // 0.4
		behindGroup.add(bg);

		// color thingy
		/*var bgColors:Array<FlxColor> = [
			0xFF70e663,
			0xFF6390e6,
			0xFF7f63e6,
			0xFFc063e6,
			0xFFe6a063,
			0xFFf77cb7,
			0xFFb8b8b8,
			0xFF716b78,
		];
		bg.color = bgColors[FlxG.random.int(0, bgColors.length - 1)];*/

		infoTxt = new FlxText(0, 0, 0, "nut");
		infoTxt.setFormat(Main.gFont, 28, 0xFFFFFFFF, CENTER);
		infoTxt.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
		behindGroup.add(infoTxt);

		updateInfo();

		// strumlines
		strumlines = new FlxTypedGroup();
		add(strumlines);

		//strumline.scrollSpeed = 4.0; // 2.8
		var strumPos:Array<Float> = [FlxG.width / 2, FlxG.width / 4];
		var downscroll:Bool = SaveData.data.get("Downscroll");

		dadStrumline = new Strumline(strumPos[0] - strumPos[1], null, downscroll, false, true, assetModifier);
		dadStrumline.ID = 0;
		strumlines.add(dadStrumline);

		bfStrumline = new Strumline(strumPos[0] + strumPos[1], null, downscroll, true, false, assetModifier);
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

		var daSong:String = SONG.song.toLowerCase();

		inst = new FlxSound();
		inst.loadEmbedded(Paths.inst(daSong), false, false);

		vocals = new FlxSound();
		if(SONG.needsVoices)
		{
			vocals.loadEmbedded(Paths.vocals(daSong), false, false);
		}

		function addMusic(music:FlxSound):Void
		{
			FlxG.sound.list.add(music);
			
			if(music.length > 0)
				musicList.push(music);

			music.play();
			music.stop();
		}

		addMusic(inst);
		addMusic(vocals);

		var unspawnNotesAll:Array<Note> = ChartLoader.getChart(SONG);

		for(note in unspawnNotesAll)
		{
			// youre too late, you dont get to spawn
			if(note.songTime < Conductor.songPos - Conductor.stepCrochet)
				continue;

			var thisStrumline = dadStrumline;
			for(strumline in strumlines)
			{
				if(note.strumlineID == strumline.ID)
					thisStrumline = strumline;
			}

			//var direc = NoteUtil.getDirection(note.noteData);
			var thisStrum = thisStrumline.strumGroup.members[note.noteData];

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
					if(noteDiff <= Timings.timingsMap.get("sick")[0] || thisStrumline.botplay)
					{
						thisStrumline.playSplash(note);
					}
				}

				// anything else
				note.isPressing = false;
				note.gotHit = true;
				if(note.holdLength > 0)
					note.gotHold = true;

				if(!note.isHold)
				{
					//note.alpha = 0;
					note.visible = false;
					thisStrum.playAnim("confirm");
				}
			};
			note.onMiss = function()
			{
				if(thisStrumline.botplay) return;

				note.gotHit = false;
				note.gotHold= false;
				note.canHit = false;
				note.isPressing = false;
				note.alpha = 0.15;

				// put global stuff inside onlyOnce
				var onlyOnce:Bool = false;

				if(!note.isHold)
					onlyOnce = true;
				else
				{
					if(!note.isHoldEnd && note.parentNote.gotHit)
						onlyOnce = true;
				}

				if(onlyOnce)
				{
					vocals.volume = 0;

					FlxG.sound.play(Paths.sound('miss/missnote' + FlxG.random.int(1, 3)), 0.55);

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
					thisStrum.playAnim("confirm");
			}

			thisStrumline.addSplash(note);

			thisStrumline.unspawnNotes.push(note);
		}

		// Updating Discord Rich Presence
		DiscordClient.changePresence("Playing: " + SONG.song.toUpperCase().replace("-", " "), null);
		startSong();
	}

	public function startSong()
	{
		// giving you some space
		Conductor.songPos -= (Conductor.crochet * 2);

		syncSong(true);
	}

	public function popUpRating(note:Note, miss:Bool = false)
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
				note.onMiss();
			}
		}

		updateInfo();

		var daRating = new Rating(rating, Timings.combo, note.assetModifier);
		behindGroup.add(daRating);

		var daX:Float = (FlxG.width / 2) - 64;
		if(SaveData.data.get("Middlescroll"))
			daX -= FlxG.width / 4;

		daRating.setPos(daX, FlxG.height / 2);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		if(FlxG.keys.justPressed.ESCAPE)
		{
			for(song in musicList)
				song.stop();

			Conductor.songPos = startConductor;
			Main.switchState(new ChartingState());
		}
		if(FlxG.keys.justPressed.R)
			checkEndSong(true);

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

				if(Conductor.songPos >= note.songTime + note.holdLength + Conductor.stepCrochet + despawnTime)
				{
					if(!note.gotHit && !note.gotHold && note.canHit)
						note.onMiss();

					if(!note.isPressing)
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

				note.y += downMult * ((note.songTime - Conductor.songPos) * (strumline.scrollSpeed * 0.45));

				if(Conductor.songPos >= note.songTime + Timings.timingsMap.get("good")[0]
				&& !note.gotHit && note.canHit)
				{
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

						hold.isPressing = true;
						
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

								var note = new Note();
								note.reloadNote(0,0,"none",assetModifier);
								FlxG.sound.play(Paths.sound('miss/missnote' + FlxG.random.int(1, 3)), 0.55);
								popUpRating(note, true);
							}
						}
					}
				}
			}
		}

		var lastSteps:Int = 0;
		var curSection:SwagSection = null;
		for(section in SONG.notes)
		{
			if(curStep >= lastSteps)
				curSection = section;

			lastSteps += section.lengthInSteps;
		}
	}

	override function beatHit()
	{
		super.beatHit();
		for(change in Conductor.bpmChangeMap)
		{
			if(curStep >= change.stepTime && Conductor.bpm != change.bpm)
				Conductor.setBPM(change.bpm);
		}
	}

	override function stepHit()
	{
		super.stepHit();
		//updateInfo();
		syncSong();
	}

	public function updateInfo()
	{
		infoTxt.text = "";

		//infoTxt.text += 'Step: ${curStep} // Beat: ${curBeat}\n';
		infoTxt.text += 'Notes Hit: ${Timings.notesHit - Timings.misses}    Misses: ${Timings.misses}\n';
		infoTxt.text += 'Accuracy: ${Timings.accuracy}% [${Timings.getRank()}]';

		infoTxt.screenCenter(X);
		if(SaveData.data.get("Downscroll"))
			infoTxt.y = 15;
		else
			infoTxt.y = FlxG.height - infoTxt.height - 15;
	}

	public function syncSong(?forced:Bool = false):Void
	{
		for(music in musicList)
		{
			if(Conductor.songPos < 0) break;

			if(!music.playing)
				music.play(Conductor.songPos);

			if(Conductor.songPos < music.length)
			{
				if(Math.abs(Conductor.songPos - music.time) >= 40 || forced)
					music.time = Conductor.songPos;
			}
		}

		checkEndSong();
	}

	public function checkEndSong(?forced:Bool = false):Void
	{
		var smallerLength:Float = inst.length;
		for(music in musicList)
		{
			if(music.length < smallerLength)
				smallerLength = music.length;
		}

		// works like endSong() if forced
		if(Conductor.songPos >= smallerLength || forced)
		{
			Main.skipClearMemory = true;
			Main.switchState();
		}
	}
}