package objects.dialogue;

import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.util.FlxAxes;
import backend.utils.DialogueUtil;

class DialogueChar extends DialogueObj
{
	public function new()
	{
		super();
	}
	
	public var startPos:FlxPoint = new FlxPoint();
	public var activePos:FlxPoint = new FlxPoint();
	
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
		y = FlxG.height - height - 285;
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
	}
}
class DialogueBox extends DialogueObj
{
	public function new()
	{
		super();
	}
	
	public var boxPos:FlxPoint = new FlxPoint();
	public var txtPos:FlxPoint = new FlxPoint();
	public var boxSkin:String = "default";
	public var fieldWidth:Float = 0;
	public var isLog:Bool = false;
	public function reloadBox(boxSkin:String = "default", isLog:Bool = false):DialogueBox
	{
		this.boxSkin = boxSkin;
		this.isLog = isLog;

		isActive = true;

		boxPos.set(0,0);
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
				
				boxPos.y = -35;
			default:
				boxSkin = "default";
				makeGraphic(Std.int(FlxG.width * 0.9), Std.int(FlxG.height * 0.32), 0xFF000000);
				fieldWidth = Std.int(FlxG.width * 0.9) - 40;
		}
		
		screenCenter(X);

		y = FlxG.height - height - 30;
		
		x += boxPos.x;
		y += boxPos.y;
		
		return this;
	}
	
	/*
	*	simulates an animation
	*	by cutting the sprite
	*/
	function fakeAnimate(fakeFrames:Array<Float>, framerate:Int = 12, isWidth:Bool = false)
	{
		if(isLog)
			return;

		clipRect = new FlxRect(0,0,0,0);
		
		var senpaiTime:Float = 0;
		var senpaiLoop:Int = 0;
		_update = function(elapsed:Float)
		{
			senpaiTime += elapsed * 12;
			if(senpaiTime >= 1)
			{
				senpaiTime = 0;
				//Logs.print('frame: $senpaiLoop');
				
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

class DialogueImg extends DialogueObj
{
	public var imgName:String = "";
	public var sprName:String = "";

	public function new(imgData:DialogueSprite)
	{
		super();

		if(imgData.animations != null) {
			frames = Paths.getSparrowAtlas(imgData.image);
			for (anim in imgData.animations) {
				animation.addByPrefix(anim.name, anim.prefix, anim.framerate, anim.looped);
			}
			animation.play('idle');
		}
		else
			loadGraphic(Paths.image(imgData.image));
		
		if (imgData.scale != null)
			scale.set(imgData.scale, imgData.scale);

		updateHitbox();

		if(imgData.screenCenter != null)
			screenCenter(CoolUtil.stringToAxes(imgData.screenCenter));

		if(imgData.x != null)
			x += imgData.x;
		if(imgData.y != null)
			y += imgData.y;

		if(imgData.flipX != null)
			flipX = imgData.flipX;
		if(imgData.flipY != null)
			flipY = imgData.flipY;

		if (imgData.alpha != null)
			fakeAlpha = imgData.alpha;

		imgName = imgData.image;
		sprName = imgData.name;
		alpha = 0;
	}
}

class DialogueObj extends FlxSprite
{
	public var isActive:Bool = false;
	public var fakeAlpha:Float = 1;

	public function new()
	{
		super();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		alpha = FlxMath.lerp(alpha, fakeAlpha * (isActive ? 1 : 0), elapsed * 10);
	}
}

