package gameObjects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;

using StringTools;

class Character extends FlxSprite
{
	public function new() {
		super();
	}

	public var curChar:String = "bf";
	public var isPlayer:Bool = false;

	public var holdTimer:Float = 0;
	public var holdLength:Float = 1;

	public var singAnims:Array<String> = [];
	public var missAnims:Array<String> = [];

	public var globalOffset:FlxPoint = new FlxPoint();
	public var cameraOffset:FlxPoint = new FlxPoint();
	private var scaleOffset:FlxPoint = new FlxPoint();

	public function reloadChar(curChar:String = "bf", isPlayer:Bool = false):Character
	{
		this.curChar = curChar;
		this.isPlayer = isPlayer;

		holdLength = 1;
		addSingPrefix(); // none

		var storedPos:Array<Float> = [x, y];
		globalOffset.set();
		cameraOffset.set();

		// what
		switch(curChar)
		{
			case "gemamugen":
				frames = Paths.getSparrowAtlas("characters/gemamugen/gemamugen");

				animation.addByPrefix('idle', 		'idle', 24, true);
				animation.addByPrefix('idle-alt',	'chacharealsmooth', 24, true);
				animation.addByPrefix('singLEFT', 	'left', 24, false);
				animation.addByPrefix('singDOWN', 	'down', 24, false);
				animation.addByPrefix('singUP', 	'up', 24, false);
				animation.addByPrefix('singRIGHT', 	'right', 24, false);

				addOffset('idle');
				addOffset('idle-alt',	-30,	0.5);
				addOffset('singLEFT',	114.5, 	-7);
				addOffset('singDOWN',	-1,	 	-5);
				addOffset('singUP',		-0.5,	152);
				addOffset('singRIGHT',	30,  	-4.5);

				playAnim('idle');

				scale.set(2,2);
				globalOffset.x = -300;
				cameraOffset.y = -180;

			case "bf-pixel":
				frames = Paths.getSparrowAtlas("characters/bf-pixel/bfPixel");

				animation.addByPrefix('idle', 'BF IDLE', 24, false);
				animation.addByPrefix('singUP', 'BF UP NOTE', 24, false);
				animation.addByPrefix('singLEFT', 'BF LEFT NOTE', 24, false);
				animation.addByPrefix('singRIGHT', 'BF RIGHT NOTE', 24, false);
				animation.addByPrefix('singDOWN', 'BF DOWN NOTE', 24, false);
				animation.addByPrefix('singUPmiss', 'BF UP MISS', 24, false);
				animation.addByPrefix('singLEFTmiss', 'BF LEFT MISS', 24, false);
				animation.addByPrefix('singRIGHTmiss', 'BF RIGHT MISS', 24, false);
				animation.addByPrefix('singDOWNmiss', 'BF DOWN MISS', 24, false);

				playAnim('idle');

				flipX = true;
				antialiasing = false;
				scale.set(6,6);

			case "bf":
				frames = Paths.getSparrowAtlas("characters/bf/BOYFRIEND");

				var leftright = ["LEFT", "RIGHT"];
				if(!isPlayer)
					leftright.reverse();

				animation.addByPrefix('idle', 'BF idle dance', 24, false);
				animation.addByPrefix('singUP', 'BF NOTE UP0', 24, false);
				animation.addByPrefix('sing${leftright[0]}', 'BF NOTE LEFT0', 24, false);
				animation.addByPrefix('sing${leftright[1]}', 'BF NOTE RIGHT0', 24, false);
				animation.addByPrefix('singDOWN', 'BF NOTE DOWN0', 24, false);
				animation.addByPrefix('singUPmiss', 'BF NOTE UP MISS', 24, false);
				animation.addByPrefix('sing${leftright[0]}miss', 'BF NOTE LEFT MISS', 24, false);
				animation.addByPrefix('sing${leftright[1]}miss', 'BF NOTE RIGHT MISS', 24, false);
				animation.addByPrefix('singDOWNmiss', 'BF NOTE DOWN MISS', 24, false);
				animation.addByPrefix('hey', 'BF HEY', 24, false);

				animation.addByPrefix('firstDeath', "BF dies", 24, false);
				animation.addByPrefix('deathLoop', "BF Dead Loop", 24, true);
				animation.addByPrefix('deathConfirm', "BF Dead confirm", 24, false);

				animation.addByPrefix('scared', 'BF idle shaking', 24);

				addOffset('idle', -5);
				addOffset("singUP", -29, 27);
				addOffset("singRIGHT", -38, -7);
				addOffset("singLEFT", 12, -6);
				addOffset("singDOWN", -10, -50);
				addOffset("singUPmiss", -29, 27);
				addOffset("singRIGHTmiss", -30, 21);
				addOffset("singLEFTmiss", 12, 24);
				addOffset("singDOWNmiss", -11, -19);
				addOffset("hey", 7, 4);
				addOffset('firstDeath', 37, 11);
				addOffset('deathLoop', 37, 5);
				addOffset('deathConfirm', 37, 69);
				addOffset('scared', -4);

				playAnim('idle');

				flipX = true;

				/*if(!isPlayer)
				{
					singAnims = ["firstDeath", "firstDeath", "firstDeath", "firstDeath"];
				}*/

			default:
				return reloadChar("bf", isPlayer);
		}

		updateHitbox();
		scaleOffset.set(offset.x, offset.y);

		if(isPlayer)
			flipX = !flipX;

		dance();

		setPosition(storedPos[0], storedPos[1]);

		return this;
	}

	public function addSingPrefix(prefix:String = "")
	{
		singAnims = ["singLEFT", "singDOWN", "singUP", "singRIGHT"];

		for(i in 0...singAnims.length)
		{
			missAnims[i] = singAnims[i] + "miss";

			singAnims[i] += prefix;
			missAnims[i] += prefix;
		}
	}

	public var danced:Bool = false;

	public function dance(forced:Bool = false)
	{
		switch(curChar)
		{
			default:
				if(animation.exists("danceLeft"))
				{
					danced = !danced;
					if(danced)
						playAnim("danceLeft");
					else
						playAnim("danceRight");
				}
				else
					playAnim("idle");
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if(holdTimer < holdLength)
		{
			holdTimer += elapsed;
		}
	}

	// animation handler
	public var animOffsets:Map<String, Array<Float>> = [];

	public function addOffset(animName:String, offX:Float = 0, offY:Float = 0):Void
		return animOffsets.set(animName, [offX, offY]);

	public function playAnim(animName:String, ?forced:Bool = false, ?reversed:Bool = false, ?frame:Int = 0)
	{
		animation.play(animName, forced, reversed, frame);

		if(animOffsets.exists(animName))
		{
			var daOffset = animOffsets.get(animName);
			offset.set(daOffset[0] * scale.x, daOffset[1] * scale.y);
		}
		else
			offset.set(0,0);

		// useful for pixel notes since their offsets are not 0, 0 by default
		offset.x += scaleOffset.x;
		offset.y += scaleOffset.y;
	}
}