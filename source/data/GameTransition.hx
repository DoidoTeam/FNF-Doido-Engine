package data;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxGradient;
import flixel.tweens.FlxTween;
import data.GameData.MusicBeatSubState;

class GameTransition extends MusicBeatSubState
{
	var sprBlack:FlxSprite;
	var sprGrad:FlxSprite;
	
	var fadeOut:Bool = false;
	
	public var finishCallback:Void->Void;
	
	public function new(fadeOut:Bool = true)
	{
		super();
		this.fadeOut = fadeOut;
		sprBlack = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFF000000);
		sprBlack.screenCenter(X);
		add(sprBlack);
		
		sprGrad = FlxGradient.createGradientFlxSprite(FlxG.width, Math.floor(FlxG.height / 2), [0xFF000000, 0x00], 1, 90);
		sprGrad.screenCenter(X);
		sprGrad.flipY = fadeOut;
		add(sprGrad);
		
		var yPos:Array<Float> = [
			-sprBlack.height - sprGrad.height - 40,	// upper
			FlxG.height / 2 - sprBlack.height / 2, 	// middle
			FlxG.height + sprGrad.height + 40		// bottom
		];
		var curY:Int = (fadeOut ? 1 : 0);
		
		sprBlack.y = yPos[curY];
		updateGradPos();
		
		FlxTween.tween(sprBlack, {y: yPos[curY + 1]}, fadeOut ? 0.6 : 0.8, {
			onComplete: function(twn:FlxTween)
			{
				if(finishCallback != null)
					finishCallback();
				else
					close();
			}
		});
	}
	
	function updateGradPos():Void
	{
		sprGrad.y = sprBlack.y + (fadeOut ? -sprGrad.height : sprBlack.height);
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		updateGradPos();
		var lastCam = FlxG.cameras.list[FlxG.cameras.list.length - 1];
		for(item in [sprBlack, sprGrad])
			item.cameras = [lastCam];
	}
}

/*
*	old transition
*/
/*class GameTransition extends MusicBeatSubState
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
}*/