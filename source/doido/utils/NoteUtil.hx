package doido.utils;

import flixel.FlxSprite;
import flixel.math.FlxAngle;

class NoteUtil
{
	public static var directions:Array<String> = [];
	
	public static function setUpDirections(howMany:Int = 4)
	{
		if (howMany < 1) howMany = 1;
		if (howMany > 9) howMany = 9;
		directions = switch(howMany)
		{
			case 1: ["middle"];
			case 2: ["left", "right"];
			case 3: ["left", "middle", "right"];
			case 4: ["left", "down", "up", "right"];
			case 5: ["left", "down", "middle", "up", "right"];
			case 6: ["left", "down", "right", "left-alt", "up", "right-alt"];
			case 7: ["left", "down", "right", "middle", "left-alt", "up", "right-alt"];
			case 8: ["left", "down", "up", "right", "left-alt", "down-alt", "up-alt", "right-alt"];
			case 9: ["left", "down", "up", "right", "middle", "left-alt", "down-alt", "up-alt", "right-alt"];
			default: ["how???"];
		}
	}
	
	public static function intToString(data:Int):String
		return directions[data];
	
	public static function stringToInt(direction:String):Int
		return directions.indexOf(direction);

	inline public static function noteWidth()
		return 160 * 0.7; // 112

	public static function setNotePos(note:FlxSprite, strum:FlxSprite, angle:Float, offsetX:Float, offsetY:Float)
	{
		var radAngle = FlxAngle.asRadians(angle);
		note.x = strum.x
			+ (Math.cos(radAngle) * offsetX)
			+ (Math.sin(radAngle) * offsetY);
		note.y = strum.y
			+ (Math.cos(radAngle) * offsetY)
			+ (Math.sin(radAngle) * offsetX);
	}
}