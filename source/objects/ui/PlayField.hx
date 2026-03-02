package objects.ui;

import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import doido.song.Conductor;
import doido.song.chart.Handler.NoteData;
import doido.song.Timings;
import doido.utils.NoteUtil;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import objects.ui.notes.*;
import doido.mobile.TouchInput;

class PlayField extends FlxGroup
{
	public var spawnNotes:Array<NoteData> = [];
	public var curSpawnNote:Int = 0;
	
	public var strumlines:Array<Strumline> = [];
	public var dadStrumline:Strumline;
	public var bfStrumline:Strumline;
	public var touchInput:TouchInput;
	
	public function new(spawnNotes:Array<NoteData>, speed:Float, downscroll:Bool, middlescroll:Bool)
	{
		super();
		this.spawnNotes = spawnNotes;
		NoteUtil.setUpDirections(4);

		var wide:Bool = false;
		#if TOUCH_CONTROLS
		if(Save.data.modernControls) {
			middlescroll = true;
			downscroll = true;
			wide = true;
		}
		#end

		var strumPos:Array<Float> = [-FlxG.width / 4, FlxG.width / 4];
		if(middlescroll)
			strumPos = [-FlxG.width, 0];
		
		dadStrumline = new Strumline(strumPos[0], downscroll, false, true, false);
		strumlines.push(dadStrumline);

		bfStrumline = new Strumline(strumPos[1], downscroll, true, false, wide);
		strumlines.push(bfStrumline);
		
		for(strumline in strumlines)
		{
			strumline.scrollSpeed = speed;
			add(strumline);
		}

		touchInput = new TouchInput(bfStrumline);
		add(touchInput);
	}

	public var pressed:Array<Bool> 		= [];
	public var justPressed:Array<Bool> 	= [];
	public var released:Array<Bool> 	= [];
	public var curStepFloat:Float = 0.0;
	
	public function updateNotes(curStepFloat:Float)
	{
		this.curStepFloat = curStepFloat;
		pressed = [
			Controls.pressed(LEFT) 		|| touchInput.pressed("left"),
			Controls.pressed(DOWN) 		|| touchInput.pressed("down"),
			Controls.pressed(UP) 		|| touchInput.pressed("up"),
			Controls.pressed(RIGHT) 	|| touchInput.pressed("right"),
		];
		justPressed = [
			Controls.justPressed(LEFT) 	|| touchInput.justPressed("left"),
			Controls.justPressed(DOWN) 	|| touchInput.justPressed("down"),
			Controls.justPressed(UP) 	|| touchInput.justPressed("up"),
			Controls.justPressed(RIGHT) || touchInput.justPressed("right"),
		];
		released = [
			Controls.released(LEFT)  	|| touchInput.released("left"),
			Controls.released(DOWN)  	|| touchInput.released("down"),
			Controls.released(UP) 	 	|| touchInput.released("up"),
			Controls.released(RIGHT) 	|| touchInput.released("right"),
		];

		// spawning notes
		if (curSpawnNote < spawnNotes.length)
		{
			var spawnStep:Float = 32; // spawns notes 32 steps ahead

			for(i in 0...spawnNotes.length)
			{
				if (i < curSpawnNote) continue;

				var noteData = spawnNotes[curSpawnNote];
				if (noteDiffStep(noteData) < spawnStep)
				{
					var strumline = strumlines[noteData.strumline];
					strumline.addNote(noteData);
					curSpawnNote++;
				}
			}
		}

		for(strumline in strumlines)
		{
			// deleting notes
			for (note in strumline.notes)
			{
				if (!note.isHold)
				{
					if (strumline.botplay)
					{
						if (curStepFloat > note.data.stepTime)
						{
							if (!note.gotHit && !note.missed)
								_onNoteHit(note, strumline);
						}
					}
					else if (!note.gotHit && !note.missed && !note.isHold)
					{
						if (noteDiff(note.data) < -Timings.getTiming("good").diff)
							_onNoteMiss(note, strumline);
					}
				}

				var despawnStep:Float = 12; // kills after 12 steps
				if (curStepFloat > note.data.stepTime + note.data.length + despawnStep)
					strumline.killNote(note);
			}

			// updating strums
			for(strum in strumline.strums)
			{
				if (!strumline.isPlayer)
				{
					if (strum.curAnimName == "confirm" && strum.curAnimFinished)
						strum.playAnim("static");
				}
				else
				{
					if (strumline.isPlayer)
					{
						if(pressed[strum.lane])
						{
							if(!["pressed", "confirm"].contains(strum.animation.curAnim.name))
								strum.playAnim("pressed");
						}
						else
							strum.playAnim("static");
						
						/*if(strum.animation.curAnim.name == "confirm")
							playerSinging = true;*/
					}
				}
			}

			// updating notes
			strumline.updateNotes(curStepFloat);

			// updating player inputs
			if (strumline.isPlayer && !strumline.botplay)
			{
				if(justPressed.contains(true))
				{
					for(i in 0...justPressed.length)
					{
						if(justPressed[i])
						{
							var possibleHitNotes:Array<Note> = []; // gets the possible ones
							var canHitNote:Note = null;
							
							for(note in strumline.notes)
							{
								if(note.isHold) continue;
								var noteDiff:Float = noteDiff(note.data);
								
								var minTiming:Float = Timings.minTiming;
								/*if(note.mustMiss)
									minTiming = Timings.getTimings("good")[1];*/
								
								if(noteDiff <= minTiming && !note.missed && !note.gotHit && note.data.lane == i)
								{
									// disables "mustMiss" notes when they are too late to hit
									/*if(note.mustMiss
									&& Conductor.songPos >= note.songTime + Timings.getTimings("sick")[1])
									{
										continue;
									}*/
									
									possibleHitNotes.push(note);
									canHitNote = note;
								}
							}
							
							// if the note actually exists then you got it
							if(canHitNote != null)
							{
								for(note in possibleHitNotes)
								{
									if(note.data.stepTime < canHitNote.data.stepTime)
										canHitNote = note;
								}

								_onNoteHit(canHitNote, strumline);
							}
							else if (onGhostTap != null)
							{
								onGhostTap(i, NoteUtil.directions[i]);
								/*if(startedCountdown)
								{
									if(ghostTapping == "NEVER" || (ghostTapping == "WHILE IDLING" && !isIdling))
									{
										onGhostTap(i, NoteUtil.directions[i]);
									}
								}*/
							}
						}
					}
				}
			}

			for(hold in strumline.notes)
			{
				if (!hold.isHold) continue;
				var holdParent = hold.holdParent;
				if(holdParent != null)
				{
					if (holdParent.gotHit && !holdParent.missed)
					{
						var holdHitLength = (curStepFloat - hold.data.stepTime);
						var holdPercent:Float = Math.min((holdHitLength / hold.data.length), 1.0);

						// hold input
						if (!hold.missed && !hold.gotHit)
						{
							hold.holdHitPercent = holdPercent;

							var isPressing:Bool = false;
							if (strumline.botplay)
								isPressing = true;
							else if (strumline.isPlayer)
								isPressing = pressed[hold.data.lane];

							if (holdPercent >= 1.0)
								isPressing = false;
			
							if(hold.isHoldEnd && isPressing)
								_onNoteHold(hold, strumline);
							
							if(!isPressing)
							{
								if(holdPercent > Timings.getTiming("shit").hold)
									_onNoteHit(hold, strumline);
								else
									_onNoteMiss(hold, strumline);
							}
						}
						
						// calculating the clipping by how much you held the note
						//if (!strumline.pauseNotes)
						if (true)
						{
							var daRect = new FlxRect(
								0, 0,
								hold.frameWidth,
								hold.frameHeight
							);
							
							var rawSize:Float = holdHitLength - hold.holdIndex;
							if (rawSize > 0)
							{
								daRect.y = FlxMath.remapToRange(
									rawSize,
									0.0, hold.holdStep,
									0.0, hold.frameHeight
								);
								if (daRect.y > daRect.height)
									daRect.y = daRect.height;
							}
							
							hold.clipRect = daRect;
						}
					}
					
					if(holdParent.missed && !hold.missed)
						_onNoteMiss(hold, strumline);
				}
			}
		}
	}

