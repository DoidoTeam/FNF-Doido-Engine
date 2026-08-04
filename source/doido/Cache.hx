package doido;

import openfl.Assets as OpenFLAssets;
import openfl.display.BitmapData;
import flixel.graphics.FlxGraphic;
import openfl.media.Sound;
import flixel.graphics.frames.FlxFramesCollection;

typedef Cached =
{
	var graphics:Map<String, FlxGraphic>;
	var frames:Map<String, FlxFramesCollection>;
	var sounds:Map<String, Sound>;
}

// caching class

@:access(openfl.display.BitmapData)
class Cache
{
	// maybe you shouldnt be able to access these?
	public static var current:Cached;
	public static var permanent:Cached;
	public static var wipeQueue:Map<String, Array<String>> = ["graphics" => [], "frames" => [], "sounds" => []];

	public static var initialized:Bool = false;
	public static var loading:Bool = false;

	// whatever dude
	public static function initCache()
	{
		current = {
			graphics: new Map<String, FlxGraphic>(),
			frames: new Map<String, FlxFramesCollection>(),
			sounds: new Map<String, Sound>()
		};

		permanent = {
			graphics: new Map<String, FlxGraphic>(),
			frames: new Map<String, FlxFramesCollection>(),
			sounds: new Map<String, Sound>()
		};

		FlxGraphic.defaultPersist = true;
		openfl.Assets.cache.enabled = false;
		initialized = true;
	}

	public static function clearCache()
	{
		if (!initialized)
			return;
		clearGraphics();
		clearAllFrames();
		clearSounds();
		clearOther();
	}

	public static function clearOther()
	{
		@:privateAccess
		for (key in FlxG.bitmap._cache.keys())
		{
			var obj = FlxG.bitmap._cache.get(key);
			if (obj != null && !isGraphicCached(key))
			{
				FlxG.bitmap._cache.remove(key);
				obj.destroy();
			}
		}
	}

	// GRAPHICS

	public static function clearGraphics()
	{
		for (key => graphic in current.graphics)
			clearGraphic(key);

		for (key in wipeQueue.get("graphics"))
			clearGraphic(key);

		wipeQueue.set("graphics", []);
	}

	public static function clearGraphic(key:String)
	{
		var graphic:FlxGraphic;
		if (current.graphics.exists(key))
		{
			graphic = current.graphics.get(key);
			current.graphics.remove(key);
		}
		else if (permanent.graphics.exists(key))
		{
			graphic = permanent.graphics.get(key);
			permanent.graphics.remove(key);
		}
		else
			return;

		killGraphic(graphic);
	}

	public static function killGraphic(graphic:FlxGraphic)
	{
		if (graphic == null)
			return;

		if (graphic.bitmap != null && graphic.bitmap.__texture != null)
			graphic.bitmap.__texture.dispose();
		graphic.persist = false;
		graphic.destroy();
	}

	public static function isGraphicCached(key:String)
		return current.graphics.exists(key) || permanent.graphics.exists(key);

	public static function pushToGPU(bitmap:BitmapData)
	{
		bitmap.lock();
		if (bitmap.__texture == null)
		{
			bitmap.image.premultiplied = true;
			bitmap.getTexture(FlxG.stage.context3D);
		}
		bitmap.getSurface();
		bitmap.disposeImage();
		bitmap.image.data = null;
		bitmap.image = null;
		bitmap.readable = true;
	}

	public static function pushAll()
	{
		if (waitingList.length <= 0 || !Save.data.gpuCaching)
			return;

		for (key in waitingList)
		{
			var graphic = getCachedGraphic(key);
			if (graphic != null && graphic.bitmap != null) // just to be sure
				pushToGPU(graphic.bitmap);
		}

		waitingList = [];
	}

	public static var waitingList:Array<String> = [];

