package objects.ui.notes;

import doido.song.Conductor;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;

class Strumline extends FlxGroup
{
	public var x:Float = 0;
	public var downscroll:Bool = false;
	public var isPlayer:Bool = false;
	public var botplay:Bool = false;
	public var wide:Bool = false;
	public var hasModchart:Bool = false;

	public var strumlineData:Int = 0;
	
	public var scrollSpeed:Float = 1.0;
	
	public var strums:Array<StrumNote> = [];
	public var notes:Array<Note> = [];
	
	public function new(xOffset:Float, downscroll:Bool = false, isPlayer:Bool = false, botplay:Bool = false, wide:Bool = false)
	{
		super();
		x = (FlxG.width / 2) + xOffset;
		this.downscroll = downscroll;
		this.isPlayer = isPlayer;
		this.botplay = botplay;
		this.wide = wide;
		
		for(i in 0...NoteUtil.directions.length)
		{
			var strum = new StrumNote();
			strum.reloadStrum(i);
			strums.push(strum);
			add(strum);
		}

		recalculateX();
		recalculateY();
	}
	
	public function addNote(noteData:NoteData)
	{
		var note:Note = cast recycle(Note);
		note.loadData(noteData);
		note.reloadSprite();
		notes.push(note);
		
		// searchs for hold notes
		if(noteData.length > 0)
		{
			var holdLength:Int = Math.ceil(noteData.length + 1);

			var endDiff:Float = noteData.length - Math.floor(noteData.length);
			if (endDiff <= 0.0) endDiff = 1.0; // oh well
			
			var holdIndex:Float = 0.0;
			for(i in 0...holdLength)
			{
				var hold:Note = cast recycle(Note);
				hold.loadData(noteData);

				hold.isHold = true;
				hold.isHoldEnd = (i == holdLength - 1);
				hold.holdStep = (i == holdLength - 2 ? endDiff : 1.0);
				hold.holdIndex = holdIndex;
				note.children.push(hold);

				hold.reloadSprite();
				hold.holdParent = note;
				notes.push(hold);
				if (!members.contains(hold)) add(hold);

				holdIndex += hold.holdStep;
			}
		}

		// adds regular note in front of hold notes
		if (!members.contains(note)) add(note);
		//members.sort(NoteUtil.sortLayer);
	}
	
	public function killNote(note:Note)
	{
		notes.remove(note);
		note.kill();
	}
	
	public function updateNotes(curStepFloat:Float)
	{
		var downMult:Int = (downscroll ? -1 : 1);

		for(note in notes)
		{
			var strum = strums[note.data.lane];
			var noteSpeed:Float = note.noteSpeed ?? scrollSpeed;
			noteSpeed *= note.noteSpeedMult;

			var noteTime:Float = (note.data.stepTime - curStepFloat);
			if (note.isHold)
				noteTime += note.holdIndex;

			var offsetX = 0.0; // note.noteOffset.x;
			var offsetY = (noteTime) * Conductor.stepCrochet * (noteSpeed * 0.45);
			var angle = note.noteAngle ?? strum.strumAngle;

			if (downscroll) angle += 180;

			if (note.isHold)
			{
				note.angle = -angle * downMult;
				if (!note.isHoldEnd)
				{
					var holdHeight:Float = Conductor.stepCrochet * (noteSpeed * 0.45) + 2;
					note.scale.y = (holdHeight / note.frameHeight);
					note.updateHitbox();
				}
			}

			note.updateOffsets();
			NoteUtil.setNotePos(
				note, strum, angle * downMult,
				offsetX, offsetY
			);
		}
	}
	
	public function recalculateX()
	{
		for (strum in strums)
		{
			strum.x = x;
			strum.x += NoteUtil.noteWidth(wide) * strum.lane;
			strum.x -= (NoteUtil.noteWidth(wide) * (strums.length - 1)) / 2;
			if(wide) strum.x += (strum.lane < (NoteUtil.directions.length/2) ? -100 : 100);
			
			strum.initialPos.x = strum.x;
		}
	}
		
	public function recalculateY()
	{
		for(strum in strums)
		{
			strum.y = (!downscroll ? 110 : FlxG.height - 110);
			strum.initialPos.y = strum.y;
		}
	}
}