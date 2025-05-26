package states.editors;

import openfl.net.FileFilter;
import openfl.net.FileReference;
import backend.game.GameData.MusicBeatState;

class ChartConvertState extends MusicBeatState
{
    public var fileName:String = "";
    public var fileLoaded:Dynamic = {};

    override function create()
    {
        super.create();



    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        if(FlxG.keys.justPressed.H)
            loadFile();
    }
    
    public function loadFile():Void
    {
        var _file = new FileReference();
        _file.browse([new FileFilter("Chart File", "json")]);
        
        fileLoaded = Paths.parseJson(_file.data.toString());
        fileName = _file.name;

        Logs.print("Loaded file: ");
        
        /*var json = {"song": formatSONG};

		var data:String = Json.stringify(json, "\t");

		if(data != null && data.length > 0)
		{
			var _file = new FileReference();
			_file.save(data.trim(), '$songDiff.json');
		}*/
    }

    public function saveFile():Void
    {
        
    }
}