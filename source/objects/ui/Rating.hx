package objects.ui;

import doido.song.Conductor;
import flixel.FlxSprite;
import flixel.tweens.FlxTween;

class RatingSprite extends FlxSprite
{
    static final ratingArray:Array<String> = ["sick", "good", "bad", "shit"];

    public var baseScale:Float = 1.0;

    public function new(assetPath:String = "base")
    {
        super();
        switch(assetPath)
        {
            default:
                baseScale = 0.7;
        }
        
        var ratingGraph = Assets.image('hud/$assetPath/ratings');
        loadGraphic(
            ratingGraph, true,
            Math.floor(ratingGraph.width),
            Math.floor(ratingGraph.height / 4)    
        );
        for(i in 0...ratingArray.length)
            animation.add(ratingArray[i], [i], 0, false);
        setUp(ratingArray[0]);
    }

    public function setUp(animName:String)
    {
        acceleration.set(0, 0);
        velocity.set(0, 0);
        scale.set(baseScale, baseScale);
        updateHitbox();
        alpha = 1.0;

        animation.play(animName);
    }

    public function defaultAnim()
    {
        screenCenter();
        velocity.set(
            FlxG.random.int(-10, 10),
            FlxG.random.int(-140, -175)
        );
        acceleration.y = 550;

        FlxTween.tween(this, {alpha: 0.0}, Conductor.crochet / 1000, {
            startDelay: 0.3,
            onComplete: (twn) -> {
                kill(); // KILL YOURSELF
            }
        });
    }
}

class ComboSprite extends FlxSprite
{
    public var baseScale:Float = 1.0;
    public var badColor:Int = 0xFF828282;

    public function new(assetPath:String = "base")
    {
        super();
        switch(assetPath)
        {
            default:
                baseScale = 0.5;
                badColor = 0xFF828282;
        }
        
        var numberGraph = Assets.image('hud/$assetPath/numbers');
        loadGraphic(
            numberGraph, true,
            Math.floor(numberGraph.width / 11),
            Math.floor(numberGraph.height)
        );
        for(i in 0...11)
            animation.add((i <= 9 ? '$i' : "-"), [i], 0, false);
        setUp("0");
    }

    public function setUp(animName:String)
    {
        acceleration.set(0, 0);
        velocity.set(0, 0);
        scale.set(baseScale, baseScale);
        updateHitbox();
        alpha = 1.0;

        color = 0xFFFFFFFF;
        
        animation.play(animName);
    }

    public function defaultAnim()
    {
        velocity.set(
            FlxG.random.int(-5, 5),
            FlxG.random.int(-140, -160)
        );
        acceleration.y = FlxG.random.int(200, 300);

        FlxTween.tween(this, {alpha: 0.0}, Conductor.crochet / 1000, {
            startDelay: FlxG.random.float(0.2, 0.8),
            onComplete: (twn) -> {
                kill(); // JK DON'T KILL YOURSELF
            }
        });
    }
}