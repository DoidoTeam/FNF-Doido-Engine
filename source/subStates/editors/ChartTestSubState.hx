package subStates.editors;

import data.Discord.DiscordClient;
import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.addons.effects.FlxTrail;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.ui.FlxButton;
import flixel.util.FlxTimer;
import data.*;
import data.SongData.SwagSong;
import data.SongData.SwagSection;
import data.chart.*;
import data.GameData.MusicBeatSubState;
import gameObjects.*;
import gameObjects.hud.*;
import gameObjects.hud.note.*;
import gameObjects.Dialogue.DialogueData;
import shaders.*;
import states.PlayState;
import states.editors.ChartingState;
import subStates.*;

using StringTools;

class ChartTestSubState extends MusicBeatSubState
{
	// song stuff
	var SONG:SwagSong;
	var musicList:Array<FlxSound> = [];
	
	public static var startConductor:Float = 0;
	
	var bg:FlxSprite;
	var backGroup:FlxGroup;
	var infoTxt:FlxText;
	var botplayTxt:FlxText;
	
	// strumlines
	var strumlines:FlxTypedGroup<Strumline>;
	var bfStrumline:Strumline;
	var dadStrumline:Strumline;
	
	var unspawnCount:Int = 0;
	var unspawnNotes:Array<Note> = [];
	
	var assetModifier:String = '';
	static var botplay:Bool = false;
	public static var downscroll:Bool = false;

	public static function resetStatics()
	{
		Timings.init();
		SplashNote.resetStatics();
	}
	
	public function exit():Void
	{
		FlxG.state.persistentDraw = true;
		Conductor.songPos = startConductor;
		for(music in musicList)
		{
			music.stop();
			music.time = startConductor;
		}
		
		close();
	}

	var modGrp:ModGroup;

	override function create()
	{
		super.create();
		resetStatics();
		SONG = ChartingState.SONG;
		
		assetModifier = PlayState.assetModifier;
		
		// adjusting the conductor
		Conductor.setBPM(SONG.bpm);
		Conductor.mapBPMChanges(SONG);
		
		Conductor.songPos = startConductor - 820; // 0.82 seconds of delay
		
		FlxG.camera.scroll.y = 0;
		
		add(backGroup = new FlxGroup());
		
		bg = new FlxSprite().loadGraphic(Paths.image('menu/backgrounds/menuDesat'));
		bg.screenCenter();
		bg.color = 0xFF494949;
		backGroup.add(bg);
		
		//bg.scale.set(1.08,1.08);
		//FlxTween.tween(bg.scale, {x: 1, y: 1}, 0.5, {ease: FlxEase.cubeOut});
		
		//hudBuild.cameras = [camHUD];
		//add(hudBuild);
		
		// strumlines
		add(strumlines = new FlxTypedGroup());
		
		//strumline.scrollSpeed = 4.0; // 2.8
		var strumPos:Array<Float> = [FlxG.width / 2, FlxG.width / 4];
		
		dadStrumline = new Strumline(strumPos[0] - strumPos[1], null, downscroll, false, true, assetModifier);
		dadStrumline.ID = 0;
		strumlines.add(dadStrumline);
		
		bfStrumline = new Strumline(strumPos[0] + strumPos[1], null, downscroll, true, false, assetModifier);
		bfStrumline.ID = 1;
		strumlines.add(bfStrumline);
		
		for(strumline in strumlines.members)
		{
			strumline.scrollSpeed = SONG.speed;
			strumline.updateHitbox();
		}
		
		musicList = ChartingState.songList;
		
		//var daSong:String = SONG.song.toLowerCase();

		//Conductor.setBPM(160);
		//Conductor.songPos = -Conductor.crochet * 5;
		
		unspawnNotes = [];
		var checkUnspawnNotes:Array<Note> = ChartLoader.getChart(SONG);
		
		for(note in checkUnspawnNotes)
		{
			if(note.songTime < startConductor - 2) continue;
			
			var thisStrumline = dadStrumline;
			for(strumline in strumlines)
				if(note.strumlineID == strumline.ID)
					thisStrumline = strumline;
			
			var noteAssetMod:String = assetModifier;
			
			note.reloadNote(note.songTime, note.noteData, note.noteType, noteAssetMod);
			
			// oop
			unspawnNotes.push(note);
			thisStrumline.addSplash(note);
		}
		
		add(infoTxt = new FlxText(0, 0, 0, "hi there! i am using whatsapp"));
		infoTxt.setFormat(Main.gFont, 28, 0xFFFFFFFF, CENTER);
		infoTxt.setBorderStyle(OUTLINE, 0xFF000000, 1.5);
		updateInfo();

		add(botplayTxt = new FlxText(0, 0, 0, "[BOTPLAY]"));
		botplayTxt.setFormat(Main.gFont, 32, 0xFFFFFFFF, CENTER);
		botplayTxt.setBorderStyle(OUTLINE, 0xFF000000, 1.5);
		botplayTxt.antialiasing = false;
		botplayTxt.screenCenter();
		botplayTxt.visible = botplay;

		var botplaySin:Float = 0;
		botplayTxt._update = function(elapsed:Float)
		{
			if(botplayTxt.visible)
			{
				botplaySin += elapsed * Math.PI;
				botplayTxt.alpha = 0.5 + Math.sin(botplaySin) * 1.0;
			}
		}

		modGrp = new ModGroup(
			function() {
				downscroll = !downscroll;
				for(strumline in strumlines)
				{
					strumline.downscroll = downscroll;
					strumline.updateHitbox();
					updateInfo();
				}
			},
			function() {
				botplay = !botplay;
				botplayTxt.visible = botplay;
			}
		);
		add(modGrp);
		
		// Updating Discord Rich Presence and making notes invisible before the countdown
		DiscordClient.changePresence("Testing: " + SONG.song.toUpperCase().replace("-", " "), null);
	}
	
