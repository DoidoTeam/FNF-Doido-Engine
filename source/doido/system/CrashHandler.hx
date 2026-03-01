package doido.system;

import flixel.text.FlxText;
import flixel.FlxSprite;
import flixel.util.FlxGradient;

using doido.utils.TextUtil;

/*
	State that is displayed when the game crashes
*/
class CrashHandler extends MusicBeatState
{
    var errorMsg:String = "";

    public function new(errorMsg:String)
    {
        super();
        this.errorMsg = errorMsg;
    }

    override function create()
    {
        super.create();
        var bg = new FlxSprite().loadGraphic(Assets.image('menuInvert'));
        bg.screenCenter();
        bg.alpha = 0.4;
        add(bg);

        var gradient = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0xFF38173F, 0xFF924DB2]);
        gradient.blend = ADD;
        add(gradient);

        var titleTxt = new FlxText(0, 16, 0, "THE GAME HAS CRASHED!!");
        titleTxt.setFormat(Main.globalFont, 36, 0xFFFFFFFF, CENTER);
        titleTxt.antialiasing = false;
        titleTxt.screenCenter(X);
        titleTxt.floorPos();
        add(titleTxt);

        var errorTxt = new FlxText(24,titleTxt.y + titleTxt.height + 16, FlxG.width - 24, errorMsg);
        errorTxt.setFormat(Main.globalFont, 24, 0xFFFFFFFF, LEFT);
        errorTxt.antialiasing = false;
        errorTxt.floorPos();
        add(errorTxt);

        var infoTxt = new FlxText(24, 0, 'Press ESCAPE to return to main menu\nPress F1 to open github issues');
        infoTxt.setFormat(Main.globalFont, 24, 0xFFFFFFFF, RIGHT);
        infoTxt.x = FlxG.width - infoTxt.width - 16;
        infoTxt.y = FlxG.height- infoTxt.height - 16;
        infoTxt.antialiasing = false;
        infoTxt.floorPos();
        add(infoTxt);

        var buddy = new FlxSprite().loadGraphic(Assets.image('crash'));
        buddy.x = FlxG.width - buddy.width - 16;
        buddy.y = infoTxt.y - buddy.height - 16;
        add(buddy);

        FlxG.sound.play(Assets.sound('crash'));
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        if(FlxG.keys.justPressed.ANY)
        {
            if(FlxG.keys.justPressed.ESCAPE)
            {
                MusicBeat.skipTrans = true;
                MusicBeat.switchState(new states.DebugMenu());
            }
            if(FlxG.keys.justPressed.F1)
            {
                FlxG.openURL('https://github.com/DoidoTeam/FNF-Doido-Engine/issues');
            }
        }
    }
}