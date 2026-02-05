package objects.ui.notes;

import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;

class Strumline extends FlxGroup
{
	public var x:Float = 0;
	public var downscroll:Bool = false;
	
	public var strums:Array<StrumNote> = [];
	public var notes:Array<Note> = [];
	
	public var hasModchart:Bool = false;
	
	public function new(xOffset:Float, downscroll:Bool = false)
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
			
			addNote(i * 2, i);
		}
		
		/*testStrum = new FlxSprite(FlxG.width / 2, 80).makeColor(64, 64, 0xFFFFFFFF);
		testStrum.spriteCenter();
		add(testStrum);*/
		
		/*testNote = new FlxSprite(FlxG.width / 2, FlxG.height - 80).makeColor(64, 64, 0xFFFF0000);
		testNote.spriteCenter();
		add(testNote);
		
		testPath = new BasePath([
			FlxPoint.get(FlxG.width / 2, FlxG.height + 80), // começo
			
			FlxPoint.get(FlxG.width / 2 + 400, FlxG.height / 2),
			//FlxPoint.get(FlxG.width / 2, FlxG.height / 2),
			FlxPoint.get(FlxG.width / 2 - 400, FlxG.height / 2),
			
			FlxPoint.get(testStrum.x, testStrum.y), // fim
		]);*/
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
	
	public function updateNotes()
	{
		for(note in notes)
		{
			var strum = strums[note.noteData];
			var path = note.notePath ?? strum.strumPath;
			
			var pathPercent:Float = 0.5;
			var pos = path.getPosition(pathPercent);
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
			}
		}
	}
}