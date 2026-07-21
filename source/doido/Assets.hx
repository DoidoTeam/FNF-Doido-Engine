package doido;

import animate.FlxAnimateFrames;
import doido.Cache;
import doido.objects.DoidoSprite.SpriteType;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.text.FlxBitmapFont;
import flixel.util.FlxColor;
import haxe.Json;
import haxe.io.Path;
import openfl.Assets as OpenFLAssets;
import openfl.display.BitmapData;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.media.Sound;
import flixel.addons.display.FlxRuntimeShader;

// am i gonna do something with this?
enum Asset
{
	IMAGE;
	SOUND;
	FONT;
	TEXT;
	JSON;
	XML;
	SCRIPT;
	SHADER;
	BINARY;
	OTHER;
}

// Paths V2
// libraries tbd
// maybe renaming to assets would be cool so im doing that for now
class Assets
{
	public static var extensions:Map<Asset, Array<String>> = [
		IMAGE => ["png"],
		SOUND => ["ogg"],
		FONT => ["ttf", "otf"],
		TEXT => ["txt"],
		JSON => ["json"],
		XML => ["xml"],
		SCRIPT => ["hx", "hxs", "hxc", "hscript"],
		SHADER => ["frag", "vert"],
		BINARY => [""],
		OTHER => [""] // ?
	];
	public static final mainPath:String = 'assets';

	public static inline function getPath(key:String, ?library:String = ""):String
	{
		if (library == "")
			return '$mainPath/$key';
		else
			return '$mainPath/$library/$key';
	}

	public static inline function fileExists(path:String, ?library:String = "", type:Asset = OTHER):Bool
		return whichExists(getPath(path, library), type) >= 0;

	public static function createDir(path:String)
	{
		#if sys
		if (!sys.FileSystem.exists(path))
			sys.FileSystem.createDirectory(path);
		#else
		Logs.print("Operation not supported on this target");
		#end
	}

	public static function openFolder(path:String)
	{
		#if android
		doido.system.android.Android.openFolder(path);
		#elseif windows
		Sys.command("explorer.exe /n, /e, \"" + Sys.getCwd().substring(0, Sys.getCwd().length - 1) + "\\" + path + "\"");
		#else
		Logs.print("Operation not supported on this target");
		#end
	}

	public static function fileBrowse(onComplete:openfl.net.FileReference->Void, ?filter:openfl.net.FileFilter, ?onError:String->Void):Void
	{
		var fr = new openfl.net.FileReference();

		var cleanupBrowse:Void->Void = () -> {};

		var onCompleteLoad = function(_)
		{
			cleanupBrowse();
			// fr.data returns bytes
			// fr.name returns file name
			onComplete(fr);
		};

		var onErrorLoad = function(e:IOErrorEvent)
		{
			cleanupBrowse();
			if (onError != null)
				onError(e.text);
		};

		var onSelect = function(_)
		{
			fr.addEventListener(Event.COMPLETE, onCompleteLoad);
			fr.addEventListener(IOErrorEvent.IO_ERROR, onErrorLoad);
			fr.load();
		};

		cleanupBrowse = function()
		{
			fr.removeEventListener(Event.SELECT, onSelect);
			fr.removeEventListener(Event.COMPLETE, onCompleteLoad);
			fr.removeEventListener(IOErrorEvent.IO_ERROR, onErrorLoad);
		};

		fr.addEventListener(Event.SELECT, onSelect);
		fr.browse(filter == null ? [] : [filter]);
	}

	public static function fileSave(data:Dynamic, name:String)
	{
		var saver = new openfl.net.FileReference();
		saver.save(data, name);
	}

	public static function getExt(key:String, ext:String)
	{
		var path = key;
		if (ext != "" && !path.endsWith('.$ext'))
			path += '.$ext';
		return path;
	}

	public static inline function isImage(path:String, type:Asset)
		return type == IMAGE || path.endsWith(".png");

	public static inline function isSound(path:String, type:Asset)
		return type == SOUND || path.endsWith(".ogg");

	public static function whichExists(path:String, type:Asset):Int
	{
		var ext = extensions.get(type);
		for (i in 0...ext.length)
		{
			if (path.endsWith('.${ext[i]}'))
				return i;

			var key:String = getExt(path, ext[i]);
			if (isImage(path, type) || isSound(path, type))
			{
				if (isImage(path, type) && Cache.isGraphicCached(key))
					return i;
				if (isSound(path, type) && Cache.isSoundCached(key))
					return i;
			}

			if (OpenFLAssets.exists(key))
			{
				return i;
			}
		}
		return -1;
	}

	public static function resolvePath(key:String, library:String = "", type:Asset):String
	{
		var path = getPath(key, library);
		var index = whichExists(path, type);
		if (index == -1)
		{
			Logs.print("PATH NOT FOUND: " + path, ERROR);
			return null;
		}

		return getExt(path, extensions.get(type)[index]);
	}

