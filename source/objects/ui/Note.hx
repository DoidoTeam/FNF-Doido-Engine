package objects.ui;

import flixel.FlxSprite;
import flixel.math.FlxPoint;

class Note extends FlxSprite
{
	public var stepTime:Float = 0;
	public var noteData:Int = 0;
	
	public var notePath:BasePath = null;
	
	public function new()
	{
		super(-5000, -5000); // offscreen lol
	}
	
	public function loadData(stepTime:Float, noteData:Int)
	{
		path = null;
		this.stepTime = stepTime;
		this.noteData = noteData;
	}
	
	public function reloadSprite()
	{
		loadSparrow("notes/base/notes");
		//animation.addByPrefix();
	}
}