	// HAS TO GET THE FULL PATH ex: "assets/images/image.png"
	public static function getGraphic(key:String, persist:Bool = false):FlxGraphic
	{
		if (isGraphicCached(key))
			return getCachedGraphic(key, persist);

		Logs.print("creating: " + key);

		var bitmap:BitmapData = OpenFLAssets.getBitmapData(key, false);

		if (Save.data.gpuCaching)
		{
			if (!loading)
				pushToGPU(bitmap);
			else
				waitingList.push(key);
		}

		var graphic:Null<FlxGraphic> = FlxGraphic.fromBitmapData(bitmap, false, null, false); // note: if this doesnt work, set last field to true
		if (persist)
			permanent.graphics.set(key, graphic);
		else
			current.graphics.set(key, graphic);
		return graphic;
	}

	public static function getCachedGraphic(key:String, persist:Bool = false):FlxGraphic
	{
		// Logs.print("we gotta get a cached graphic! " + key);

		if (!isGraphicCached(key))
			return null; // just in case?
		if (permanent.graphics.exists(key))
			return permanent.graphics.get(key);

		var graphic = current.graphics.get(key);
		if (persist)
		{ // if you ever want to move a graphic from current to permanent?
			current.graphics.remove(key);
			permanent.graphics.set(key, graphic);
		}
		return graphic;
	}

	// FRAMES
	// note: rename later
	public static function clearAllFrames()
	{
		for (key => frames in current.frames)
			clearFrames(key);

		for (key in wipeQueue.get("frames"))
			clearFrames(key);

		wipeQueue.set("frames", []);
	}

	public static function clearFrames(key:String)
	{
		var frames:FlxFramesCollection;
		if (current.frames.exists(key))
		{
			frames = current.frames.get(key);
			current.frames.remove(key);
		}
		else if (permanent.frames.exists(key))
		{
			frames = permanent.frames.get(key);
			permanent.frames.remove(key);
		}
		else
			return;

		killFrames(frames);
	}

	public static function killFrames(frames:FlxFramesCollection)
	{
		if (frames != null)
		{
			frames.destroy();
			frames = null;
		}
	}

	public static function isFramesCached(key:String)
		return current.frames.exists(key) || permanent.frames.exists(key);

	public static function setCachedFrames(key:String, frames:FlxFramesCollection, persist:Bool = false)
	{
		if (persist)
			permanent.frames.set(key, frames);
		else
			current.frames.set(key, frames);
		return frames;
	}

	public static function getCachedFrames(key:String, persist:Bool = false):FlxFramesCollection
	{
		// Logs.print("we gotta get a cached frame! " + key);

		if (!isFramesCached(key))
			return null; // just in case?
		if (permanent.frames.exists(key))
			return permanent.frames.get(key);

		var frames = current.frames.get(key);
		if (persist)
		{ // if you ever want to move a graphic from current to permanent?
			current.frames.remove(key);
			permanent.frames.set(key, frames);
		}
		return frames;
	}

	// SOUND

	public static function clearSounds()
	{
		for (key => sound in current.sounds)
			clearSound(key);

		for (key in wipeQueue.get("sounds"))
			clearSound(key);

		wipeQueue.set("sounds", []);
	}

	public static function clearSound(key:String)
	{
		var sound:Sound;
		if (current.sounds.exists(key))
		{
			sound = current.sounds.get(key);
			current.sounds.remove(key);
		}
		else if (permanent.sounds.exists(key))
		{
			sound = permanent.sounds.get(key);
			permanent.sounds.remove(key);
		}
		else
			return;

		killSound(sound);
	}

	public static function killSound(sound:Sound)
	{
		#if !html5
		sound.close();
		#end
		sound = null;
	}

	public static function isSoundCached(key:String)
		return current.sounds.exists(key) || permanent.sounds.exists(key);

	public static function getSound(key:String, persist:Bool = false):Sound
	{
		if (isSoundCached(key))
			return getCachedSound(key, persist);
		var sound:Null<Sound> = OpenFLAssets.getSound(key, false);
		if (persist)
			permanent.sounds.set(key, sound);
		else
			current.sounds.set(key, sound);
		return sound;
	}

	public static function getCachedSound(key:String, persist:Bool = false):Sound
	{
		if (!isSoundCached(key))
			return null; // just in case?
		if (permanent.sounds.exists(key))
			return permanent.sounds.get(key);

		var sound = current.sounds.get(key);
		if (persist)
		{
			current.sounds.remove(key);
			permanent.sounds.set(key, sound);
		}
		return sound;
	}
}
