package states;

import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.math.FlxMath;

using doido.utils.TextUtil;

class DebugMenu extends MusicBeatState
{
    var options:Array<String> = ["PlayState", "Options"];
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