package doido.utils;

import flixel.text.FlxText;
import flixel.util.FlxColor;

class TextUtil
{
	public static function setOutline(text:FlxText, ?color:FlxColor, thickness:Float = 1.0)
	{
		if (color == null) color = FlxColor.BLACK;
		
		text.setBorderStyle(OUTLINE, color, thickness);
	}

	public static function floorPos(text:FlxText)
	{
		text.setPosition(
			Math.floor(text.x),
			Math.floor(text.y)
		);
	}
}