package objects.ui;

import doido.song.Conductor;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import states.PlayState;

using doido.utils.TextUtil;

class DebugInfo extends FlxGroup
{
	public var daText:FlxText;
	public var playState:PlayState;
	
	public function new(playState:PlayState)
	{
		super();
		this.playState = playState;
		visible = false;
		
		daText = new FlxText(10, 0, 0, '');
		daText.setFormat(Main.globalFont, 18, 0xFFFFFFFF, LEFT);
		daText.setOutline(0xFF000000, 1.5);
		daText.antialiasing = false;
		add(daText);
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (FlxG.keys.justPressed.F1) visible = !visible;
	}
	
	override function draw()
	{
		if (visible)
		{
			var text:String = "";
			text += "Time: " + Math.floor(Conductor.songPos / 1000 * 100) / 100;
			text += "\nStep: " + Math.floor(playState.curStepFloat * 100) / 100;
			text += "\nBeat: " + Math.floor(playState.curStepFloat / 4 * 100) / 100;
			
			if (daText.text != text) {
				daText.text = text;
				daText.y = FlxG.height - daText.height - 10;
			}
		}
		//daText.screenCenter(X);
		super.draw();
	}
}