package backend.game;

import flixel.text.FlxText;
import backend.game.MusicBeatData.MusicBeatState;
import flixel.FlxSprite;
import flixel.util.FlxGradient;

/*
	State that is displayed when the game crashes
*/

class CrashHandlerState extends MusicBeatState
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

        var bg = new FlxSprite().loadGraphic(Paths.image('menu/backgrounds/menuInvert'));
        bg.screenCenter();
        bg.alpha = 0.4;
        add(bg);

        var gradient = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0xFF38173F, 0xFF924DB2]);
        gradient.blend = ADD;
        add(gradient);

        var titleTxt = new FlxText(0, 16, 0, "THE GAME HAS CRASHED!!");
        titleTxt.setFormat(Main.gFont, 36, 0xFFFFFFFF, CENTER);
        titleTxt.screenCenter(X);
        add(titleTxt);

        var errorTxt = new FlxText(24,titleTxt.y + titleTxt.height + 16, FlxG.width - 24, errorMsg);
        errorTxt.setFormat(Main.gFont, 24, 0xFFFFFFFF, LEFT);
        add(errorTxt);

        var infoTxt = new FlxText(24, 0, 'Press ESCAPE to return to main menu\nPress ENTER to open github issues');
        infoTxt.setFormat(Main.gFont, 24, 0xFFFFFFFF, RIGHT);
        infoTxt.x = FlxG.width - infoTxt.width - 16;
        infoTxt.y = FlxG.height- infoTxt.height - 16;
        add(infoTxt);

        var buddy = new FlxSprite().loadGraphic(Paths.image('crash'));
        buddy.x = FlxG.width - buddy.width - 16;
        buddy.y = infoTxt.y - buddy.height - 16;
        add(buddy);

        FlxG.sound.play(Paths.sound('crash'));
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        if(FlxG.keys.justPressed.ANY)
        {
            if(FlxG.keys.justPressed.ESCAPE)
            {
                Main.skipTrans = true;
                Main.switchState(new states.menu.MainMenuState());
            }
            if(FlxG.keys.justPressed.ENTER)
            {
                FlxG.openURL('https://github.com/DoidoTeam/FNF-Doido-Engine/issues');
            }
        }
    }
}