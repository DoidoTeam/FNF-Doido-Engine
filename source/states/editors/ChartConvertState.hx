package states.editors;

import backend.song.SongConverter;
import tjson.TJSON;
import openfl.events.Event;
import openfl.net.FileFilter;
import openfl.net.FileReference;
import backend.game.GameData.MusicBeatState;

class ChartConvertState extends MusicBeatState
{
    public var fileName:String = "No File Loaded!!";
    public var fileLoaded:Dynamic = {};

    override function create()
    {
        super.create();
        fileLoaded = null;


    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        if(FlxG.keys.justPressed.H)
            loadFile();

        if(fileLoaded != null)
        {
            try {
                if(FlxG.keys.justPressed.ONE)
                {
                    saveFile(SongConverter.updateDoidoChart(cast fileLoaded.song));
                }
            } catch(e) {
                Logs.print("Oops", ERROR);
            }
        }
    }
    
    public function saveFile(daFile:Dynamic):Void
    {
        if(daFile != null)
        {
            var data:String = haxe.Json.stringify(daFile, "\t");
            if(data != null && data.length > 0)
            {
                var _file = new FileReference();
                _file.save(data.trim(), '$fileName');
            }
            fileLoaded = null;
        }
    }

    public function loadFile():Void
    {
        var _file = new FileReference();
        _file.addEventListener(Event.SELECT, (e:Event) -> {
            _file.load();

            fileName = _file.name;
            Logs.print('Loaded file: $fileName');
            if(_file.data != null)
            {
                fileLoaded = Paths.parseJson(_file.data.toString());
                //Logs.print('${_file.data.toString()}');
            }
            
        }, false, 0, true);
        _file.addEventListener(Event.CANCEL, (e:Event) -> {

            Logs.print("Cancelled!!");

        }, false, 0, true);
        _file.browse([new FileFilter("Chart File", "*.json")]);
    }
}