package;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.display.BitmapData;
import lime.utils.Assets;
import sys.FileSystem;
import sys.io.File;

class Paths
{
	public static var renderedGraphics:Map<String, FlxGraphic> = [];
	
	public static function returnGraphic(key:String)
	{
		var path = 'assets/images/$key.png';
		if(FileSystem.exists(path))
		{
			if(!renderedGraphics.exists(path))
			{
				var bitmap = BitmapData.fromFile(path);
				var newGraphic:FlxGraphic;
				
				newGraphic = FlxGraphic.fromBitmapData(bitmap, false, key, false);
				trace('created new image $key');
				
				renderedGraphics.set(path, newGraphic);
			}
			
			return renderedGraphics.get(path);
		}
		trace('$key doesnt exist, fuck');
		return null;
	}
	
	public static function music(key:String):String
		return 'assets/music/$key.ogg';
	
	public static function sound(key:String):String
		return 'assets/sounds/$key.ogg';

	public static function song(key:String):String
		return 'assets/songs/$key.ogg';
	
	public static function image(key:String):FlxGraphic
		return returnGraphic(key);
	
	public static function font(key:String):String
		return 'assets/fonts/$key';
		
	public static function file(key:String):String
		return 'assets/$key';
	
	public static function getSparrowAtlas(key:String)
	{
		var spriteSheet:FlxGraphic = returnGraphic(key);
		return FlxAtlasFrames.fromSparrow(spriteSheet, 'assets/images/$key.xml');
	}
}