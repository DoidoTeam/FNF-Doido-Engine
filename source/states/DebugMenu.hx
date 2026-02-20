package states;

import doido.song.SongData;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID as FlxPad;
import openfl.net.FileReference;
import openfl.net.FileFilter;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import tjson.TJSON;
import haxe.Json;

using doido.utils.TextUtil;

class DebugMenu extends MusicBeatState
{
    var options:Array<String> = ["PlayState", "Controls", "Options", "Chart Converter"];
    var text:FlxText;
    var title:FlxText;
    var ver:FlxText;
    var cur:Int = 0;

    override function create()
    {
        super.create();
        DiscordIO.changePresence("In the Main Menu");

        var bg = new FlxSprite().loadGraphic(Assets.image('menuInvert'));
		add(bg);

        text = new FlxText(10, 0, 0, '');
		text.setFormat(Main.globalFont, 48, 0xFFFFFFFF, LEFT);
		text.setOutline(0xFF000000, 3);
		add(text);
        drawText();
        text.y = FlxG.height - text.height - 10;

        title = new FlxText(10, 0, 0, 'DE-Pudim');
		title.setFormat(Main.globalFont, 100, 0xFFFFFFFF, LEFT);
		title.setOutline(0xFF000000, 5);
        title.y = text.y - title.height;
		add(title);

        ver = new FlxText(10, 0, 0, Main.internalVer);
		ver.setFormat(Main.globalFont, 32, 0xFFFFFFFF, LEFT);
		ver.setOutline(0xFF000000, 2.5);
        ver.x = title.x + title.width + 5;
        ver.y = text.y - ver.height;
		add(ver);
    }

    function drawText() {
        text.text = "";
        for(i in 0...options.length)
            text.text += options[i] + (i == cur ? " <\n" : "\n");
    }

    override function update(elapsed:Float)
	{
		super.update(elapsed);

        if(Controls.justPressed(UI_UP))
            changeSelection(-1);
        if(Controls.justPressed(UI_DOWN))
            changeSelection(1);

        if(Controls.justPressed(ACCEPT)) {
            switch(options[cur].toLowerCase()) {
                case "options":
                    MusicBeat.switchState(new DebugOptions());
                case "controls":
                    MusicBeat.switchState(new DebugControls());
                case "chart converter":
                    MusicBeat.switchState(new ChartConverter());
                default:
                    MusicBeat.switchState(new states.PlayState());
            }
        }
    }

    public function changeSelection(change:Int = 0)
	{
		if(change != 0) FlxG.sound.play(Assets.sound('scroll'));
		
		cur += change;
		cur = FlxMath.wrap(cur, 0, options.length - 1);
		drawText();
	}
}

class ChartConverter extends MusicBeatState
{
    var options:Array<String> = ["FNF 2 Doido", "Doido 2 FNF"];
    var text:FlxText;
    var title:FlxText;
    var ver:FlxText;
    var cur:Int = 0;

    override function create()
    {
        super.create();
        DiscordIO.changePresence("In the Main Menu");

        var bg = new FlxSprite().loadGraphic(Assets.image('menuInvert'));
		add(bg);

        text = new FlxText(10, 0, 0, '');
		text.setFormat(Main.globalFont, 48, 0xFFFFFFFF, LEFT);
		text.setOutline(0xFF000000, 3);
		add(text);
        drawText();
        text.y = FlxG.height - text.height - 10;

        title = new FlxText(10, 0, 0, 'DE-Pudim');
		title.setFormat(Main.globalFont, 100, 0xFFFFFFFF, LEFT);
		title.setOutline(0xFF000000, 5);
        title.y = text.y - title.height;
		add(title);

        ver = new FlxText(10, 0, 0, "Chart Converter");
		ver.setFormat(Main.globalFont, 32, 0xFFFFFFFF, LEFT);
		ver.setOutline(0xFF000000, 2.5);
        ver.x = title.x + title.width + 5;
        ver.y = text.y - ver.height;
		add(ver);
    }

    function drawText() {
        text.text = "";
        for(i in 0...options.length)
            text.text += options[i] + (i == cur ? " <\n" : "\n");
    }

    override function update(elapsed:Float)
	{
		super.update(elapsed);

        if(Controls.justPressed(UI_UP))
            changeSelection(-1);
        if(Controls.justPressed(UI_DOWN))
            changeSelection(1);

        if(Controls.justPressed(ACCEPT)) {
            switch(options[cur]) {
                case "FNF 2 Doido":
                    fnf2Doido();
                case "Doido 2 FNF":

            }
        }
    }

    function fnf2Doido() {
        var loader = new FileReference();
        var filter = new FileFilter("Legacy Charts", "*.json");
        var SONG:DoidoSong;

        function onSelect(e:Event):Void {
            loader.load();
        }

        function onComplete(e:Event):Void {
            var bytes = loader.data;
            var text = bytes.readUTFBytes(bytes.length);
            SONG = SongData.parseSong(TJSON.parse(text));

            var data:String = Json.stringify(SONG, "\t");
            if(data != null && data.length > 0)
            {
                var saver = new FileReference();
                saver.save(data.trim(), 'converted.json');
            }
        }

        function onError(e:IOErrorEvent):Void {
            trace("File load error");
        }

        loader.addEventListener(Event.SELECT, onSelect);
        loader.addEventListener(Event.COMPLETE, onComplete);
        loader.addEventListener(IOErrorEvent.IO_ERROR, onError);
        loader.browse([filter]);
    }

