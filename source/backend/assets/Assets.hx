package backend.assets;

import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFramesCollection;
import animate.FlxAnimateFrames;
import openfl.Assets as OpenFLAssets;
import openfl.media.Sound;
import tjson.TJSON;

//am i gonna do something with this?
enum Asset
{
	IMAGE;
    SOUND;
    FONT;
    TEXT;
    JSON;
    XML;
    //SCRIPT;
    OTHER;
}

// Paths V2
// libraries tbd
// maybe renaming to assets would be cool so im doing that for now
class Assets
{
    public static var extensions:Map<Asset,Array<String>> = [
        IMAGE => ["png"],
        SOUND => ["ogg"],
        FONT => ["ttf", "otf"],
        TEXT => ["txt"],
        JSON => ["json"],
        XML => ["xml"],
        OTHER => [""] //?
    ];
    public static final mainPath:String = 'assets';
    public static function getPath(key:String):String {
        return '$mainPath/$key';
    }

    public static function fileExists(path:String, type:Asset):Bool
        return whichExists(getPath(path), type) >= 0;

    public static function whichExists(path:String, type:Asset):Int {
        var ext = extensions.get(type);
        for (i in 0...ext.length) {
            if(OpenFLAssets.exists('$path.${ext[i]}')) {
                return i;
            }
                
        }

        return -1;
    }

    public static function resolvePath(key:String, type:Asset):String {
        var path = getPath(key);
        var index = whichExists(path, type);
        if(index == -1)
            return null;

        return getPath('$key.${extensions.get(type)[index]}');
    }

    public static function getAsset<T>(key:String, type:Asset):T {
        var path = resolvePath(key, type);
        switch(type) {
            case IMAGE:
                if(path == null)
                    return null;
                return cast Cache.getGraphic(path, false);
            case SOUND:
                if(path == null)
                    path = resolvePath('sounds/beep', SOUND);
                return cast Cache.getSound(path, false);
            case TEXT | JSON | XML:
                return cast OpenFLAssets.getText(path).trim();
            default:
                return cast path;
        };
    }

    public static function image(key:String):FlxGraphic
		return getAsset('images/$key', IMAGE);

    public static function sound(key:String):Sound
		return getAsset('sounds/$key', SOUND);

    public static function music(key:String):Sound
        return getAsset('music/$key', SOUND);

    public static function font(key:String):String
        return getAsset('fonts/$key', FONT);

    public static function json(key:String):Dynamic
		return TJSON.parse(getAsset('$key', JSON));

    public static function sparrow(key:String):FlxFramesCollection
		return FlxAtlasFrames.fromSparrow(getAsset('images/$key', IMAGE), getAsset('images/$key', XML));
	
	public static function animate(key:String):FlxAnimateFrames
		return FlxAnimateFrames.fromAnimate(key);

    public static function inst(song:String):Sound
		return getAsset('songs/$song/audio/Inst', SOUND);

    public static function voices(song:String):Sound
		return getAsset('songs/$song/audio/Voices', SOUND);
}