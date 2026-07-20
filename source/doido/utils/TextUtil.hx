package doido.utils;

import flixel.text.FlxText;
import flixel.text.FlxBitmapText;
import flixel.util.FlxColor;
import flixel.util.typeLimit.OneOfTwo;

class TextUtil
{
	public static function setOutline(text:OneOfTwo<FlxText, FlxBitmapText>, ?color:FlxColor, thickness:Float = 1.0)
	{
		if (color == null)
			color = FlxColor.BLACK;

		(cast text).borderStyle = OUTLINE;
		(cast text).borderColor = color;
		(cast text).borderSize = thickness;
	}

	public static function floorPos(text:FlxText)
	{
		text.setPosition(Math.floor(text.x), Math.floor(text.y));
	}

	public static function posToTimer(mil:Float = 0):String
	{
		if (mil < 0)
			mil = 0;
		// gets song pos and makes a timer out of it
		var sec:Int = Math.floor(mil / 1000);
		var min:Int = Math.floor(sec / 60);

		function forceZero(shit:String):String
		{
			while (shit.length <= 1)
				shit = '0' + shit;
			return shit;
		}

		var disSec:String = forceZero('${sec % 60}');
		var disMin:String = '$min';
		return '$disMin:$disSec';
	}

	public static function titleCase(str:String):String
	{
		var words = str.split(" ");
		var result = [];
		for (word in words)
			result.push(word.charAt(0).toUpperCase() + word.substr(1).toLowerCase());
		return result.join(" ");
	}
}
