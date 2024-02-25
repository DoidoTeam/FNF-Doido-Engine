package;

import haxe.Json;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.sound.FlxSound;
import lime.utils.Assets;
import openfl.display.BitmapData;
import openfl.media.Sound;
import states.PlayState;
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
	
	public static function fileExists(filePath:String):Bool
		return FileSystem.exists(getPath(filePath));
	
	public static function getSound(key:String):Sound
	{
		if(!renderedSounds.exists(key))
			renderedSounds.set(key, Sound.fromFile(getPath('$key.ogg')));
		
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
		"menu/checkmark.png",
		"menu/menuArrows.png",
	];
	public static function clearMemory()
	{	
		// sprite caching
		var clearCount:Array<String> = [];
		for(key => graphic in renderedGraphics)
		{
			if(dumpExclusions.contains(key + '.png')) continue;

			clearCount.push(key);
			
			if (openfl.Assets.cache.hasBitmapData(key))
				openfl.Assets.cache.removeBitmapData(key);
			
			graphic.dump();
			graphic.destroy();
			FlxG.bitmap.remove(graphic);
			renderedGraphics.remove(key);
		}
		trace('cleared $clearCount');
		trace('cleared ${clearCount.length} assets');
		
		// sound clearing
		for (key => sound in renderedSounds)
		{
			if(dumpExclusions.contains(key + '.ogg')) continue;
			
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

	public static function json(key:String):Dynamic
	{
		var rawJson = File.getContent(getPath('$key.json')).trim();

		while(!rawJson.endsWith("}"))
			rawJson = rawJson.substr(0, rawJson.length - 1);

		return Json.parse(rawJson);
	}

	public static function video(key:String):String
	{
		return getPath('videos/$key.mp4');
	}
	
	// sparrow (.xml) sheets
	public static function getSparrowAtlas(key:String)
		return FlxAtlasFrames.fromSparrow(getGraphic(key), getPath('images/$key.xml'));
	
	// packer (.txt) sheets
	public static function getPackerAtlas(key:String)
		return FlxAtlasFrames.fromSpriteSheetPacker(getGraphic(key), getPath('images/$key.txt'));
		
	public static function readDir(dir:String, ?type:String, ?removeType:Bool = true):Array<String>
	{
		var theList:Array<String> = [];
		
		try
		{
			var rawList = FileSystem.readDirectory(getPath(dir));
			for(i in 0...rawList.length)
			{
				if(type != null)
				{
					// 
					if(!rawList[i].endsWith(type))
						rawList[i] = "";
					
					// cleans it
					if(removeType)
						rawList[i] = rawList[i].replace(type, "");
				}
				
				// adds it to the real list if its not empty
				if(rawList[i] != "")
					theList.push(rawList[i]);
			}
		} catch(e) {}
		
		trace(theList);
		return theList;
	}

	// preload stuff for playstate
	// so it doesnt lag whenever it gets called out
	public static function preloadPlayStuff():Void
	{
		var preGraphics:Array<String> = [
			//"hud/base/ready",
		];
		var preSounds:Array<String> = [
			//"sounds/countdown/intro3",
			
			"music/death/deathSound",
			"music/death/deathMusic",
			"music/death/deathMusicEnd",
		];
		for(i in 1...4)
			preSounds.push('sounds/miss/missnote${i}');
		
		for(i in 0...4)
		{
			var soundName:String = ["3", "2", "1", "Go"][i];
				
			var soundPath:String = PlayState.countdownModifier;
			if(!fileExists('sounds/countdown/$soundPath/intro$soundName.ogg'))
				soundPath = 'base';
			
			preSounds.push('sounds/countdown/$soundPath/intro$soundName');
			
			if(i >= 1)
			{
				var countName:String = ["ready", "set", "go"][i - 1];
				
				var spritePath:String = PlayState.countdownModifier;
				if(!Paths.fileExists('images/hud/$spritePath/$countName.png'))
					spritePath = 'base';
				
				preGraphics.push('hud/$spritePath/$countName');
			}
		}

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