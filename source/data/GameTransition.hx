package data;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import data.GameData.MusicBeatSubState;

class GameTransition extends MusicBeatSubState
{
	public var blackFade:FlxSprite;
	
	public var finishCallback:Void->Void;
	
	public function new(fadeOut:Bool = true)
	{
		super();
		
		blackFade = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFF000000);
		blackFade.screenCenter();
		add(blackFade);
		
		blackFade.alpha = (fadeOut ? 1 : 0);
		FlxTween.tween(blackFade, {alpha: fadeOut ? 0 : 1}, 0.32, {
			onComplete: function(twn:FlxTween)
			{
				if(finishCallback != null)
					finishCallback();
				else
					close();
			}
		});
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		var lastCam = FlxG.cameras.list[FlxG.cameras.list.length - 1];
		blackFade.cameras = [lastCam];
	}
}