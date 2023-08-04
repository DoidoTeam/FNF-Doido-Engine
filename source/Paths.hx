package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.system.FlxSound;
import lime.utils.Assets;
import openfl.display.BitmapData;
import openfl.media.Sound;
import sys.FileSystem;
import sys.io.File;

using StringTools;

class Paths
{
	public static var renderedGraphics:Map<String, FlxGraphic> = [];
	public static var renderedSounds:Map<String, Sound> = [];

	// idk
	public static function getPath(key:String):String
		return 'assets/$key';
	
	public static function getSound(key:String):Sound
	{
		if(!renderedSounds.exists(key))
		{
			renderedSounds.set(key, Sound.fromFile(getPath('$key.ogg')));
		}
		
		return renderedSounds.get(key);
	}
	public static function getGraphic(key:String):FlxGraphic
	{
		var path = getPath('images/$key.png');
		if(FileSystem.exists(path))
		{
			if(!renderedGraphics.exists(key))
			{
				var bitmap = BitmapData.fromFile(path);
				
				var newGraphic = FlxGraphic.fromBitmapData(bitmap, false, key, false);
				trace('created new image $key');
				
				renderedGraphics.set(key, newGraphic);
			}
			
			return renderedGraphics.get(key);
		}
		trace('$key doesnt exist, fuck');
		return null;
	}

	/* 	add .png at the end for images
	*	add .ogg at the end for sounds
	*/
	public static var dumpExclusions:Array<String> = [
		"menu/alphabet/default.png",
	];
	public static function clearMemory()
	{	
		// sprite handler
		var clearCount:Int = 0;
		for(key => graphic in renderedGraphics)
		{
			if(dumpExclusions.contains(key + '.png')) continue;

			trace('cleared $key');
			clearCount++;
			
			if (openfl.Assets.cache.hasBitmapData(key))
				openfl.Assets.cache.removeBitmapData(key);
			
			graphic.dump();
			graphic.destroy();
			FlxG.bitmap.remove(graphic);
			renderedGraphics.remove(key);
		}
		trace('cleared $clearCount assets');
		
		// sound clearing
		for (key => sound in renderedSounds)
		{
			if(dumpExclusions.contains(key + '.ogg')) return;
			
			Assets.cache.clear(key);
			renderedSounds.remove(key);
		}
	}
	
	public static function music(key:String):Sound
		return getSound('music/$key');
	
	public static function sound(key:String):Sound
		return getSound('sounds/$key');

	public static function inst(key:String):Sound
		return getSound('songs/$key/Inst');

	public static function vocals(key:String):Sound
		return getSound('songs/$key/Voices');
	
	public static function image(key:String):FlxGraphic
		return getGraphic(key);
	
	public static function font(key:String):String
		return getPath('fonts/$key');

	public static function text(key:String):String
		return Assets.getText(getPath('$key.txt')).trim();
	
	public static function getSparrowAtlas(key:String)
		return FlxAtlasFrames.fromSparrow(getGraphic(key), 'assets/images/$key.xml');

	// preload stuff for playstate
	// so it doesnt lag whenever it gets called out
	public static function preloadPlayStuff():Void
	{
		var preGraphics:Array<String> = [
			"hud/base/ready",
			"hud/base/set",
			"hud/base/go",
		];
		var preSounds:Array<String> = [
			"sounds/countdown/intro3",
			"sounds/countdown/intro2",
			"sounds/countdown/intro1",
			"sounds/countdown/introGo",

			"sounds/miss/missnote1",
			"sounds/miss/missnote2",
			"sounds/miss/missnote3",

			"music/death/deathSound",
			"music/death/deathMusic",
			"music/death/deathMusicEnd",
		];

		for(i in preGraphics)
			preloadGraphic(i);

		for(i in preSounds)
			preloadSound(i);
	}

	public static function preloadGraphic(key:String)
	{
		// no point in preloading something already loaded duh
		if(renderedGraphics.exists(key)) return;

		var what = new FlxSprite().loadGraphic(image(key));
		FlxG.state.add(what);
		FlxG.state.remove(what);
	}
	public static function preloadSound(key:String)
	{
		if(renderedSounds.exists(key)) return;

		var what = new FlxSound().loadEmbedded(getSound(key), false, false);
		what.play();
		what.stop();
	}
}