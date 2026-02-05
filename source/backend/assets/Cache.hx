package backend.assets;

import openfl.Assets as OpenFLAssets;
import openfl.display.BitmapData;
import flixel.graphics.FlxGraphic;
import openfl.media.Sound;

typedef Cached =
{
	var graphics:Map<String, FlxGraphic>;
	var sounds:Map<String, Sound>;
}

//caching class
@:access(openfl.display.BitmapData)
class Cache
{
    //maybe you shouldnt be able to access these?
    public static var current:Cached;
    public static var permanent:Cached;

    public static var initialized:Bool = false;

    //whatever dude
    public static function initCache()
    {
        current = {
            graphics: new Map<String, FlxGraphic>(),
            sounds: new Map<String, Sound>()
        };

        permanent = {
            graphics: new Map<String, FlxGraphic>(),
            sounds: new Map<String, Sound>()
        };

        initialized = true;
    }

    public static function clearCache()
    {
        if(!initialized) return;
        clearGraphics();
        clearSounds();
        clearOther();
    }

    public static function clearOther() {
        @:privateAccess
		for(key in FlxG.bitmap._cache.keys())
		{
			var obj = FlxG.bitmap._cache.get(key);
			if(obj != null && !isGraphicCached(key))
			{
				FlxG.bitmap._cache.remove(key);
				obj.destroy();
			}
		}
    }

    // GRAPHICS

    public static function clearGraphics() {
        for(key => graphic in current.graphics) {
            //FlxG.bitmap.remove(graphic); maybe not?
            if (graphic.bitmap != null && graphic.bitmap.__texture != null)
                graphic.bitmap.__texture.dispose();
            graphic.persist = false;
            graphic.destroy();
            current.graphics.remove(key);
        }
    }

    public static function isGraphicCached(key:String)
        return current.graphics.exists(key) || permanent.graphics.exists(key);

    //HAS TO GET THE FULL PATH ex: "assets/images/image.png"
    public static function getGraphic(key:String, persist:Bool = false):FlxGraphic {
        if(isGraphicCached(key)) return getCachedGraphic(key, persist);

        Logs.print("creating: " + key);

        var bitmap:BitmapData = OpenFLAssets.getBitmapData(key, false);
        
        if(Save.data.gpuCaching) {
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

        var graphic:Null<FlxGraphic> = FlxGraphic.fromBitmapData(bitmap, false, null, false); //note: if this doesnt work, set last field to true
        if(persist)
            permanent.graphics.set(key, graphic);
        else
            current.graphics.set(key, graphic);
        return graphic;
    }

    public static function getCachedGraphic(key:String, persist:Bool = false):FlxGraphic {
        //Logs.print("we gotta get a cached graphic! " + key);

        if(!isGraphicCached(key)) return null; //just in case?
        if(permanent.graphics.exists(key)) return permanent.graphics.get(key);

        var graphic = current.graphics.get(key);
        if(persist) { //if you ever want to move a graphic from current to permanent?
            current.graphics.remove(key);
            permanent.graphics.set(key, graphic);
        }
        return graphic;      
    }

    // SOUND

    public static function clearSounds() {
		for (key => sound in current.sounds) {	
            //?!		
			//LimeAssets.cache.clear(key);
			current.sounds.remove(key);
		}
    }

    public static function isSoundCached(key:String)
        return current.sounds.exists(key) || permanent.sounds.exists(key);

    public static function getSound(key:String, persist:Bool = false):Sound {
        if(isSoundCached(key)) return getCachedSound(key, persist);
        var sound:Null<Sound> = OpenFLAssets.getSound(key, false);
        if(persist)
            permanent.sounds.set(key, sound);
        else
            current.sounds.set(key, sound);
        return sound;
    }

    public static function getCachedSound(key:String, persist:Bool = false):Sound {
        if(!isSoundCached(key)) return null; //just in case?
        if(permanent.sounds.exists(key)) return permanent.sounds.get(key);

        var sound = current.sounds.get(key);
        if(persist) {
            current.sounds.remove(key);
            permanent.sounds.set(key, sound);
        }
        return sound;      
    }
}