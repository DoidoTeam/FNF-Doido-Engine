package backend.utils;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;

class SpriteUtil
{
	public static function makeColor(spr:FlxSprite, width:Float, height:Float, ?color:FlxColor):FlxSprite
	{
		if (color == null) color = FlxColor.WHITE;
		spr.makeGraphic(1, 1, color);
		spr.antialiasing = false;
		spr.scale.set(width, height);
		spr.updateHitbox();
		return spr;
	}
	
	/*public static function makeGradient(width:Float, height:Float, colors:Array<FlxColor>, chunkSize:UInt = 1, rotation:Int = 90, interpolate:Bool = true):FlxSprite
	{
		if (colors.length == 0) colors = [FlxColor.WHITE];
		if (colors.length == 1) return makeGraphic(width, height, colors[0]);
		
		spr = FlxGradient.createGradientFlxSprite(
			Math.floor(width), Math.floor(height), colors, chunkSize, rotation, interpolate
		);
		return spr;
	}*/
	
	public static function loadImage(spr:FlxSprite, key:String):FlxSprite
	{
		spr.loadGraphic(Assets.image(key));
		return spr;
	}
	
	public static function loadSparrow(spr:FlxSprite, key:String):FlxSprite
	{
		spr.frames = Assets.sparrow(key);
		return spr;
	}
	
	//public static function loadMultiSparrow(spr:FlxSprite, )
	
	public static function spriteCenter(spr:FlxSprite):FlxSprite
	{
		spr.updateHitbox();
		spr.offset.x += spr.frameWidth * spr.scale.x / 2;
		spr.offset.y += spr.frameHeight * spr.scale.y / 2;
		return spr;
	}
}