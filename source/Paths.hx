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
import states.PlayState;
import tjson.TJSON;

using StringTools;

class Paths
{
	public static var renderedGraphics:Map<String, FlxGraphic> = [];
	public static var renderedSounds:Map<String, Sound> = [];

	// idk
	public static function getPath(key:String, ?library:String):String {
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
	
	public static function fileExists(filePath:String, ?library:String):Bool
		#if desktop
		return sys.FileSystem.exists(getPath(filePath, library));
		#else
		return openfl.Assets.exists(getPath(filePath, library));
		#end
	
	public static function getSound(key:String, ?library:String):Sound
	{
		if(!renderedSounds.exists(key))
		{
			if(!fileExists('$key.ogg', library)) {
				Logs.print('$key.ogg doesnt exist', WARNING);
				key = 'sounds/beep';
			}
			Logs.print('created new sound $key');
			renderedSounds.set(key,
				#if desktop
				Sound.fromFile(getPath('$key.ogg', library))
				#else
				openfl.Assets.getSound(getPath('$key.ogg', library), false)
				#end
			);
		}
		return renderedSounds.get(key);
	}
	public static function getGraphic(key:String, ?library:String):FlxGraphic
	{
		if(key.endsWith('.png'))
			key = key.substring(0, key.lastIndexOf('.png'));
		var path = getPath('images/$key.png', library);
		if(fileExists('images/$key.png', library))
		{
			if(!renderedGraphics.exists(key))
			{
				#if desktop
				var bitmap = BitmapData.fromFile(path);
				#else
				var bitmap = openfl.Assets.getBitmapData(path, false);
				#end
				
				var newGraphic = FlxGraphic.fromBitmapData(bitmap, false, key, false);
				Logs.print('created new image $key');
				
				renderedGraphics.set(key, newGraphic);
			}
			
			return renderedGraphics.get(key);
		}
		Logs.print('$key.png doesnt exist, fuck', WARNING);
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
			
			renderedGraphics.remove(key);
			if(openfl.Assets.cache.hasBitmapData(key))
				openfl.Assets.cache.removeBitmapData(key);
			
			FlxG.bitmap.remove(graphic);
			#if (flixel < "6.0.0")
			graphic.dump();
			#end
			graphic.destroy();
		}

		Logs.print('cleared $clearCount');
		Logs.print('cleared ${clearCount.length} assets');

		// uhhhh
		@:privateAccess
		for(key in FlxG.bitmap._cache.keys())
		{
			var obj = FlxG.bitmap._cache.get(key);
			if(obj != null && !renderedGraphics.exists(key))
			{
				openfl.Assets.cache.removeBitmapData(key);
				FlxG.bitmap._cache.remove(key);
				#if (flixel < "6.0.0")
				obj.dump();
				#end
				obj.destroy();
			}
		}
		
		// sound clearing
		for (key => sound in renderedSounds)
		{
			if(dumpExclusions.contains(key + '.ogg')) continue;
			
			Assets.cache.clear(key);
			renderedSounds.remove(key);
		}
	}
	
	public static function music(key:String, ?library:String):Sound
		return getSound('music/$key', library);
	
	public static function sound(key:String, ?library:String):Sound
		return getSound('sounds/$key', library);

	public static function songPath(song:String, key:String, diff:String, prefix:String = ''):String
	{
		var song:String = 'songs/$song/audio/$key';
		var diffPref:String = '';
		
		// erect
		if(['erect', 'nightmare'].contains(diff))
			diffPref = '-erect';
		
		if(fileExists('$song$diffPref$prefix.ogg'))
			return '$song$diffPref$prefix';
		else
			return '$song$diffPref';
	}
	public static function inst(song:String, diff:String = ''):Sound
		return getSound(songPath(song, 'Inst', diff));

	public static function vocals(song:String, diff:String = '', ?prefix:String = ''):Sound
		return getSound(songPath(song, 'Voices', diff, prefix));
	
	public static function image(key:String, ?library:String):FlxGraphic
		return getGraphic(key, library);
	
	public static function font(key:String, ?library:String):String
		return getPath('fonts/$key', library);

	public static function text(key:String, ?library:String):String
		return Assets.getText(getPath('$key.txt', library)).trim();