    public function changeSelection(change:Int = 0)
	{
		if(change != 0) FlxG.sound.play(Assets.sound('scroll'));
		
		cur += change;
		cur = FlxMath.wrap(cur, 0, options.length - 1);
		drawText();
	}
}

class DebugControls extends MusicBeatState
{
    public static var pad:Bool = false;
    var options:Array<DoidoKey> = [];
    var text:FlxText;
    var title:FlxText;
    var curV:Int = 0;
    var curH:Int = 0;

    override function create()
    {
        super.create();
        DiscordIO.changePresence("In the Controls Menu");
        var bg = new FlxSprite().loadGraphic(Assets.image('menuInvert'));
		add(bg);

        for (label => key in Controls.bindMap) {
            if(key.rebindable)
                options.push(label);
        }

        text = new FlxText(10, 0, 0, '');
		text.setFormat(Main.globalFont, 48, 0xFFFFFFFF, LEFT);
		text.setOutline(0xFF000000, 3);
		add(text);
        drawText();
        text.y = FlxG.height - text.height - 10;

        title = new FlxText(10, 0, 0, 'Controls');
		title.setFormat(Main.globalFont, 100, 0xFFFFFFFF, LEFT);
		title.setOutline(0xFF000000, 5);
        title.y = text.y - title.height;
		add(title);
    }

    function drawText() {
        text.text = "";
        for(i in 0...options.length) {
            var name:String = (cast options[i]).toUpperCase();
            var bind0:String = "";
            var bind1:String = "";

            if(pad) {
                bind0 = Controls.bindMap.get(options[i]).gamepad[0].toString();
                bind1 = Controls.bindMap.get(options[i]).gamepad[1].toString();
            }
            else {
                bind0 = Controls.bindMap.get(options[i]).keyboard[0].toString();
                bind1 = Controls.bindMap.get(options[i]).keyboard[1].toString();
            }

            bind0 = '${curH == 0 && curV == i ? "> " : ""}${Controls.formatKey(bind0, pad)}${curH == 0 && curV == i ? " <" : ""}';
            bind1 = '${curH == 1 && curV == i ? "> " : ""}${Controls.formatKey(bind1, pad)}${curH == 1 && curV == i ? " <" : ""}';

            text.text += '$name $bind0 $bind1\n';
        }

        // um bonus bem grande assim
        var name:String = "DEVICE";
        var bind0:String = "KEYBOARD";
        var bind1:String = "GAMEPAD";

        if(curV == options.length) {
            if(curH == 0)
                bind0 = '> $bind0 <';
            else
                bind1 = '> $bind1 <';
        }

        text.text += '$name $bind0 $bind1\n';
    }

    var waitingInput:Bool = false;
    override function update(elapsed:Float)
	{
		super.update(elapsed);

        if(waitingInput) {
            if(pad && FlxG.gamepads.lastActive.justPressed.ANY) {
                waitingInput = false;
                var daKey:FlxPad = FlxG.gamepads.lastActive.firstJustPressedID();

                if(FlxG.gamepads.lastActive.analog.value.LEFT_STICK_X < 0)
                    daKey = FlxPad.LEFT_STICK_DIGITAL_LEFT;
                if(FlxG.gamepads.lastActive.analog.value.LEFT_STICK_X > 0)
                    daKey = FlxPad.LEFT_STICK_DIGITAL_RIGHT;
                if(FlxG.gamepads.lastActive.analog.value.LEFT_STICK_Y < 0)
                    daKey = FlxPad.LEFT_STICK_DIGITAL_UP;
                if(FlxG.gamepads.lastActive.analog.value.LEFT_STICK_Y > 0)
                    daKey = FlxPad.LEFT_STICK_DIGITAL_DOWN;

                if(FlxG.gamepads.lastActive.analog.value.RIGHT_STICK_X < 0)
                    daKey = FlxPad.RIGHT_STICK_DIGITAL_LEFT;
                if(FlxG.gamepads.lastActive.analog.value.RIGHT_STICK_X > 0)
                    daKey = FlxPad.RIGHT_STICK_DIGITAL_RIGHT;
                if(FlxG.gamepads.lastActive.analog.value.RIGHT_STICK_Y < 0)
                    daKey = FlxPad.RIGHT_STICK_DIGITAL_UP;
                if(FlxG.gamepads.lastActive.analog.value.RIGHT_STICK_Y > 0)
                    daKey = FlxPad.RIGHT_STICK_DIGITAL_DOWN;

                Controls.bindMap.get(options[curV]).gamepad[curH] = daKey;
                Controls.save();
                drawText();
            }
            else if(FlxG.keys.justPressed.ANY) {
                waitingInput = false;
                var daKey:FlxKey = FlxG.keys.firstJustPressed();
                Controls.bindMap.get(options[curV]).keyboard[curH] = daKey;
                Controls.save();
                drawText();
            }   
        }
        else {
            if(Controls.justPressed(UI_UP))
                changeSelection(-1);
            if(Controls.justPressed(UI_DOWN))
                changeSelection(1);
            if(Controls.justPressed(UI_LEFT))
                changeBind(-1);
            if(Controls.justPressed(UI_RIGHT))
                changeBind(1);

            if(Controls.justPressed(ACCEPT)) {
                if(curV == options.length) {
                    pad = curH == 1;
                    MusicBeat.switchState(new DebugControls());
                }
                else
                    waitingInput = true;
            }
            if(Controls.justPressed(BACK))
			    MusicBeat.switchState(new states.DebugMenu());

        }
    }

