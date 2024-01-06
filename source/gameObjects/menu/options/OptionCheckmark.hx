package gameObjects.menu.options;

import flixel.FlxG;
import flixel.FlxSprite;

class OptionCheckmark extends FlxSprite
{
	public var value:Bool = false;

	public function new(value:Bool = false, ?size:Float = 1)
	{
		super();
		this.value = value;
		frames = Paths.getSparrowAtlas('menu/checkmark');
		animation.addByPrefix("true", "true", 24, false);
		animation.addByPrefix("false","false",24, false);
		animation.play(Std.string(value), true, false, (value ? 5 : 7));
		scale.set(size, size);
		updateHitbox();
	}

	public function setValue(value:Bool = false)
	{
		this.value = value;
		animation.play(Std.string(value));
	}

	override function updateHitbox()
	{
		super.updateHitbox();
		//offset.x -= 20 * scale.x;
		//offset.y += 22 * scale.y;
		offset.y += 18 * scale.y;
	}
}