	public static function getContent(filePath:String, ?library:String):String
		#if desktop
		return sys.io.File.getContent(getPath(filePath, library));
		#else
		return openfl.Assets.getText(getPath(filePath, library));
		#end

	public static function json(key:String, ?library:String):Dynamic
		return TJSON.parse(getContent('$key.json', library).trim());

	public static function script(key:String, ?library:String):String
		return getContent('$key', library);

	public static function shader(key:String, ?library:String):Null<String>
		return getContent('shaders/$key', library);

	public static function getScriptArray(?song:String):Array<String>
	{
		var arr:Array<String> = [];
		for(folder in ["scripts", 'songs/$song/scripts'])
		{
			for(file in readDir(folder, [".hx", ".hxc"], false))
				arr.push('$folder/$file');
		}
		//trace(arr);
		return arr;
	}

	public static function video(key:String, ?library:String):String
		return getPath('videos/$key.mp4', library);
	
	// sparrow (.xml) sheets
	public static function getSparrowAtlas(key:String, ?library:String)
		return FlxAtlasFrames.fromSparrow(getGraphic(key, library), getPath('images/$key.xml', library));
	
	// packer (.txt) sheets
	public static function getPackerAtlas(key:String, ?library:String)
		return FlxAtlasFrames.fromSpriteSheetPacker(getGraphic(key, library), getPath('images/$key.txt', library));

	// aseprite (.json) sheets
	public static function getAsepriteAtlas(key:String, ?library:String)
		return FlxAtlasFrames.fromAseprite(getGraphic(key, library), getPath('images/$key.json', library));

	// sparrow (.xml) sheets but split into multiple graphics
	public static function getMultiSparrowAtlas(baseSheet:String, otherSheets:Array<String>, ?library:String) {
		var frames:FlxFramesCollection = getSparrowAtlas(baseSheet);

		if(otherSheets.length > 0) {
			for(i in 0...otherSheets.length) {
				var newFrames:FlxFramesCollection = getSparrowAtlas(otherSheets[i]);
				for(frame in newFrames.frames) {
					frames.pushFrame(frame);
				}
			}
		}

		return frames;
	}

	// get single frame (for now sparrow only)
	public static function getFrame(key:String, frame:String, ?library:String):FlxGraphic
		return FlxGraphic.fromFrame(getSparrowAtlas(key).getByName(frame));
		
	public static function readDir(dir:String, ?typeArr:Array<String>, ?removeType:Bool = true, ?library:String):Array<String>
	{
		var swagList:Array<String> = [];
		
		try {
			#if desktop
			var rawList = sys.FileSystem.readDirectory(getPath(dir, library));
			for(i in 0...rawList.length)
			{
				if(typeArr?.length > 0)
				{
					for(type in typeArr) {
						if(rawList[i].endsWith(type)) {
							// cleans it
							if(removeType)
								rawList[i] = rawList[i].replace(type, "");
							swagList.push(rawList[i]);
						}
					}
				}
				else
					swagList.push(rawList[i]);
			}
			#end
		} catch(e) {}
		
		Logs.print('read dir ${(swagList.length > 0) ? '$swagList' : 'EMPTY'} at ${getPath(dir, library)}');
		return swagList;
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
		if(SaveData.data.get("Hitsounds") != "OFF")
			preSounds.push('sounds/hitsounds/${SaveData.data.get("Hitsounds")}');
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
				if(!fileExists('images/hud/$spritePath/$countName.png'))
					spritePath = 'base';
				
				preGraphics.push('hud/$spritePath/$countName');
			}
		}

		for(i in preGraphics)
			preloadGraphic(i);

		for(i in preSounds)
			preloadSound(i);
	}

	public static function preloadGraphic(key:String, ?library:String)
	{
		// no point in preloading something already loaded duh
		if(renderedGraphics.exists(key)) return;

		var what = new FlxSprite().loadGraphic(image(key, library));
		FlxG.state.add(what);
		FlxG.state.remove(what);
	}
	public static function preloadSound(key:String, ?library:String)
	{
		if(renderedSounds.exists(key)) return;

		var what = new FlxSound().loadEmbedded(getSound(key, library), false, false);
		what.play();
		what.stop();
	}
}
