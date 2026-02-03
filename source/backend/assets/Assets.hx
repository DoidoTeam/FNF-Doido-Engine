package source.backend.assets;

import openfl.Assets as OpenFLAssets;

//am i gonna do something with this?
enum Asset
{
	IMAGE;
    SOUND;
    TEXT;
    SCRIPT;
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
        TEXT => ["txt", "json"],
        SCRIPT => ["hxc", "hx"],
        OTHER => [""] //?
    ];
    public static final mainPath:String = 'assets';
    public static function getPath(key:String):String {
        return '$mainPath/';
    }

    public static function fileExists(path:String, type:Asset):Bool
        return whichExists(path, type) >= 0;

    public static function whichExists(path:String, type:Asset):Int {
        for (i in 0...extensions.get(type).length) {
            if(OpenFLAssets.exists(getPath(filePath, library)))
                return i;
        }

        return -1;
    }
}