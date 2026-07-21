package doido.objects;

import flixel.FlxCamera;
import openfl.geom.Rectangle;
import flixel.math.FlxRect;
import flixel.math.FlxPoint;
import flixel.math.FlxMath;

class DoidoCamera extends FlxCamera
{
	override public function new(ui:Bool = false, defaultDrawTarget:Bool = false)
	{
		super();
		if (ui)
			bgColor.alpha = 0;
		if (!defaultDrawTarget)
			FlxG.cameras.add(this, false);
		else
		{
			FlxG.cameras.reset(this);
			FlxG.cameras.setDefaultDrawTarget(this, true);
		}
	}

	public function moveCam(targets:Array<DoidoPoint>)
	{
		scroll.set(0, 0);
		for (target in targets)
		{
			scroll.x += target.x;
			scroll.y += target.y;
		}
	}

	override function updateScrollRect():Void
	{
		super.updateScrollRect();
		var rect:Rectangle = (_scrollRect != null) ? _scrollRect.scrollRect : null;

		if (rect != null)
		{
			// angle fix
			var flxRect = FlxRect.get();
			flxRect.copyFromFlash(_scrollRect.scrollRect);
			flxRect.getRotatedBounds(angle, FlxPoint.get(FlxMath.lerp(flxRect.left, flxRect.right, 0.5), FlxMath.lerp(flxRect.top, flxRect.bottom, 0.5)), flxRect);
			_scrollRect.x += flxRect.x - _scrollRect.scrollRect.x;
			_scrollRect.y += flxRect.y - _scrollRect.scrollRect.y;
			_scrollRect.scrollRect = flxRect.copyToFlash();
			flxRect.put();
		}
	}

	override function set_angle(Angle:Float):Float
	{
		super.set_angle(Angle);
		updateScrollRect(); // angle fix
		return Angle;
	}
}
