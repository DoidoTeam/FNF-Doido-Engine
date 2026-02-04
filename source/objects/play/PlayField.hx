package objects.play;

import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import backend.game.SplinePath;

class PlayField extends FlxTypedGroup<FlxSprite>
{
	var testPath:SplinePath;
	var testStrum:FlxSprite;
	var testNote:FlxSprite;
	
	public function new()
	{
		super();
		testStrum = new FlxSprite(FlxG.width / 2, 80).makeColor(64, 64, 0xFFFFFFFF);
		testStrum.spriteCenter();
		add(testStrum);
		
		testNote = new FlxSprite(FlxG.width / 2, FlxG.height - 80).makeColor(64, 64, 0xFFFF0000);
		testNote.spriteCenter();
		add(testNote);
		
		testPath = new SplinePath([
			FlxPoint.get(FlxG.width / 2, FlxG.height + 80), // começo
			
			FlxPoint.get(FlxG.width / 2 + 400, FlxG.height / 2),
			//FlxPoint.get(FlxG.width / 2, FlxG.height / 2),
			FlxPoint.get(FlxG.width / 2 - 400, FlxG.height / 2),
			
			FlxPoint.get(testStrum.x, testStrum.y), // fim
		]);
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (Controls.pressed(UI_LEFT))
			testPath.percent -= elapsed / 2;
		if (Controls.pressed(UI_RIGHT))
			testPath.percent += elapsed / 2;
		
		var pos = testPath.getPosition();
		testNote.setPosition(pos.x, pos.y);
		
		if (Controls.justPressed(ACCEPT))
			Logs.print("PATH PERCENT: " + testPath.percent, WARNING);
	}
}