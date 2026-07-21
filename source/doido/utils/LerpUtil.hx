package doido.utils;

import flixel.tweens.FlxTween;
import flixel.math.FlxMath;

class LerpPoint
{
	public var point:DoidoPoint;
	public var tween:FlxTween;

	var lerped:DoidoPoint;

	public function new()
	{
		point = {x: 0, y: 0};
		lerped = {x: 0, y: 0};
	}

	public function set(point:DoidoPoint)
	{
		clearTween();
		this.point = point;
	}

	public function tweenTo(target:DoidoPoint, duration:Float, ease:String = "linear", modifier:String = "inout")
	{
		clearTween();

		if (duration <= 0)
		{
			point = MathUtil.copyPoint(target);
			lerped = MathUtil.copyPoint(target);
		}
		else
		{
			tween = FlxTween.tween(point, {x: target.x, y: target.y}, duration, {
				ease: TweenUtil.fromString(ease, modifier),
				onComplete: (_) -> tween = null
			});
		}
	}

	public function get(lerp:Float):DoidoPoint
	{
		if (tweening)
			lerp = 1;

		lerped.x = FlxMath.lerp(lerped.x, point.x, lerp);
		lerped.y = FlxMath.lerp(lerped.y, point.y, lerp);
		return lerped;
	}

	public var tweening(get, never):Bool;

	public function get_tweening():Bool
		return tween != null;

	public function clearTween()
	{
		if (!tweening)
			return;

		tween.cancel();
		tween = null;
	}
}
