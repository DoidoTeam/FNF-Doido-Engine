package states.editors;

import objects.menu.Alphabet;
import flixel.text.FlxText;
import flixel.FlxSprite;
import backend.song.SongConverter;
import tjson.TJSON;
import openfl.events.Event;
import openfl.net.FileFilter;
import openfl.net.FileReference;
import backend.game.GameData.MusicBeatState;

class ChartConvertState extends MusicBeatState
{
    public var chartName:String = "No Chart Loaded!!";
    public var eventName:String = "No Events Loaded!!";

    public var loadedJson:Map<String, Dynamic> = [
        "chart" => null,
        "event" => null,
    ];

    override function create()
    {
        super.create();
        var bg = new FlxSprite().loadGraphic(Paths.image("menu/backgrounds/menuInvert"));
        bg.color = 0xFFAD66E9;
		bg.screenCenter();
		bg.scrollFactor.set();
		add(bg);

        var mainY:Float = 30;

        var loadLabel = new Alphabet(FlxG.width / 2, 0, "", false);
		loadLabel.align = CENTER;
        loadLabel.scale.set(0.55,0.55);
		loadLabel.y = mainY;
		loadLabel.updateHitbox();
        setTxt(loadLabel, "Load Files");
		add(loadLabel);

        var convertLabel = new Alphabet(FlxG.width / 2, 0, "", false);
		convertLabel.align = CENTER;
        convertLabel.scale.set(0.55,0.55);
		convertLabel.y = mainY + 200;
		convertLabel.updateHitbox();
        setTxt(convertLabel, "Convert Files");
		add(convertLabel);
        
        var txtLoadChart = new Alphabet(0, 0, "", false);
		txtLoadChart.align = RIGHT;
        txtLoadChart.scale.set(0.45,0.45);
        txtLoadChart.x = FlxG.width / 2 - 10;
		txtLoadChart.y = mainY + 110;
		txtLoadChart.updateHitbox();
        setTxt(txtLoadChart, chartName);
		add(txtLoadChart);

        var txtLoadEvent = new Alphabet(0, 0, "", false);
		txtLoadEvent.align = LEFT;
        txtLoadEvent.scale.set(0.45,0.45);
        txtLoadEvent.x = FlxG.width / 2 + 10;
		txtLoadEvent.y = mainY + 110;
		txtLoadEvent.updateHitbox();
        setTxt(txtLoadEvent, eventName);
		add(txtLoadEvent);

        var btnLoadChart = new ConvertButton("load_chart", () -> {
            loadFile("chart", () -> {
                setTxt(txtLoadChart, "Chart: " + chartName);
            });
        });
        var posL:Float = FlxG.width / 2 - btnLoadChart.width - 10;
        var posR:Float = FlxG.width / 2 + 10;
        btnLoadChart.setPosition(posL, mainY + 45);
        add(btnLoadChart);

        var btnLoadEvent = new ConvertButton("load_event", () -> {
            loadFile("event", () -> {
                setTxt(txtLoadEvent, "Events: " + eventName);
            });
        });
        btnLoadEvent.setPosition(posR, mainY + 45);
        add(btnLoadEvent);

        var btnConvertDoidoOld = new ConvertButton("convert_doido_old", () -> {
            
        });
        btnConvertDoidoOld.setPosition(posL, mainY + 245);
        add(btnConvertDoidoOld);

        var btnConvertDoidoNew = new ConvertButton("convert_doido_new", () -> {
            saveFile(SongConverter.updateDoidoChart(cast loadedJson.get("chart").song));
        });
        btnConvertDoidoNew.setPosition(posR, mainY + 245);
        add(btnConvertDoidoNew);
    }

    public function setTxt(item:Alphabet, newTxt:String)
    {
        item.text = newTxt;
        for(letter in item.members)
            letter.setColorTransform(1, 1, 1, letter.alpha, 255, 255, 255);
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
    }
    
    public function saveFile(daFile:Dynamic, isEvent:Bool = false):Void
    {
        if(daFile != null)
        {
            var data:String = haxe.Json.stringify(daFile, "\t");
            if(data != null && data.length > 0)
            {
                var _file = new FileReference();
                _file.save(data.trim(), isEvent ? 'event_output.json' : 'chart_output.json');
            }
        }
    }

    public function loadFile(fileToLoad:String, ?afterLoad:Void->Void):Void
    {
        var _file = new FileReference();
        _file.addEventListener(Event.SELECT, (e:Event) -> {
            _file.load();

            if(fileToLoad == "chart")
                chartName = _file.name;
            else if(fileToLoad == "event")
                eventName = _file.name;
            Logs.print('Loaded file: ${_file.name}');
            if(_file.data != null)
            {
                loadedJson.set(fileToLoad, Paths.parseJson(_file.data.toString()));
                //Logs.print('${_file.data.toString()}');
            }

            if(afterLoad != null)
                afterLoad();
            
        }, false, 0, true);
        _file.addEventListener(Event.CANCEL, (e:Event) -> {

            Logs.print("Cancelled!!");

        }, false, 0, true);
        _file.browse([new FileFilter("Chart File", "*.json")]);
    }
}
class ConvertButton extends FlxSprite
{
    public var curName:String = "";
    public var onClick:Void->Void;

    public function new(curName:String, onClick:Void->Void)
    {
        super();
        this.curName = curName;
        this.onClick = onClick;
        frames = Paths.getSparrowAtlas('menu/chartconvert/buttons');
        animation.addByPrefix('idle', 'buttons', 0, false);
        animation.play('idle');

        animation.curAnim.curFrame = switch(curName)
        {
            case "load_chart": 0;
            case "load_event": 1;
            case "convert_doido_old": 2;
            case "convert_doido_new": 3;
            default: 0;
        }
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        if(FlxG.mouse.overlaps(this))
        {
            alpha = 1.0;
            if(FlxG.mouse.justPressed && onClick != null)
            {
                try {
                    onClick();
                } catch(e) {
                    FlxG.sound.play(Paths.sound('menu/cancelMenu'));
                    Logs.print("Oops", ERROR);
                }
            }
        }
        else
            alpha = 0.4;
    }
}