package objects.hud;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import states.PlayState;

class DoidoBar extends FlxSpriteGroup
{
    public var border:FlxSprite;

    public var sideL:FlxSprite;
    public var sideR:FlxSprite; 
    public var percent(default, set):Float = 0;

    public function set_percent(v:Float)
    {
        percent = v;
        if(sideL != null && sideR != null)
        {
            var rectL = FlxRect.get(
                0, 0,
                FlxMath.lerp(sideL.frameWidth, 0, percent / 100),
                sideL.frameHeight
            );
            sideL.clipRect = rectL; 
            var rectR = FlxRect.get(
                FlxMath.lerp(sideR.frameWidth, 0, percent / 100),
                0, sideR.frameWidth, sideR.frameHeight
            );
            sideR.clipRect = rectR;
        }
        return percent;
    }

    public function new(?x:Float = 0, ?y:Float = 0, barFile:String, ?borderFile:String, ?startPercent:Float = 50)
    {
    	super(x, y);
        percent = startPercent;

        sideR = new FlxSprite();
    	sideR.loadGraphic(Paths.image(barFile));
    	sideL = new FlxSprite();
    	sideL.loadGraphic(Paths.image(barFile));
    
    	add(sideR);
    	add(sideL);
        if(borderFile != null)
        {
            border = new FlxSprite().loadGraphic(Paths.image(borderFile));
            add(border);
        }
    }
}