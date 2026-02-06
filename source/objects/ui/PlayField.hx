package objects.ui;

import backend.utils.NoteUtil;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import objects.ui.notes.*;

class PlayField extends FlxGroup
{
	/*var testPath:BasePath;
	var testStrum:FlxSprite;
	var testNote:FlxSprite;*/
	
	public var strumlines:Array<Strumline> = [];
	public var dadStrumline:Strumline;
	public var bfStrumline:Strumline;
	
	public function new()
	{
		super();
		NoteUtil.setUpDirections(4);
		
		bfStrumline = new Strumline(FlxG.width / 4, false, true, false);
		strumlines.push(bfStrumline);
		
		dadStrumline = new Strumline(-FlxG.width / 4, false, false, true);
		strumlines.push(dadStrumline);
		
		for(strumline in strumlines)
		{
			add(strumline);
		}
		
		
	}
	
	public function updateNotes(curStepFloat:Float)
	{
		for(strumline in strumlines)
		{
			strumline.updateNotes(curStepFloat);
		}
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		/*if (Controls.pressed(UI_LEFT))
			testPath.percent -= elapsed / 2;
		if (Controls.pressed(UI_RIGHT))
			testPath.percent += elapsed / 2;*/
		/*elapsedtime += elapsed * 2;
		testPath.percent = 0.5 + Math.sin(elapsedtime) * 0.5;
		
		FlxG.mouse.visible = true;
		if (FlxG.mouse.justPressed)
		{
			var dot = new FlxSprite(FlxG.mouse.x, FlxG.mouse.y).makeColor(12, 12, 0xFF00FF00);
			dot.spriteCenter();
			add(dot);
			
			testPath.points.insert(1, FlxPoint.get(dot.x, dot.y));
		}
		
		var pos = testPath.getPosition();
		testNote.setPosition(pos.x, pos.y);
		
		if (Controls.justPressed(ACCEPT))
			Logs.print("PATH PERCENT: " + testPath.percent, WARNING);*/
	}
}