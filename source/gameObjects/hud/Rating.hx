package gameObjects.hud;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import data.Conductor;
import sys.FileSystem;

using StringTools;

class Rating extends FlxGroup
{
	var daRating:RatingFNF;
	var daNum:NumberFNF;
	
	public function new(rating:String, combo:Int, assetModifier:String = "base")
	{
		super();
		daRating = new RatingFNF(rating, assetModifier);
		add(daRating);
		
		daNum = new NumberFNF(combo, assetModifier);
		add(daNum);
		
		// RED
		if(combo < 0)
			daNum.color = 0xFFFF0000;
		
		setPos();
		
		daRating.acceleration.y = 550;
		daRating.velocity.y 	= -FlxG.random.int(140, 175);
		daRating.velocity.x 	= FlxG.random.int(-10, 10);
		
		deathTween(daRating, Conductor.crochet / 1000);
		for(item in daNum)
		{
			item.acceleration.y = FlxG.random.int(200, 300);
			item.velocity.y 	= -FlxG.random.int(140, 160);
			item.velocity.x 	= FlxG.random.int(-5, 5);
			
			deathTween(item, (Conductor.crochet / 1000) + FlxG.random.int(0, 3) * 0.3);
		}
	}
	
	public function setPos(x:Float = 0, y:Float = 0)
	{
		daRating.x = x - daRating.width / 2;
		daRating.y = y - daRating.height / 2;
		
		var center:Float = daRating.x + daRating.width / 2;
		for(item in daNum)
		{
			item.x = center + ((item.width - 12) * item.ID);
			item.y = daRating.y + daRating.height - 18;
		}
		
		var lastItem = daNum.members[daNum.members.length - 1];
		var shitLength:Float = lastItem.x + lastItem.width - daNum.members[0].x;
		
		for(item in daNum)
			item.x -= shitLength / 2;
	}
	
	// KILLS the poor thing :[
	public function deathTween(item:FlxSprite, delayTime:Float = 0)
	{
		FlxTween.tween(item, {alpha: 0}, Conductor.crochet / 1000, {
			startDelay: delayTime,
			onComplete: function(twn:FlxTween)
			{
				item.destroy();
			}
		});
	}
	
	public static function preload(assetModifier:String = "base"):Void
	{
		var ratingMod:String = assetModifier;
		var numberMod:String = assetModifier;
		
		function checkExist(filePath:String):Bool
			return FileSystem.exists(Paths.getPath('images/hud/$assetModifier/$filePath.png'));
		
		if(!checkExist('ratings')) ratingMod = "base";
		if(!checkExist('numbers')) numberMod = "base";
		
		Paths.preloadGraphic('hud/$ratingMod/ratings');
		Paths.preloadGraphic('hud/$numberMod/numbers');
	}
}
/*
*	in case you want to spawn them individually for some reason
*/
class RatingFNF extends FlxSprite
{
	public function new(rating:String, assetModifier:String = "base")
	{
		super();
		if(!FileSystem.exists(Paths.getPath('images/hud/$assetModifier/ratings.png')))
			assetModifier = "base";
		
		var daGraph = Paths.image('hud/$assetModifier/ratings');
		loadGraphic(daGraph, true, Math.floor(daGraph.width), Math.floor(daGraph.height / 4));
		
		var ratingNum:Int = ["sick", "good", "bad", "shit"].indexOf(rating);
		
		if(ratingNum == -1)
		{
			ratingNum = 0;
			visible = false;
		}
		
		animation.add(rating, [ratingNum], 0, false);
		animation.play(rating);
		
		antialiasing = FlxSprite.defaultAntialiasing;
		isPixelSprite = false;
		
		switch(assetModifier)
		{
			default:
				scale.set(0.7,0.7);
			case "pixel":
				antialiasing = false;
				isPixelSprite = true;
				scale.set(5,5);
		}
		updateHitbox();
	}
}
class NumberFNF extends FlxSpriteGroup
{
	public function new(number:Int, assetModifier:String = "base")
	{
		super();
		if(!FileSystem.exists(Paths.getPath('images/hud/$assetModifier/numbers.png')))
			assetModifier = "base";
		
		var numArray:Array<String> = Std.string(number).split("");
		var count:Int = 0;
		for(i in numArray)
		{
			var num = new FlxSprite();
			var numGraph = Paths.image('hud/$assetModifier/numbers');
			num.loadGraphic(numGraph, true, Math.floor(numGraph.width / 11), Math.floor(numGraph.height));
			
			var realNum:Int = switch(i)
			{
				default: Std.parseInt(i);
				case "-": 10;
			};
			
			num.animation.add(i, [realNum], 0, false);
			
			num.animation.play(i);
			add(num);
			
			num.ID = count;
			count++;

			num.antialiasing = FlxSprite.defaultAntialiasing;
			num.isPixelSprite = false;
			
			switch(assetModifier)
			{
				default:
					num.scale.set(0.5,0.5);
				case "pixel":
					num.antialiasing = false;
					num.isPixelSprite = true;
					num.scale.set(5,5);
			}
			num.updateHitbox();
		}
	}
}