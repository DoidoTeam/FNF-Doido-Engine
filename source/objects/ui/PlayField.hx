package objects.ui;

import doido.song.Conductor;
import doido.song.chart.Handler.NoteData;
import doido.song.Timings;
import doido.utils.NoteUtil;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import objects.ui.notes.*;
import doido.mobile.Hitbox;

class PlayField extends FlxGroup
{
	public var spawnNotes:Array<NoteData> = [];
	public var curSpawnNote:Int = 0;
	
	public var strumlines:Array<Strumline> = [];
	public var dadStrumline:Strumline;
	public var bfStrumline:Strumline;
	public var hitbox:Hitbox;
	
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

		hitbox = new Hitbox(bfStrumline);
		add(hitbox);
	}

	public var pressed:Array<Bool> 		= [];
	public var justPressed:Array<Bool> 	= [];
	public var released:Array<Bool> 	= [];
	public var curStepFloat:Float = 0.0;
	
	public function updateNotes(curStepFloat:Float)
	{
		this.curStepFloat = curStepFloat;
		pressed = [
			Controls.pressed(LEFT) 	|| hitbox.pressed("left"),
			Controls.pressed(DOWN) 	|| hitbox.pressed("down"),
			Controls.pressed(UP) 	|| hitbox.pressed("up"),
			Controls.pressed(RIGHT) || hitbox.pressed("right"),
		];
		justPressed = [
			Controls.justPressed(LEFT) 	|| hitbox.justPressed("left"),
			Controls.justPressed(DOWN) 	|| hitbox.justPressed("down"),
			Controls.justPressed(UP) 	|| hitbox.justPressed("up"),
			Controls.justPressed(RIGHT) || hitbox.justPressed("right"),
		];
		released = [
			Controls.released(LEFT)  || hitbox.released("left"),
			Controls.released(DOWN)  || hitbox.released("down"),
			Controls.released(UP) 	 || hitbox.released("up"),
			Controls.released(RIGHT) || hitbox.released("right"),
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
						if(pressed[strum.strumData])
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
							}
							/*else if (i < 4) // you ghost tapped lol
							{
								if(startedCountdown)
								{
									if(ghostTapping == "NEVER" || (ghostTapping == "WHILE IDLING" && !isIdling))
									{
										// i don't think vocals should stop when ghost tapping
										// vocals.volume = 0;

										var note = new Note();
										note.updateData(0, i, "none", assetModifier);
										//note.reloadSprite();
										_onNoteMiss(note, strumline, true);
									}
								}
							}*/
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
	}
}