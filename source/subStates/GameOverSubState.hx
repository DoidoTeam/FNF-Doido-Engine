package subStates;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import data.GameData.MusicBeatSubState;
import gameObjects.Character;
import states.*;

class GameOverSubState extends MusicBeatSubState
{
	public var bf:Character;
	public var bfFollow:FlxObject;

	public function new(bf:Character)
	{
		super();
		this.bf = bf;
		add(bf);

		if(!bf.animation.exists("firstDeath"))
			bf.reloadChar("bf", bf.isPlayer);

		bf.playAnim("firstDeath");

		bfFollow = new FlxObject(bf.x + bf.width / 2, bf.y + bf.height / 2);

		new FlxTimer().start(0.4, function(tmr:FlxTimer)
		{
			FlxG.camera.follow(bfFollow, LOCKON, FlxG.elapsed * 1);
		});
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if(bf.animation.curAnim.name == "firstDeath"
		&& bf.animation.curAnim.finished)
			bf.playAnim("deathLoop");

		if(!ended)
		{
			if(controls.justPressed("BACK"))
			{
				FlxG.camera.fade(FlxColor.BLACK, 0.2, false, function()
				{
					Main.switchState(new MenuState());
				}, true);
				
			}

			if(controls.justPressed("ACCEPT"))
				endBullshit();
		}
	}

	public var ended:Bool = false;

	public function endBullshit()
	{
		ended = true;
		bf.playAnim("deathConfirm");

		new FlxTimer().start(1.0, function(tmr:FlxTimer)
		{
			FlxG.camera.fade(FlxColor.BLACK, 1.0, false, null, true);

			new FlxTimer().start(2.0, function(tmr:FlxTimer)
			{
				Main.switchState(new PlayState());
			});

		});
	}
}