	function updateInfo()
	{
		infoTxt.text = 'Accuracy: ${Timings.accuracy}%\n';
		infoTxt.text +='Hits: ${Timings.notesHit - Timings.misses} -- Misses: ${Timings.misses}';
		
		infoTxt.screenCenter(X);
		infoTxt.y = (downscroll ? 15 : FlxG.height - infoTxt.height - 15);
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
		
		// anything else
		note.gotHeld = true;
		note.gotHit = true;
		note.missed = false;
		if(!note.isHold)
			note.visible = false;
		
		if(note.mustMiss) return;

		thisStrum.playAnim("confirm");

		// when the player hits notes
		//vocals.volume = 1;
		if(strumline.isPlayer)
		{
			popUpRating(note, strumline, false);
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
	}
	function onNoteMiss(note:Note, strumline:Strumline)
	{
		var thisStrum = strumline.strumGroup.members[note.noteData];
		
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
			//vocals.volume = 0;
			FlxG.sound.play(Paths.sound('miss/missnote' + FlxG.random.int(1, 3)), 0.55);
			
			// when the player misses notes
			if(strumline.isPlayer)
				popUpRating(note, strumline, true);
		}
	}
	function onNoteHold(note:Note, strumline:Strumline)
	{
		// runs until you hold it enough
		if(note.holdHitLength > note.holdLength) return;
		
		var thisStrum = strumline.strumGroup.members[note.noteData];
		
		//vocals.volume = 1;
		thisStrum.playAnim("confirm", true);
		
		if(note.gotHit) return;
	}
	
	public function popUpRating(note:Note, strumline:Strumline, miss:Bool = false)
	{
		// return;
		var noteDiff:Float = Math.abs(note.songTime - Conductor.songPos);
		if((note.isHold && !miss) || strumline.botplay)
			noteDiff = 0;

		var rating:String = Timings.diffToRating(noteDiff);
		var judge:Float = Timings.diffToJudge(noteDiff);
		if(miss)
		{
			rating = "miss";
			judge = Timings.getTimings("miss")[2];
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
				//note.onMiss();
				// forces a miss anyway
				onNoteMiss(note, strumline);
			}
		}
		
