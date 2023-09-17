package subStates.editors;

import data.Discord.DiscordClient;
import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import data.*;
import data.SongData.SwagSong;
import data.SongData.SwagSection;
import data.chart.*;
import data.GameData.MusicBeatSubState;
import gameObjects.*;
import gameObjects.hud.*;
import gameObjects.hud.note.*;
import shaders.*;
import states.editors.ChartingState;
import states.PlayState;
import subStates.*;

using StringTools;

class ChartTestSubState extends MusicBeatSubState
{
	// song stuff
	public static var SONG:SwagSong;
	public var inst:FlxSound;
	public var vocals:FlxSound;
	public var musicList:Array<FlxSound> = [];

	public static var songLength:Float = 0;
	
	public static var startConductor:Float = 0;

	// extra stuff
	public static var songDiff:String = "normal";
	public static var assetModifier:String = "base";
	// score, misses, accuracy and other stuff
	// are on the Timings.hx class!!

	// objects
	var backGroup:FlxGroup;
	var bg:FlxSprite;
	var infoTxt:FlxText;
	
	var botplayTxt:FlxText;

	// strumlines
	public var strumlines:FlxTypedGroup<Strumline>;
	public var bfStrumline:Strumline;
	public var dadStrumline:Strumline;

	//var paused:Bool = false;
	var downscroll:Bool = false;
	var botplay:Bool = false;
	
	override public function create()
	{
		super.create();
		Controls.setSoundKeys();
		assetModifier = PlayState.assetModifier;
		Timings.init();
		SONG = ChartingState.SONG;
		//startConductor = Conductor.songPos;
		if(SONG == null)
			SONG = SongData.loadFromJson("ugh");
		
		FlxG.camera.scroll.y = 0;
		
		// preloading stuff
		// Paths.preloadPlayStuff();
		Rating.preload(assetModifier);
		SplashNote.resetStatics();

		// adjusting the conductor
		Conductor.setBPM(SONG.bpm);
		Conductor.mapBPMChanges(SONG);
		
		backGroup = new FlxGroup();
		add(backGroup);

		bg = new FlxSprite().loadGraphic(Paths.image("menu/backgrounds/menuDesat"));
		bg.scrollFactor.set();
		backGroup.add(bg);
		
		bg.color = FlxColor.fromRGB(60,60,60);
		bg.alpha = 0;
		FlxTween.tween(bg, {alpha: 1}, 0.3);
		
		infoTxt = new FlxText(0, 0, 0, "nut");
		infoTxt.setFormat(Main.gFont, 28, 0xFFFFFFFF, CENTER);
		infoTxt.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
		infoTxt.scrollFactor.set();
		backGroup.add(infoTxt);
		updateInfo();
		
		botplayTxt = new FlxText(0, 0, 0, "BOTPLAY");
		botplayTxt.setFormat(Main.gFont, 28, 0xFFFFFFFF, CENTER);
		botplayTxt.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
		botplayTxt.scrollFactor.set();
		botplayTxt.visible = false;
		backGroup.add(botplayTxt);
		
		botplayTxt.screenCenter();
		botplayTxt.x += FlxG.width / 4;
		
		var botSin:Float = 0;
		botplayTxt._update = function(elapsed:Float)
		{
			if(botplayTxt.visible)
			{
				botSin += elapsed * Math.PI;
				botplayTxt.alpha = 0.5 + Math.sin(botSin) * 1.0;
			}
		}
		
		downscroll = SaveData.data.get("Downscroll");
		var downscrollButton = new FlxButton(8, 0, "Downscroll", function() {
			downscroll = !downscroll;
			updateInfo();
			for(strumline in strumlines.members)
			{
				strumline.downscroll = downscroll;
				strumline.updateHitbox();
			}
		});
		downscrollButton.scrollFactor.set();
		add(downscrollButton);
		
		var botplayButton = new FlxButton(8, 0, "Botplay", function() {
			bfStrumline.botplay = !bfStrumline.botplay;
			botplayTxt.visible = bfStrumline.botplay;
		});
		botplayButton.scrollFactor.set();
		add(botplayButton);
		
		for(button in [downscrollButton, botplayButton])
			button.y = FlxG.height - button.height - 8;
		
		downscrollButton.y -= 20 + 4;

		// strumlines
		strumlines = new FlxTypedGroup();
		add(strumlines);

		var strumPos:Array<Float> = [FlxG.width / 2, FlxG.width / 4];
		//var downscroll:Bool = SaveData.data.get("Downscroll");

		dadStrumline = new Strumline(strumPos[0] - strumPos[1], null, downscroll, false, true, assetModifier);
		dadStrumline.ID = 0;
		strumlines.add(dadStrumline);

		bfStrumline = new Strumline(strumPos[0] + strumPos[1], null, downscroll, true, false, assetModifier);
		bfStrumline.ID = 1;
		strumlines.add(bfStrumline);

		/*if(SaveData.data.get("Middlescroll"))
		{
			dadStrumline.x -= strumPos[0]; // goes offscreen
			bfStrumline.x  -= strumPos[1]; // goes to the middle
		}*/

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
		//Conductor.songPos = -Conductor.crochet * 5;

		var unspawnNotesAll:Array<Note> = ChartLoader.getChart(SONG);

		for(note in unspawnNotesAll)
		{
			if(note.songTime < startConductor - 1) continue;
			
			var thisStrumline = dadStrumline;
			for(strumline in strumlines)
			{
				if(note.strumlineID == strumline.ID)
					thisStrumline = strumline;
			}

			var noteAssetMod:String = assetModifier;

			note.reloadNote(note.songTime, note.noteData, note.noteType, noteAssetMod);

			thisStrumline.addSplash(note);

			thisStrumline.unspawnNotes.push(note);
		}

		// Updating Discord Rich Presence
		DiscordClient.changePresence("Testing Chart: " + SONG.song.toUpperCase().replace("-", " "), null);
		
		Conductor.songPos -= Conductor.crochet * 4;
	}
	
