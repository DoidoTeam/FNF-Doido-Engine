package objects.ui;

import backend.song.Conductor;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import states.PlayState;

using backend.utils.TextUtil;

class DebugInfo extends FlxGroup
{
	public var daText:FlxText;
	public var playState:PlayState;
	
	public function new(playState:PlayState)
	{
		super();
		this.playState = playState;
		
		daText = new FlxText(10, 0, 0, '');
		daText.setFormat(Main.globalFont, 18, 0xFFFFFFFF, LEFT);
		daText.setOutline(0xFF000000, 1.5);
		daText.antialiasing = false;
		add(daText);
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}
	
	override function draw()
	{
		var text:String = "";
		text += "Time: " + Math.floor(Conductor.songPos / 1000 * 100) / 100 + "\n";
		text += "Step: " + Math.floor(playState.curStepFloat * 100) / 100 + "\n";
		text += "Beat: " + Math.floor(playState.curStepFloat / 4 * 100) / 100;
		
		if (daText.text != text) {
			daText.text = text;
			daText.y = FlxG.height - daText.height - 10;
		}
		super.draw();
	}
}