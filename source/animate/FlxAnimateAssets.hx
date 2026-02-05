package animate;

import flixel.FlxG;
import haxe.io.Bytes;
import openfl.display.BitmapData;

using StringTools;

/**
 * Wrapper for assets to allow HaxeFlixel 5.9.0+ and HaxeFlixel 5.8.0- compatibility.
 * Class to be used for replacing the method used for loading assets, if using ``FlxAnimateFrames.fromAnimate`` through a folder path.
 * For more control over loading texture atlases I recommend using the rest of the params in the ``fromAnimate`` frame loader.
 */
class FlxAnimateAssets
{
	public static dynamic function exists(path:String, type:AssetType):Bool
	{
		trace("exist check " + path + " " + Assets.fileExists(path));
		return Assets.fileExists(path);
	}

	public static dynamic function getText(path:String):String
	{
		trace("text " + path);
		return Assets.getAsset(path, TEXT, false);
	}

	public static dynamic function getBytes(path:String):Bytes
	{
		trace("bytes " + path);
		return Assets.getAsset(path, BINARY, false);
	}

	public static dynamic function getBitmapData(path:String):BitmapData
	{
		trace("bmp " + path);
		return Assets.getAsset(path, IMAGE, false).bitmap;
	}

	public static dynamic function list(path:String, ?type:AssetType, ?library:String, includeSubDirectories:Bool = false):Array<String>
	{
		trace("list " + path);
		return Assets.list(path);
	}
}

typedef AssetType = #if (flixel >= "5.9.0") flixel.system.frontEnds.AssetFrontEnd.FlxAssetType #else openfl.utils.AssetType #end;