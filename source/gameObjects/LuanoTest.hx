package gameObjects;

import flixel.FlxG;
import flixel.FlxSprite;
import states.PlayState;

class LuanoTest extends FlxSprite
{
	public function new()
	{
		super();
		frames = Paths.getSparrowAtlas("characters/luano-test/luano");

		animation.addByPrefix("idle", "luano idle", 24, true);
		animation.addByPrefix("walkL", "luano walk left", 24, true);
		animation.addByPrefix("walkR", "luano walk right", 24, true);
		animation.addByPrefix("punch", "luano punch", 24, false);

		animation.play("idle");
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		var move:Int = (Controls.pressed("LEFT") ? -1 : Controls.pressed("RIGHT") ? 1 : 0);

		if(Controls.justPressed("ACCEPT"))
			animation.play("punch");

		// animations
		if(animation.curAnim.name != "punch")
		{
			if(move == 0)
				animation.play("idle");
			else
				animation.play("walk" + ((move == -1) ? "L" : "R"));
		}
		else
		{
			if(animation.curAnim.curFrame >= 15)
			{
				PlayState.health -= 16 * elapsed;
			}
		}

		x += 300 * move * elapsed;
	}
}