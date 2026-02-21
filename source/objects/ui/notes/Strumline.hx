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
	public var hasModchart:Bool = false;

	public var strumlineData:Int = 0;
	
	public var scrollSpeed:Float = 1.0;
	
	public var strums:Array<StrumNote> = [];
	public var notes:Array<Note> = [];
	
	public function new(xOffset:Float, downscroll:Bool = false, isPlayer:Bool = false, botplay:Bool = false)
	{
		super();
		x = (FlxG.width / 2) + xOffset;
		this.downscroll = downscroll;
		this.isPlayer = isPlayer;
		this.botplay = botplay;
		
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
		add(note);
	}
	
	public function killNote(note:Note)
	{
		notes.remove(note);
		note.kill();
	}
	
	public function updateNotes(curStepFloat:Float)
	{
		for(note in notes)
		{
			var strum = strums[note.data.lane];
			var noteSpeed:Float = note.noteSpeed ?? scrollSpeed;

			var offsetX = 0.0; // note.noteOffset.x;
			var offsetY = (note.data.stepTime - curStepFloat) * Conductor.stepCrochet * (noteSpeed * 0.45);
			var angle = 0.0;

			NoteUtil.setNotePos(
				note, strum, angle,
				offsetX, offsetY,
			);
		}
	}
	
	public function recalculateX()
	{
		for (strum in strums)
		{
			strum.x = x;
			strum.x += NoteUtil.noteWidth() * strum.strumData;
			strum.x -= (NoteUtil.noteWidth() * (strums.length - 1)) / 2;
			
			strum.initialPos.x = strum.x;
		}
	}
		
	public function recalculateY()
	{
		for(strum in strums)
		{
			strum.y = (!downscroll ? 110 : FlxG.height - 110);
			strum.initialPos.x = strum.y;
		}
	}
}