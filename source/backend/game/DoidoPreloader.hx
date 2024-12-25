package backend.game;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.BlendMode;
import openfl.display.Sprite;
import openfl.display.Stage;
import openfl.geom.Rectangle;
import flixel.math.FlxMath;
import flixel.system.FlxBasePreloader;

@:keep @:bitmap("assets/images/doido_logo.png")
private class DoidoLogo extends BitmapData {}

class DoidoPreloader extends FlxBasePreloader
{
    var _stage:Stage;
    var imgData:DoidoLogo;

    var logo:Bitmap;
    var loadBar:Sprite;

	override function create():Void
	{
        _stage = openfl.Lib.application.window.stage;

		logo = createBitmap(DoidoLogo, function(logo:Bitmap){
            logo.width = logo.width * 0.45;
            logo.height = logo.height * 0.45;
            logo.x = (_stage.stageWidth - logo.width) / 2;
            logo.y = (_stage.stageHeight - logo.height) / 2;
            logo.alpha = 0;
        });
        addChild(logo);

        loadBar = new Sprite();
        loadBar.graphics.beginFill(0xFFFFFF);
        loadBar.graphics.drawRect(0, 0, 1, 1);

        loadBar.height = 20 - 8;
        loadBar.y = _stage.stageHeight - loadBar.height - 8;
        changeBarSize(0);

        addChild(loadBar);
        
		super.create();
	}

    override function destroy():Void
    {
        _stage = null;
        imgData = null;
        logo = null;
        loadBar = null;
        super.destroy();
    }

	override public function update(percent:Float):Void
	{
        var newSize = (_stage.stageWidth - 16) * percent;
        changeBarSize(FlxMath.lerp(loadBar.width, newSize, 0.7));

        if(percent < 0.3)
            logo.alpha = FlxMath.lerp(percent*(10/3), logo.alpha, 0.7);
        else if(percent > 0.85)
            logo.alpha = FlxMath.lerp(((1-percent)*(100/15)), logo.alpha, 0.7);
        else
            logo.alpha = 1;
	}

    function changeBarSize(newSize:Float)
    {
        loadBar.width = newSize;
        loadBar.x = (_stage.stageWidth - loadBar.width) / 2;
    }
}