		//hudBuild.updateText();
		var daRating = new Rating(rating, Timings.combo, note.assetModifier);
		daRating.setPos((FlxG.width / 2), FlxG.height / 2);
		backGroup.add(daRating);
		
		updateInfo();
	}
	
	var pressed:Array<Bool> 	= [];
	var justPressed:Array<Bool> = [];
	var released:Array<Bool> 	= [];
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if(FlxG.keys.justPressed.ESCAPE)
			exit();

		bg.scale.set(
			FlxMath.lerp(bg.scale.x, 1.0, elapsed * 8),
			FlxMath.lerp(bg.scale.y, 1.0, elapsed * 8)
		);

		if(FlxG.keys.justPressed.TAB)
			modGrp.isActive = !modGrp.isActive;
		
		//if(startedCountdown)
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
				if(strumline.isPlayer && !strumline.botplay)
				{
					if(pressed[strum.strumData])
					{
						if(!["pressed", "confirm"].contains(strum.animation.curAnim.name))
							strum.playAnim("pressed");
					}
					else
						strum.playAnim("static");
					
					//if(strum.animation.curAnim.name == "confirm")
					//	playerSinging = true;
				}
				else
				{
					// how botplay handles it
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
							if(!SaveData.data.get("Ghost Tapping"))
							{
								//vocals.volume = 0;

								var note = new Note();
								note.reloadNote(0, i, "none", assetModifier);
								onNoteMiss(note, strumline);
							}
						}
					}
				}
			}
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

		if(curBeat % 2 == 0)
			bg.scale.set(1.045,1.045);
	}

	override function stepHit()
	{
		super.stepHit();
		syncSong();
	}

	public function syncSong():Void
	{
		for(music in musicList)
		{
			if(Conductor.songPos < 0) break;
			
			if(Math.abs(music.time - Conductor.songPos) >= 40)
			{
				music.play();
				music.time = Conductor.songPos;
			}
		}
		
		if(Conductor.songPos >= ChartingState.songLength)
			exit();
	}
}

class ModGroup extends FlxGroup
{
	public var bg:FlxSprite;
	public var labelTxt:FlxText;

	public var btnDownscroll:FlxButton;
	public var btnBotplay:FlxButton;

	public var isActive:Bool = false;

	public function new(downscrollClick:Void->Void, botplayClick:Void->Void)
	{
		super();
		bg = new FlxSprite(0, 400).makeGraphic(155, 80, 0xFF000000);
		bg.antialiasing = false;
		bg.alpha = 0.7;
		add(bg);

		labelTxt = new FlxText(0, 0, 0, "TAB");
		labelTxt.setFormat(Main.gFont, 28, 0xFFFFFFFF, CENTER);
		labelTxt.y = bg.y + bg.height / 2 - labelTxt.height / 2;
		labelTxt.antialiasing = false;
		add(labelTxt);

		btnDownscroll = new FlxButton(0, 0, "Downscroll", downscrollClick);
		btnDownscroll.ID = -1;
		btnBotplay = new FlxButton(0, 0, "Botplay", botplayClick);
		btnBotplay.ID = 0;
		add(btnDownscroll);
		add(btnBotplay);

		for(btn in [btnDownscroll, btnBotplay])
			btn.y = bg.y + bg.height / 2 + btn.height * btn.ID;

		updatePos(1);
	}

	public function updatePos(lerpTime:Float = 1)
	{
		bg.x = FlxMath.lerp(bg.x, FlxG.width - (isActive ? bg.width - 8 : 40), lerpTime);
		
		btnDownscroll.x = btnBotplay.x = bg.x + 50;

		labelTxt.angle = 0;
		labelTxt.x = bg.x - 6; // 8
		labelTxt.angle = -90;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		updatePos(elapsed * 8);
	}
}