package;

import flixel.graphics.frames.FlxFramesCollection;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.sound.FlxSound;
import lime.utils.Assets;
import openfl.display.BitmapData;
import openfl.media.Sound;
//import states.PlayState;
import tjson.TJSON;

class Paths
{
	public static function clearMemory()
	{
		@:privateAccess
		for (graphic in FlxG.bitmap._cache)
		{
			if (graphic != null && graphic.useCount <= 0)
			{
				graphic.persist = false;
				graphic.destroy();
			}
		}
		FlxG.sound.destroy(false);
	}
	
	inline public static function getPath(key:String, ?library:String):String {
		#if RENAME_UNDERSCORE
		var pathArray:Array<String> = key.split("/").copy();
		var loopCount = 0;
		key = "";

		for (folder in pathArray) {
			var truFolder:String = folder;

			if(folder.startsWith("_"))
				truFolder = folder.substr(1);

			loopCount++;
			key += truFolder + (loopCount == pathArray.length ? "" : "/");
		}

		if(library != null)
			library = (library.startsWith("_") ? library.split("_")[1] : library);
		#end

		if(library == null)
			return 'assets/$key';
		else
			return 'assets/$library/$key';
	}

	inline public static function fileExists(filePath:String, ?library:String):Bool
		#if desktop
		return sys.FileSystem.exists(getPath(filePath, library));
		#else
		return openfl.Assets.exists(getPath(filePath, library));
		#end
	
	public static function font(key:String, ?library:String):String
		return getPath('fonts/$key', library);
	
	public static function text(key:String, ?library:String):String
		return Assets.getText(getPath('$key.txt', library)).trim();
}