    public function changeSelection(change:Int = 0)
	{
		if(change != 0) FlxG.sound.play(Assets.sound('scroll'));
		
		curV += change;
		curV = FlxMath.wrap(curV, 0, options.length);
		drawText();
	}

    public function changeBind(change:Int = 0)
	{
		if(change != 0) FlxG.sound.play(Assets.sound('scroll'));
		
		curH += change;
		curH = FlxMath.wrap(curH, 0, 1);
		drawText();
	}
}


//fodei
typedef Option = {
	var name:String;
	var get:Void->Dynamic;
	var set:Dynamic->Void;
}

class DebugOptions extends MusicBeatState
{
    var options:Array<Option> = [];
    var text:FlxText;
    var title:FlxText;
    var cur:Int = 0;

    override function create()
    {
        super.create();
        DiscordIO.changePresence("In the Options Menu");

        var bg = new FlxSprite().loadGraphic(Assets.image('menuInvert'));
		add(bg);

        options = [
            #if desktop
            {
                name: "FPS Counter",
                get: () -> Save.data.fpsCounter,
                set: (b:Bool) -> Save.data.fpsCounter = b
            },
            {
                name: "FPS",
                get: () -> Save.data.fps,
                set: (i:Int) -> Save.data.fps = FlxMath.wrap(i, 30, 144)
            },
            {
                name: "GPU Caching",
                get: () -> Save.data.gpuCaching,
                set: (b:Bool) -> Save.data.gpuCaching = b
            },
            #end
            {
                name: "Antialiasing",
                get: () -> Save.data.antialiasing,
                set: (b:Bool) -> Save.data.antialiasing = b
            },
        ];

        text = new FlxText(10, 0, 0, '');
		text.setFormat(Main.globalFont, 48, 0xFFFFFFFF, LEFT);
		text.setOutline(0xFF000000, 3);
		add(text);
        drawText();
        text.y = FlxG.height - text.height - 10;

        title = new FlxText(10, 0, 0, 'Options');
		title.setFormat(Main.globalFont, 100, 0xFFFFFFFF, LEFT);
		title.setOutline(0xFF000000, 5);
        title.y = text.y - title.height;
		add(title);
    }

    function drawText() {
        text.text = "";
        for(i in 0...options.length)
            text.text += '${options[i].name} ${options[i].get()} ${(i == cur ? "<\n" : "\n")}';
    }

    var holdTimer:Float = 0;
    override function update(elapsed:Float)
	{
		super.update(elapsed);

        if(Controls.justPressed(UI_UP))
            changeSelection(-1);
        if(Controls.justPressed(UI_DOWN))
            changeSelection(1);

        if(Controls.justPressed(BACK))
			MusicBeat.switchState(new states.DebugMenu());

        var holdMax:Float = 0.4;
        if(Controls.justPressed(UI_LEFT) || Controls.justPressed(UI_RIGHT) || holdTimer >= holdMax)
        {
            var selChange:Int = -(Controls.pressed(UI_LEFT) ? 1 : 0) + (Controls.pressed(UI_RIGHT) ? 1 : 0);
            if(selChange != 0)
                changeOption(selChange);

            if(holdTimer >= holdMax)
                holdTimer = holdMax - 0.005; // 0.02
        }

        if(Controls.pressed(UI_LEFT) || Controls.pressed(UI_RIGHT) && holdTimer <= holdMax)
            holdTimer += elapsed;
        if(Controls.released(UI_LEFT) || Controls.released(UI_RIGHT))
            holdTimer = 0;
    }

    public function changeSelection(change:Int = 0)
	{
		if(change != 0) FlxG.sound.play(Assets.sound('scroll'));
		
		cur += change;
		cur = FlxMath.wrap(cur, 0, options.length - 1);
		drawText();
	}

    public function changeOption(change:Int = 0)
    {
        if(change != 0) FlxG.sound.play(Assets.sound('scroll'));
		
		var option = options[cur];
        if(Std.isOfType(option.get(), Int)) {
            option.set(option.get()+change);
        }
        else if(Std.isOfType(option.get(), Bool)) {
            option.set(!option.get());
        }
        Save.save();
		drawText();
    }
}