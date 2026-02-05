package objects.ui;

import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;

class Strumline extends FlxGroup
{
	public var strums:Array<StrumNote> = [];
	public function new(xOffset:Float)
	{
		super();
		
		for(i in 0...NoteUtil.directions.length)
		{
			var strum = new StrumNote();
			strum.reloadStrum(i);
			strums.push(strum);
			add(strum);
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
	}
}