	inline public static function cleanPath(path:String):String
		return Path.withoutExtension(Path.withoutDirectory(path));

	public static function getAsset<T>(key:String, ?library:String = "", type:Asset, ext:Bool = true, persist:Bool = false):T
	{
		var path = resolvePath(key, library, (ext ? type : OTHER));

		switch (type)
		{
			case IMAGE:
				if (path == null)
					return null;
				return cast Cache.getGraphic(path, persist);
			case SOUND:
				if (path == null)
					path = resolvePath('sounds/beep', SOUND);
				return cast Cache.getSound(path, persist);
			case SHADER:
				var shaderArr:Array<String> = [null, null];
				shaderArr[path.endsWith('frag') ? 0 : 1] = OpenFLAssets.getText(path).trim();
				return cast new FlxRuntimeShader(shaderArr[0], shaderArr[1]);
			case TEXT | JSON | XML | SCRIPT:
				if (path == null)
					return cast "";
				return cast OpenFLAssets.getText(path).trim();
			case BINARY:
				return cast OpenFLAssets.getBytes(path);
			default:
				return cast path;
		};
	}

	public static function clearAsset(key:String, ?library:String = "", type:Asset, ext:Bool = true)
	{
		var path = resolvePath(key, library, (ext ? type : OTHER));
		switch (type)
		{
			case IMAGE:
				Cache.clearGraphic(path);
			case SOUND:
				Cache.clearSound(path);
			default:
				Logs.print("tried to clear non cacheable asset...");
		}
	}

	public static function queueAssetClear(key:String, ?library:String = "", type:Asset, ext:Bool = true)
	{
		var path = resolvePath(key, library, (ext ? type : OTHER));
		switch (type)
		{
			case IMAGE:
				Cache.wipeQueue.get("graphics").push(path);
			case SOUND:
				Cache.wipeQueue.get("sounds").push(path);
			default:
				Logs.print("tried to queue non cacheable asset...");
		}
	}

	public static function list(key:String, ?library:String = "", clean:Bool = false, ?exclude:Array<String>, type:Asset = OTHER):Array<String>
	{
		var rawlist:Array<String> = OpenFLAssets.list();
		var list:Array<String> = [];
		var path = getPath(key, library);
		if (exclude == null)
			exclude = [];

		if (type != OTHER)
		{
			for (i in 0...rawlist.length)
			{
				for (type in extensions.get(type))
				{
					if (rawlist[i].endsWith(type) && !(exclude.contains(rawlist[i]) || exclude.contains('${rawlist[i]}.$type')))
					{
						list.push(rawlist[i]);
					}
				}
			}
		}
		else
			list = rawlist;

		// taken from flixel-animate
		list = list.filter((str) -> str.startsWith(path.substring(path.indexOf(':') + 1, path.length)))
			.map((str) -> str.split('${path.split(":").pop()}/').pop());

		if (clean)
		{
			for (i in 0...list.length)
				list[i] = cleanPath(list[i]);
		}

		return list;
	}

	public static function getScriptArray(?song:String):Array<String>
	{
		var arr:Array<String> = [];
		for (folder in ["data/scripts/playstate", 'songs/$song/scripts'])
		{
			for (file in list(folder, SCRIPT))
			{
				if (!file.startsWith("_"))
					arr.push('$folder/$file');
			}
		}
		return arr;
	}

	/*
	 *   AUDIO
	 */
	public static inline function sound(key:String, ?library:String = "", persist:Bool = false):Sound
		return getAsset('sounds/$key', library, SOUND, true, persist);

	public static inline function music(key:String, ?library:String = "", persist:Bool = false):Sound
		return getAsset('music/$key', library, SOUND, true, persist);

	public static inline function clearSound(key:String, ?library:String = "")
		clearAsset('sounds/$key', library, SOUND);

	public static inline function clearMusic(key:String, ?library:String = "")
		clearAsset('music/$key', library, SOUND);

	public static inline function queueSoundClear(key:String, ?library:String = "")
		queueAssetClear('sounds/$key', library, SOUND);

	public static inline function queueMusicClear(key:String, ?library:String = "")
		queueAssetClear('music/$key', library, SOUND);

	public static inline function inst(song:String, postfix:String = "", persist:Bool = false):Sound
		return getAsset('songs/$song/audio/Inst$postfix', SOUND, true, persist);

	public static inline function voices(song:String, postfix:String = "", persist:Bool = false):Sound
		return getAsset('songs/$song/audio/Voices$postfix', SOUND, true, persist);

	/*
	 *   DATA
	 */
	public static inline function text(key:String, ?library:String):String
		return getAsset('$key', library, TEXT);

