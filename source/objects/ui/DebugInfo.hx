package objects.ui;

import backend.song.Conductor;
import flixel.group.FlxGroup;
import flixel.text.FlxText;

using backend.utils.TextUtil;

class DebugInfo extends FlxGroup
{
	public var daText:FlxText;
	
	public function new()
	{
		super();
		
		daText = new FlxText(10, 0, 0, 'test');
		daText.setFormat(Main.globalFont, 18, 0xFFFFFFFF, LEFT);
		daText.setOutline(0xFF000000, 1.5);
		daText.y = FlxG.height - daText.height - 10;
		add(daText);
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}
	
	override function draw()
	{
		var text:String = "SONG TIME: " + (Conductor.songPos / 1000);
		
		if (daText.text != text)
			daText.text = text;
		super.draw();
	}
}