package objects.ui;

import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup;
import flixel.FlxSprite;

class RatingSprite extends FlxSprite
{
    static final ratingArray:Array<String> = ["sick", "good", "bad", "shit"];

    public var baseScale:Float = 1.0;

    public function new(assetPath:String = "base") {
        super();
        switch(assetPath)
        {
            default:
                baseScale = 0.7;
                var ratingGraph = Assets.image('hud/$assetPath/ratings');
                loadGraphic(
                    ratingGraph, true,
                    Math.floor(ratingGraph.width),
                    Math.floor(ratingGraph.height / 4)    
                );
                for(i in 0...ratingArray.length)
                    animation.add(ratingArray[i], [i], 0, false);
        }
        
        animation.play(ratingArray[0]);
        setUp();
    }

    public function setUp()
    {
        acceleration.set(0, 0);
        velocity.set(0, 0);
        scale.set(baseScale, baseScale);
        updateHitbox();
        alpha = 1.0;
    }

    public function playAnim(animName:String)
    {
        animation.play(animName);
        ratingAnimation();
    }

    public dynamic function ratingAnimation()
    {
        screenCenter();
        velocity.set(
            FlxG.random.int(-50, 50),
            FlxG.random.int(-100, -200)
        );
        acceleration.y = FlxG.random.int(200, 300);

        FlxTween.tween(this, {alpha: 0.0}, 0.1, {
            startDelay: 0.8,
            onComplete: (twn) -> {
                kill(); // KILL YOURSELF
            }
        });
    }
}
class ComboSprite extends FlxSpriteGroup
{

}