	public static inline function json(key:String, ?library:String = ""):Dynamic
		return Json.parse(getAsset(key, library, JSON));

	public static inline function script(key:String, ?library:String = ""):String
		return getAsset('$key', library, SCRIPT, true);

	public static inline function shader(key:String, ?library:String = ""):FlxRuntimeShader
		return getAsset('data/shaders/$key', library, SHADER, true);

	public static inline function font(key:String, ?library:String = ""):String
		return getAsset('fonts/$key', library, FONT);

	public static inline function textToArray(key:String, ?library:String = ""):Array<String>
	{
		var rawList:Array<String> = text(key, library).split('\n');
		var daList:Array<String> = [];

		for (text in rawList)
		{
			if (text == "")
				continue;

			daList.push(text.trim());
		}

		return daList;
	}

	/*
	 *   IMAGES
	 */
	public static inline function image(key:String, ?library:String = "", persist:Bool = false):FlxGraphic
		return getAsset('images/$key', library, IMAGE, true, persist);

	public static inline function clearImage(key:String, ?library:String = "")
		clearAsset('images/$key', library, IMAGE);

	public static inline function queueImageClear(key:String, ?library:String = "")
		queueAssetClear('images/$key', library, IMAGE);

	public static inline function sparrow(key:String, ?library:String = ""):FlxFramesCollection
		return framesCollection(key, library, SPARROW);

	public static inline function multiSparrow(key:String, ?library:String = "", extrasheets:Array<String>):FlxFramesCollection
		return framesCollection(key, extrasheets, library, MULTISPARROW);

	public static inline function packer(key:String, ?library:String = ""):FlxFramesCollection
		return framesCollection(key, library, PACKER);

	public static inline function aseprite(key:String, ?library:String = ""):FlxFramesCollection
		return framesCollection(key, library, ASEPRITE);

	public static inline function animate(key:String, ?library:String = ""):FlxAnimateFrames
		return cast framesCollection(key, library, ATLAS);

	public static inline function bitmapFont(key:String, ?library:String = "fonts"):FlxBitmapFont
		return cast framesCollection(key, library, FONT);

	public static inline function framesCollection(key:String, ?extrasheets:Array<String>, ?library:String = "", type:SpriteType, persist:Bool = false):FlxFramesCollection
	{
		var path = getPath(key, library);
		var frames:FlxFramesCollection = null;

		if (Cache.isFramesCached(path))
			frames = Cache.getCachedFrames(path);
		else
		{
			frames = switch (type)
			{
				case FONT:
					FlxBitmapFont.fromAngelCode(getAsset('images/$key', library, IMAGE), getAsset('images/$key', library, XML));
				case ASEPRITE:
					FlxAtlasFrames.fromAseprite(getAsset('images/$key', library, IMAGE), getAsset('images/$key', library, JSON));
				case PACKER:
					FlxAtlasFrames.fromSpriteSheetPacker(getAsset('images/$key', library, IMAGE), getAsset('images/$key', library, TEXT));
				case ATLAS:
					FlxAnimateFrames.fromAnimate('images/$key', library);
				default:
					FlxAtlasFrames.fromSparrow(getAsset('images/$key', library, IMAGE), getAsset('images/$key', library, XML));
			}
			if (type == MULTISPARROW && (extrasheets ?? []).length > 0)
			{
				for (extraKey in extrasheets)
				{
					var newFrames:FlxFramesCollection = FlxAtlasFrames.fromSparrow(getAsset('images/$extraKey', library, IMAGE), getAsset('images/$extraKey', library, XML));
					for (frame in newFrames.frames)
					{
						frames.pushFrame(frame);
					}
				}
			}
			Cache.setCachedFrames(path, frames, persist);
		}

		return frames;
	}

	public static inline function clearFrames(key:String, ?library:String = "")
		Cache.clearFrames(getPath(key, library));

	public static inline function queueFramesClear(key:String, ?library:String = "")
		Cache.wipeQueue.get("frames").push(getPath(key, library));

	public static function loadPaletteFromFile(key:String, ?library:String = ""):Array<Array<FlxColor>>
	{
		if (key.endsWith('.png'))
			key = key.substring(0, key.lastIndexOf('.png'));
		var path = getPath('images/$key.png', library);

		var bitmap = BitmapData.fromFile(path);
		var palettes:Array<Array<FlxColor>> = [];

		for (paletteIndex in 0...bitmap.height)
		{
			var palette = [];
			for (colorIndex in 0...bitmap.width)
			{
				var color:FlxColor = bitmap.getPixel32(colorIndex, paletteIndex);
				if (color.alpha != 0.0)
				{
					palette.push(color);
				}
			}
			palettes.push(palette);
		}

		bitmap.dispose();
		return palettes;
	}
}
