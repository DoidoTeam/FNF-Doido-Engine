package gameObjects.dialogue;

import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.math.FlxMath;
import flixel.math.FlxRect;

class DialogueChar extends FlxSprite
{
	public function new()
	{
		super();
	}
	
	public var startPos:FlxPoint = new FlxPoint();
	public var activePos:FlxPoint = new FlxPoint();
	public var isActive:Bool = false;
	
	public var curChar:String = '';
	public function reloadChar(curChar:String):DialogueChar
	{
		this.curChar = curChar;
		startPos.set(-500, 700);
		activePos.set(100, 700);
		switch(curChar)
		{
			case 'bf-pixel':
				loadGraphic(Paths.image('dialogue/chars/bf-pixel/bf-pixel'));
				antialiasing = false;
				scale.set(5,5);
				updateHitbox();
				
				defaultPos();
				x += 240;
				startPos.set(x + 200, y);
				activePos.set(x, y);
			
			case 'senpai'|'senpai-angry'|'spirit':
				loadGraphic(Paths.image('dialogue/chars/senpai/$curChar'));
				antialiasing = false;
				scale.set(5,5);
				updateHitbox();
				
				defaultPos();
				x -= 240;
				if(curChar == 'spirit')
					y += 130;
				
				startPos.set(x - 200, y);
				activePos.set(x, y);
				
			default:
				return reloadChar('bf-pixel');
		}
		setPosition(startPos.x, startPos.y);
		alpha = 0;
		return this;
	}
	
	function defaultPos()
	{
		screenCenter(X);
		y = FlxG.height - height - 285; // 320
	}
	
	public function playAnim(animName:String = '')
	{
		try{
			animation.play(animName, false, false, 0);
		}
		catch(e) {}
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		var daPos:FlxPoint = startPos;
		if(isActive)
			daPos = activePos;
		
		x = FlxMath.lerp(x, daPos.x, elapsed * 8);
		y = FlxMath.lerp(y, daPos.y, elapsed * 8);
		alpha = FlxMath.lerp(alpha, isActive ? 1 : 0, elapsed * 10);
	}
}
class DialogueBox extends FlxSprite
{
	public function new()
	{
		super();
	}
	
	public var txtPos:FlxPoint = new FlxPoint();
	public var boxSkin:String = "default";
	public var fieldWidth:Float = 0;
	public function reloadBox(boxSkin:String = "default"):DialogueBox
	{
		this.boxSkin = boxSkin;
		txtPos.set(20,20);
		_update = null;
		switch(boxSkin)
		{
			case "school":
				loadGraphic(Paths.image('dialogue/box/pixel/school'));
				antialiasing = false;
				scale.set(5,5);
				updateHitbox();
				
				fakeAnimate([0.05, 0.15, 0.5, 0.88, 1.0], 12, false);
				
				txtPos.set(85,70);
				fieldWidth = 800;
				
			case "school-evil":
				makeGraphic(190 * 5, 42 * 5, 0xFF000000);
				
				fakeAnimate([0.05, 0.15, 0.5, 0.98, 1.0], 12, true);

				fieldWidth = (190*5) - 40;
				
			default:
				boxSkin = "default";
				makeGraphic(Std.int(FlxG.width * 0.9), Std.int(FlxG.height * 0.32), 0xFF000000);
				fieldWidth = Std.int(FlxG.width * 0.9) - 40;
		}
		
		screenCenter(X);
		y = FlxG.height - height - 30;
		// adjust the pos
		switch(boxSkin)
		{
			case "school-evil":
				y -= 35;
		}
		
		return this;
	}
	
	/*
	*	simulates an animation
	*	by cutting the sprite
	*/
	function fakeAnimate(fakeFrames:Array<Float>, framerate:Int = 12, isWidth:Bool = false)
	{
		clipRect = new FlxRect(0,0,0,0);
		
		var senpaiTime:Float = 0;
		var senpaiLoop:Int = 0;
		_update = function(elapsed:Float)
		{
			senpaiTime += elapsed * 12;
			if(senpaiTime >= 1)
			{
				senpaiTime = 0;
				//trace('frame: $senpaiLoop');
				
				var daWidth:Float = frameWidth;
				var daHeight:Float = frameHeight;
				if(isWidth)
					daWidth *= fakeFrames[senpaiLoop];
				else
					daHeight *= fakeFrames[senpaiLoop];
				
				clipRect = new FlxRect(0, 0, daWidth, daHeight);
				senpaiLoop++;
				
				if(senpaiLoop >= fakeFrames.length)
				{
					clipRect = null;
					_update = null;
				}
			}
		}
	}
}