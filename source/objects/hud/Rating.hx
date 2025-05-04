package objects.hud;

import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import backend.song.Conductor;

using StringTools;

class Rating extends FlxGroup
{
	var daRating:RatingFNF;
	var daNum:NumberFNF;

	var tweens:Array<FlxTween> = [];

	public var ratingScale:Float = 1.0; // scale multiplier
	public var numberScale:Float = 1.0; // scale multiplier
	public var numberOffset:FlxPoint = new FlxPoint(0,0); // global offset for numbers
	public var numberSpace:Float = 0.0; // space between each number

	public var assetModifier:String = "base";
	
	public function new(rating:String, combo:Int, assetModifier:String = "base")
	{
		super();
		this.assetModifier = assetModifier;
		daRating = new RatingFNF(rating, assetModifier);
		add(daRating);
		
		daNum = new NumberFNF(combo, assetModifier);
		add(daNum);
		
		// RED
		if(combo < 0)
			daNum.color = 0xFFFF0000;

		switch(assetModifier)
		{
			case "pixel":
				numberSpace = 0.8;
				numberOffset.y = -1.6;
			default:
				numberSpace = 24;
				numberOffset.y = -42;
		}
		
		setPos();
	}

	public function playRating()
	{
		var single:Bool = SaveData.data.get("Single Rating");

		if(!single)
		{
			daRating.acceleration.y = 550;
			daRating.velocity.y 	= -FlxG.random.int(140, 175);
			daRating.velocity.x 	= FlxG.random.int(-10, 10);
		}
		else
		{
			jumpTween(daRating);
		}
		deathTween(daRating, 0.3);
		for(item in daNum)
		{
			if(!single)
			{
				item.acceleration.y = FlxG.random.int(200, 300);
				item.velocity.y 	= -FlxG.random.int(140, 160);
				item.velocity.x 	= FlxG.random.int(-5, 5);
			}
			else
			{
				jumpTween(item, FlxG.random.float(0, 0.25));
			}
			deathTween(item, FlxG.random.float(0.2, 0.8));
		}
	}
	
	public function setPos(x:Float = 0, y:Float = 0)
	{
		daRating.scale.set(
			daRating.mainScale * ratingScale,
			daRating.mainScale * ratingScale
		);
		daRating.updateHitbox();
		for(item in daNum)
		{
			item.scale.set(
				daNum.mainScale * ratingScale,
				daNum.mainScale * ratingScale
			);
			item.updateHitbox();
		}

		daRating.x = x - daRating.width / 2;
		daRating.y = y - daRating.height / 2;
		
		var center:Float = daRating.x + daRating.width / 2;
		for(item in daNum)
		{
			var formatOffset = numberSpace * item.scale.x;

			item.x = center + ((item.width - formatOffset) * item.ID);
			item.y = daRating.y + daRating.height + (numberOffset.y * item.scale.y);
			item.x += numberOffset.x * item.scale.x;
		}
		
		var lastItem = daNum.members[daNum.members.length - 1];
		var shitLength:Float = lastItem.x + lastItem.width - daNum.members[0].x;
		
		for(item in daNum)
			item.x -= shitLength / 2;
	}

	// makes the thing do a little jump
	public function jumpTween(item:FlxSprite, timeOffset:Float = 0.0)
	{
		var scaleOffset = FlxG.random.bool(50) ? -0.2 : 0.2;
		var prevScale = [item.scale.x, item.scale.y];
		item.scale.x *= 1.0 + scaleOffset;
		item.scale.y *= 1.0 - scaleOffset;
		tweens.push(FlxTween.tween(item.scale, {x: prevScale[0], y: prevScale[1]}, 0.15 + timeOffset, {ease: FlxEase.cubeOut}));
	}
	
	// KILLS the poor thing :[
	public function deathTween(item:FlxSprite, delayTime:Float = 0)
	{
		var daTween = FlxTween.tween(item, {alpha: 0}, Conductor.crochet / 1000, {
			startDelay: delayTime,
			onComplete: function(twn:FlxTween)
			{
				item.destroy();
			}
		});
		tweens.push(daTween);
	}
	
	public static function preload(assetModifier:String = "base"):Void
	{
		var ratingMod:String = assetModifier;
		var numberMod:String = assetModifier;
		
		function checkExist(filePath:String):Bool
			return Paths.fileExists('images/hud/$assetModifier/$filePath.png');
		
		if(!checkExist('ratings')) ratingMod = "base";
		if(!checkExist('numbers')) numberMod = "base";
		
		Paths.preloadGraphic('hud/$ratingMod/ratings');
		Paths.preloadGraphic('hud/$numberMod/numbers');
	}

	override public function kill()
	{
		for(tween in tweens)
			if(tween != null)
				tween.cancel();

		for(item in members)
			if(item != null)
				item.kill();

		super.kill();
	}
}

/*
*	in case you want to spawn them individually for some reason
*/
class RatingFNF extends FlxSprite
{
	public var mainScale:Float = 1.0;

	public function new(rating:String, assetModifier:String = "base")
	{
		super();
		if(!Paths.fileExists('images/hud/$assetModifier/ratings.png'))
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
				mainScale = 0.7;
			case "pixel":
				antialiasing = false;
				isPixelSprite = true;
				mainScale = 5;
		}
		updateHitbox();
	}
}

class NumberFNF extends FlxSpriteGroup
{
	public var mainScale:Float = 1.0;

	public function new(number:Int, assetModifier:String = "base")
	{
		super();
		if(!Paths.fileExists('images/hud/$assetModifier/numbers.png'))
			assetModifier = "base";

		var stringNum = Std.string(number);
		if(number > 0)
		{
			stringNum = stringNum.lpad('0', 3);
		}

		var numArray:Array<String> = stringNum.split("");
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
					mainScale = 0.5;
				case "pixel":
					num.antialiasing = false;
					num.isPixelSprite = true;
					mainScale = 5;
			}
		}
	}
}