package objects.ui;

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

			var noteData = spawnNotes[curSpawnNote];
			if (noteDiffStep(noteData) < spawnStep)
			{
				var strumline = strumlines[noteData.strumline];
				strumline.addNote(noteData);
				curSpawnNote++;
			}
		}

		for(strumline in strumlines)
		{
			// deleting notes
			for (note in strumline.notes)
			{
				if (strumline.botplay)
				{
					if (!note.gotHit && noteDiff(note.data) <= 0)
						_onNoteHit(note);
				}
				else if (!note.gotHit && !note.missed)
				{
					if (noteDiff(note.data) < -Timings.getTiming("good").diff)
						_onNoteMiss(note);
				}

				var despawnStep:Float = 12; // kills after 12 steps
				if (curStepFloat > note.data.stepTime + despawnStep)
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
								//if(note.isHold) continue;
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

								_onNoteHit(canHitNote);
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
		}
	}

	inline public function noteDiffStep(note:NoteData):Float {
		return (note.stepTime - curStepFloat);
	}

	inline public function noteDiff(note:NoteData):Float {
		return noteDiffStep(note) * Conductor.stepCrochet;
	}

	public var onNoteHit:(note:Note)->Void = null;
	private function _onNoteHit(note:Note)
	{
		if (onNoteHit != null) onNoteHit(note);

		var strumline = strumlines[note.data.strumline];
		var strum = strumline.strums[note.data.lane];
		var diff = noteDiff(note.data);

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

	public var onNoteMiss:(note:Note)->Void = null;
	private function _onNoteMiss(note:Note)
	{
		if (onNoteMiss != null) onNoteMiss(note);
		note.missed = true;
		//note.visible = false;
		note.alpha = 0.2;
	}

	public var onGhostTap:(lane:Int, direction:String)->Void;
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		#if debug
		for(strumline in strumlines)
		{
			for(strum in strumline.strums)
			{
				if (FlxG.keys.justPressed.NUMPADNINE)
				{
					FlxTween.completeTweensOf(strum);
					var downMult:Int = (strumline.downscroll ? -1 : 1);
					var angle:Float = [13, 5.2, -5.2, -13][strum.lane];
					if (strum.strumAngle == angle) angle = 0;

					FlxTween.tween(
						strum, {
							strumAngle: angle,
							angle: angle * -downMult,
							y: strum.initialPos.y + ((angle == 0) ? 0 : [12, 0, 0, 12][strum.lane]) * downMult,
						},
						0.4, { ease: FlxEase.cubeInOut }
					);
				}
			}
			for(note in strumline.notes)
			{
				note.angle = strumline.strums[note.data.lane].angle;
			}
		}
		#end
	}
}