	public function updateInfo()
	{
		infoTxt.text = "";

		//infoTxt.text += 'Step: ${curStep} // Beat: ${curBeat}\n';
		infoTxt.text += 'Notes Hit: ${Timings.notesHit - Timings.misses}    Misses: ${Timings.misses}\n';
		infoTxt.text += 'Accuracy: ${Timings.accuracy}% [${Timings.getRank()}]';

		infoTxt.screenCenter(X);
		if(downscroll)
			infoTxt.y = 15;
		else
			infoTxt.y = FlxG.height - infoTxt.height - 15;
	}

	public var playingSong:Bool = true;

	// checks
	public function checkNoteHit(note:Note, strumline:Strumline)
	{
		if(!note.mustMiss)
			onNoteHit(note, strumline);
		else
			onNoteMiss(note, strumline);
	}

	// actual functions
	function onNoteHit(note:Note, strumline:Strumline)
	{
		var thisStrum = strumline.strumGroup.members[note.noteData];
		
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

		if(!note.isHold)
		{
			var noteDiff:Float = Math.abs(note.songTime - Conductor.songPos);
			if(noteDiff <= Timings.timingsMap.get("sick")[0] || strumline.botplay)
			{
				strumline.playSplash(note);
			}
		}
	}
	function onNoteMiss(note:Note, strumline:Strumline)
	{
		if(strumline.botplay) return;

		var thisStrum = strumline.strumGroup.members[note.noteData];

		note.gotHit = false;
		note.missed = true;
		note.setAlpha();

		// put stuff inside onlyOnce
		var onlyOnce:Bool = false;
		if(!note.isHold)
			onlyOnce = true;
		else
		{
			if(note.isHoldEnd && note.holdHitLength > 0)
				onlyOnce = true;
		}

		if(onlyOnce)
		{
			vocals.volume = 0;

			FlxG.sound.play(Paths.sound('miss/missnote' + FlxG.random.int(1, 3)), 0.55);

			// when the player misses notes
			if(strumline.isPlayer)
				popUpRating(note, strumline, true);
		}
	}
	function onNoteHold(note:Note, strumline:Strumline)
	{
		// runs until you hold it enough
		if(note.gotHit) return;
		
		var thisStrum = strumline.strumGroup.members[note.noteData];
		
		vocals.volume = 1;
		thisStrum.playAnim("confirm");
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
				// forces a miss anyway
				onNoteMiss(note, strumline);
			}
		}

		var daRating = new Rating(rating, Timings.combo, note.assetModifier);
		
		var daX:Float = (FlxG.width / 2) - 64;
		/*if(SaveData.data.get("Middlescroll"))
			daX -= FlxG.width / 4;*/

		daRating.setPos(daX, FlxG.height / 2);
		backGroup.add(daRating);
		
		// update the text stuff
		updateInfo();
	}
	
	var pressed:Array<Bool> 	= [];
	var justPressed:Array<Bool> = [];
	var released:Array<Bool> 	= [];
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if(Controls.justPressed("PAUSE"))
			playingSong = !playingSong;
		
		if((Controls.pressed("UI_LEFT") || Controls.pressed("UI_RIGHT")) && !playingSong)
		{
			Conductor.songPos += elapsed * 1000 * (Controls.pressed("UI_LEFT") ? -1 : 1) * (FlxG.keys.pressed.SHIFT ? 4 : 1);
			
			//resetNote();
			for(strumline in strumlines)
				for(unsNote in strumline.unspawnNotes)
					if(unsNote.songTime >= Conductor.songPos && (unsNote.missed || unsNote.gotHeld || unsNote.gotHit))
						unsNote.resetNote();
		}
		
		if(playingSong)
			Conductor.songPos += elapsed * 1000;
		if(Conductor.songPos >= songLength || Controls.justPressed("RESET"))
		{
			Timings.init();
			updateInfo();
			Conductor.songPos = startConductor - Conductor.crochet * 4;
			for(music in musicList)
				music.time = Conductor.songPos;
			
			for(strumline in strumlines)
				for(unsNote in strumline.unspawnNotes)
					unsNote.resetNote();
		}
		
		for(music in musicList)
		{
			if(Conductor.songPos >= 0 && playingSong)
			{
				if(!music.playing)
				{
					music.stop();
					music.play(Conductor.songPos);
				}
			}
			else if(music.playing)
				music.stop();
		}
		
		if(FlxG.keys.justPressed.ESCAPE)
		{
			playingSong = false;
			for(music in musicList)
				music.stop();
			Conductor.songPos = startConductor;
			Controls.setSoundKeys(true);
			close();
		}

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
				var spawnTime:Int = 1000;
				if(strumline.scrollSpeed <= 1.5)
					spawnTime = 5000;

				if(unsNote.songTime - Conductor.songPos <= spawnTime && !unsNote.spawned)
				{
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

				note.x = thisStrum.x + note.noteOffset.x;
				note.y = thisStrum.y + (thisStrum.height / 12 * downMult) + (note.noteOffset.y * downMult);
				
				// adjusting
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
					
					if(SaveData.data.get("Split Holds"))
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
								if(note.mustMiss && note.songTime < Conductor.songPos - Timings.timingsMap.get("sick")[0])
									continue;

								if(note.songTime < canHitNote.songTime)
									canHitNote = note;
							}

							checkNoteHit(canHitNote, strumline);
						}
						else
						{
							// you ghost tapped lol
							if(!SaveData.data.get("Ghost Tapping"))
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
		}
		
		var lastSteps:Int = 0;
		var curSection = SONG.notes[0];
		for(section in SONG.notes)
		{
			if(curStep >= lastSteps)
				curSection = section;

			lastSteps += section.lengthInSteps;
		}
		/*if(curSection != null)
		{
			// what
		}*/
	}
	
	override function beatHit()
	{
		super.beatHit();
		for(change in Conductor.bpmChangeMap)
		{
			if(curStep >= change.stepTime && Conductor.bpm != change.bpm)
				Conductor.setBPM(change.bpm);
		}
		
		// updates in case it missed something
		if(curBeat % 4 == 0)
			updateInfo();
	}

	override function stepHit()
	{
		super.stepHit();
		syncSong();
	}

	public function syncSong(?forced:Bool = false):Void
	{
		if(!playingSong) return;

		for(music in musicList)
		{
			if(music.playing && Conductor.songPos < music.length)
			{
				if(Math.abs(Conductor.songPos - music.time) >= 40 || forced)
				{
					// makes everyone sync to the instrumental
					//trace("synced song");
					music.time = Conductor.songPos;
				}
			}
		}

		checkEndSong();
	}
	
	// checks if the song is allowed to end
	public function checkEndSong():Void
	{
		if(Conductor.songPos >= songLength)
			Conductor.songPos = startConductor;
	}
}