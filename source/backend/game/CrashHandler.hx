package backend.game;

import openfl.media.Sound;
import openfl.media.SoundChannel;
import openfl.media.SoundTransform;
import openfl.display.Stage;
import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.Assets;
import openfl.ui.Keyboard;
import openfl.events.KeyboardEvent;
import openfl.text.TextFormat;
import openfl.text.TextField;
import openfl.display.Sprite;

class CrashHandler extends Sprite
{
    var _stage:Stage;
    var imgData:BitmapData;

    var crashSnd:Sound;
    var trans:SoundTransform;
    var channel:SoundChannel;

    var fontSize:Int = 24;
    var showBuddy:Bool = true;
    public function new(stack:String, ?path:String = "")
    {
        super();
        _stage = openfl.Lib.application.window.stage;

        var windowSize:Int = CoolUtil.stringToInt((SaveData.data.get("Window Size").split("x")[1]));

        fontSize = Std.int((windowSize / 30));
        trace(fontSize);

        final _matrix = new flixel.math.FlxMatrix().rotateByPositive90();
		graphics.beginGradientFill(LINEAR, [0xFF38173F, 0xFF733A8D], [0.6, 1], [125, 255], _matrix);
        graphics.drawRect(0, 0, _stage.stageWidth, _stage.stageHeight);
        graphics.endFill();

        var errorField = new TextField();
        var pressField = new TextField();
        for(field in [errorField, pressField])
        {
            field.defaultTextFormat = new TextFormat(
                Main.gFont, fontSize, 0xFFFFFFFF, true
            );
            field.selectable = false;
            field.multiline = true;
            if(field != pressField) {
                field.wordWrap = true;
                field.width = _stage.stageWidth - 48;
            }
            field.autoSize = CENTER;
        }
        errorField.x = (_stage.stageWidth - errorField.width) / 2;
        errorField.text = 'THE GAME HAS CRASHED\n\n${stack}';
        #if sys
        errorField.text += '\n\nCrash log created at: "${path}"';
        #end
        errorField.y = fontSize;

        pressField.text = 'Press ESCAPE to return to main menu\nPress ENTER to open github issues';
        pressField.x = (_stage.stageWidth - pressField.width) - fontSize;
        pressField.y = _stage.stageHeight - pressField.height - fontSize;

        imgData = Assets.getBitmapData("assets/images/crash.png");
        var crashImg = new Bitmap(imgData);
        crashImg.width = crashImg.width * (windowSize / 720);
        crashImg.height = crashImg.height * (windowSize / 720);
        crashImg.x = (_stage.stageWidth - crashImg.width) - fontSize;// / 2;
        crashImg.y = (_stage.stageHeight- crashImg.height - pressField.height - 32);

        if(showBuddy)
            addChild(crashImg);

        addChild(errorField);
        addChild(pressField);

        if(!SaveData.saveSettings.data.muted) {
            crashSnd = Assets.getSound("assets/sounds/crash.ogg", false);
            trans = new SoundTransform(SaveData.saveSettings.data.volume, 0);
            channel = crashSnd.play(0, 1, trans);
        }
        
        openfl.Lib.application.window.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
    }
    
    /*override function __enterFrame(deltaTime:Int)
    {
        super.__enterFrame(deltaTime);
    }*/

    public function onKeyPress(e:KeyboardEvent):Void
    {
        if(e.keyCode == Keyboard.ESCAPE)
        {
            imgData.dispose();
            crashSnd.close();
            openfl.Lib.application.window.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
            if(Main.instance != null && Main.instance.contains(this))
                Main.instance.removeChild(this);

            @:privateAccess
            Main.instance.game._viewingCrash = false;
            
            FlxG.switchState(new states.menu.MainMenuState());
        }
        if(e.keyCode == Keyboard.ENTER)
        {
            FlxG.openURL('https://github.com/DoidoTeam/FNF-Doido-Engine/issues');
        }
    }
}