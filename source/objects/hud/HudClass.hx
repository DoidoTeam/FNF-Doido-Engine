package objects.hud;

import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import backend.song.Conductor;
import states.PlayState;

enum IconChange {
    PLAYER;
    ENEMY;
}
class HudClass extends FlxGroup
{
    public var hudName:String = "";

    var separator:String = " | ";
	public var health:Float = 1;
    public var songTime:Float = 0.0;
    public var downscroll:Bool = false;

    public var ratingGrp:FlxGroup;

    public var alpha(default, set):Float = 1.0;
    // sprites that get affected by the alpha
    public var alphaList:Array<FlxSprite> = [];

    public function set_alpha(v:Float):Float
    {
        alpha = v;
        for(item in alphaList)
            if(item != null)
                item.alpha = alpha;
        return alpha;
    }

	public function new(hudName:String)
	{
		super();
        this.hudName = hudName;
        ratingGrp = new FlxGroup();
		health = PlayState.health;
        songTime = 0;
	}

	public function updateInfoTxt() {}
	
	public function updateTimeTxt()
    {
		songTime = FlxMath.bound(Conductor.songPos, 0, PlayState.songLength);
	}

    public function addRating(rating:Rating)
    {
        ratingGrp.add(rating);
    }

	public function changeIcon(newIcon:String = "face", type:IconChange = ENEMY) {}

    public function stepHit(curStep:Int = 0) {}
	public function beatHit(curBeat:Int = 0) {}

    public function enableTimeTxt(enabled:Bool) {}

    public function updatePositions()
    {
        updateInfoTxt();
        updateTimeTxt();
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        health = FlxMath.lerp(health, PlayState.health, elapsed * 8);
        if(Math.abs(health - PlayState.health) <= 0.00001)
            health = PlayState.health;
        updateTimeTxt();
    }
}