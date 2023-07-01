package;

import data.*;
import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxGame;
import openfl.display.Sprite;

class Main extends Sprite
{
	public function new()
	{
		super();
		
		addChild(new FlxGame(0, 0, Init, 120, 120, true));
	}

	public static var gFont:String = Paths.font("vcr.ttf");//"Nokia Cellphone FC Small";
	
	public static var skipTrans:Bool = true; // starts on but it turns false inside Init
	public static function switchState(target:FlxState):Void
	{
		if(skipTrans)
			return FlxG.switchState(target);
		
		var trans = new GameTransition(false);
		trans.finishCallback = function()
		{
			FlxG.switchState(target);
		}
		FlxG.state.openSubState(trans);
	}
}