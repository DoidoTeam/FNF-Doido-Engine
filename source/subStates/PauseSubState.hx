package subStates;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import data.GameData.MusicBeatSubState;
import states.*;

class PauseSubState extends MusicBeatSubState
{
	public var uuh:FlxSprite;

	public function new()
	{
		super();
		var banana = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
		add(banana);

		banana.alpha = 0;
		FlxTween.tween(banana, {alpha: 0.4}, 0.1);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		var lastCam = FlxG.cameras.list[FlxG.cameras.list.length - 1];
		for(item in this.members)
		{
			if(Std.isOfType(item, FlxSprite))
				cast(item, FlxSprite).cameras = [lastCam];
		}

		if(FlxG.keys.justPressed.ENTER)
			close();
	}
}