	inline public function noteDiffStep(note:NoteData):Float {
		return (note.stepTime - curStepFloat);
	}

	inline public function noteDiff(note:NoteData):Float {
		return noteDiffStep(note) * Conductor.stepCrochet;
	}

	public var onNoteHit:(note:Note, strumline:Strumline)->Void = null;
	private function _onNoteHit(note:Note, strumline:Strumline)
	{
		var strum = strumline.strums[note.data.lane];
		var diff = noteDiff(note.data);

		if (!note.isHold)
		{
			// makes the note transparent if you hit less than good (bad or shit)
			if (diff >= Timings.getTiming("good").diff)
			{
				note.missed = true;
				note.alpha = 0.4;
			}
			else
			{
				note.gotHit = true;
				note.visible = false;
				strum.playAnim("confirm");
			}
		}
		else
		{
			strum.playAnim("confirm");
			note.gotHit = true;
			// turns transparent if you dont hit sick
			if (note.holdHitPercent < Timings.getTiming("sick").hold)
				note.alpha = 0.4;
		}

		if (onNoteHit != null) onNoteHit(note, strumline);
	}

	public var canPlayHoldAnims:Bool = true;
	public var onNoteHold:(note:Note, strumline:Strumline)->Void = null;
	private function _onNoteHold(note:Note, strumline:Strumline)
	{
		var strum = strumline.strums[note.data.lane];

		if (canPlayHoldAnims)
			strum.playAnim("confirm");

		if (onNoteHold != null) onNoteHold(note, strumline);
		canPlayHoldAnims = false;
	}

	public var onNoteMiss:(note:Note, strumline:Strumline)->Void = null;
	private function _onNoteMiss(note:Note, strumline:Strumline)
	{
		note.missed = true;
		//note.visible = false;
		note.alpha = 0.2;

		if (onNoteMiss != null) onNoteMiss(note, strumline);
	}

	public var onGhostTap:(lane:Int, direction:String)->Void;
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}

	public static var modchartAllowed(get, never):Bool;
	public static function get_modchartAllowed():Bool {
		return #if TOUCH_CONTROLS !Save.data.modernControls #else true #end;
	}
}