package objects.ui.notes;

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
	
	public var scrollSpeed:Float = 1.0;
	
	public var strums:Array<StrumNote> = [];
	public var notes:Array<Note> = [];
	
	public function new(xOffset:Float, downscroll:Bool = false, isPlayer:Bool = false, botplay:Bool = false)
	{
		super();
		x = (FlxG.width / 2) + xOffset;
		this.downscroll = downscroll;
		
		for(i in 0...NoteUtil.directions.length)
		{
			var strum = new StrumNote();
			strum.reloadStrum(i);
			strums.push(strum);
			add(strum);
			
			for(j in 0...4)
				addNote((j * 16) + (i * 4), i);
		}
		
		recalculateX();
		recalculateY();
	}
	
	public function addNote(stepTime:Float, noteData:Int)
	{
		var note:Note = cast recycle(Note);
		note.loadData(stepTime, noteData);
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
			var strum = strums[note.noteData];
			var path = (note.notePath ?? strum.strumPath);
			
			var noteSpeed:Float = note.noteSpeed ?? scrollSpeed;
			var pathPercent:Float = (note.stepTime - curStepFloat) / 16 * noteSpeed;
			
			var pos = path.getPosition(1.0 - pathPercent);
			note.setPosition(pos.x, pos.y);
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
			
			if (!hasModchart)
			{
				strum.strumPath.points = [
					FlxPoint.get(strum.x, downscroll ? -100 : FlxG.height + 100),
					FlxPoint.get(strum.x, strum.y)
				];
				//strum.strumPath.spline = true;
				/*for(_i in 0...2) {
					var i = _i;
					if (i == 0) i = -1;
					strum.strumPath.points.insert(1, 
						FlxPoint.get(
							strum.x + 80 * i,
							FlxG.height / 2 + 100 * i
						)
					);
				}*/
				/*for(_i in 0...2) {
					var i = _i;
					if (i == 0) i = -1;
					strum.strumPath.points.insert(1, 
						FlxPoint.get(
							strum.x + 8 * i,
							strum.y + 200 + (25 * i)
						)
					);
				}*/
			}
		}
	}
}