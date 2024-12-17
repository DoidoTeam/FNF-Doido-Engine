package backend.game;

import flixel.FlxSprite;
import flixel.util.FlxGradient;
import flixel.tweens.FlxTween;
import backend.game.GameData.MusicBeatSubState;

/*
	Transition between states.

	Usage: When changing between states, you can choose which transition will play.
	Main.switchState(new states.menu.MainMenuState(), "base");
*/

class GameTransition extends MusicBeatSubState
{	
	var fadeOut:Bool = false;
	var transition:String = 'funkin';
	
	// Callback at the end of the transition
	public var finishCallback:Void->Void;

	// Sprites used in transitions
	var sprBlack:FlxSprite;
	var sprGrad:FlxSprite;
	
	public function new(fadeOut:Bool = true, transition:String = "funkin")
	{
		super();
		this.fadeOut = fadeOut;
		this.transition = transition;

		switch(transition) {
			case 'funkin':
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
						endTransition();
					}
				});
			default:
				sprBlack = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFF000000);
				sprBlack.screenCenter();
				add(sprBlack);
				
				sprBlack.alpha = (fadeOut ? 1 : 0);
				FlxTween.tween(sprBlack, {alpha: fadeOut ? 0 : 1}, 0.32, {
					onComplete: function(twn:FlxTween)
					{
						endTransition();
					}
				});
		}
	}

	function endTransition()
	{
		if(finishCallback != null)
			finishCallback();
		else
			close();
	}
	
	function updateGradPos():Void {
		sprGrad.y = sprBlack.y + (fadeOut ? -sprGrad.height : sprBlack.height);
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		this.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		switch(transition) {
			case 'funkin':
				updateGradPos();
			default:
				// do nothing
		}
	}
}