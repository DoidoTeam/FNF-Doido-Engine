package gameObjects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

typedef DialogueData = {
	var pages:Array<DialoguePage>;
}
typedef DialoguePage = {
	// box
	var ?boxSkin:String;
	// actual text
	var ?text:String;
	// character
	var ?charLeft:String;
	var ?charRight:String;
	var ?charFocus:String;
}
class Dialogue extends FlxGroup
{
	public var finishCallback:Void->Void;
	
	public function new()
	{
		super();
		charL = new DialogueChar();
		charR = new DialogueChar();
		charL.visible = false;
		charR.visible = false;
		box = new DialogueBox();
		text = new FlxText(0, 0, 0, "");
		text.setFormat(Main.gFont, 36, 0xFFFFFFFF, LEFT);
		text.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
		
		bg = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFF000000);
		bg.screenCenter();
		bg.alpha = 0.3;
		add(bg);
		
		add(charL);
		add(charR);
		add(box);
		add(text);
	}
	
	public var data:DialogueData;
	
	public var bg:FlxSprite;
	public var box:DialogueBox;
	public var charL:DialogueChar;
	public var charR:DialogueChar;
	public var text:FlxText;
	
	public function load(data:DialogueData)
	{
		this.data = data;
		// preloading
		for(page in data.pages)
		{
			if(page.boxSkin != null)
				box.reloadBox(page.boxSkin);
			if(page.charLeft != null)
				charL.reloadChar(page.charLeft);
			if(page.charRight != null)
				charR.reloadChar(page.charRight);
		}
		// first page
		changePage(false);
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if(Controls.justPressed('ACCEPT'))
		{
			if(isTyping)
				isTyping = false;
			else
				changePage();
		}
		if(Controls.justPressed('BACK'))
			finishCallback();
		
		if(isTyping)
		{
			text.text = typeTxt.substring(0, typeLoop);
			typeTimer += elapsed;
			if(typeTimer >= 0.04)
			{
				//if(typeLoop % 2 == 0)
				FlxG.sound.play(Paths.sound('dialogue/talking'));
				
				typeTimer = 0;
				typeLoop++;
			}
			if(typeLoop >= typeTxt.length)
				isTyping = false;
		}
		else
			text.text = typeTxt;
	}
	
	var typeLoop:Int = 0;
	var typeTimer:Float = 0;
	var isTyping:Bool = false;
	var typeTxt:String = "";
	public function startTyping(typeTxt:String = '')
	{
		typeLoop = 0;
		typeTimer = 0;
		isTyping = true;
		this.typeTxt = typeTxt;
	}
	
	public var curPage:Int = 0;
	
	public function changePage(change:Bool = true):Void
	{
		if(change) curPage++;
		if(curPage >= data.pages.length)
			return finishCallback();
		
		if(change)
			FlxG.sound.play(Paths.sound('dialogue/clickText'), 0.5);
		
		try{
			var swagPage = data.pages[curPage];
			
			if(swagPage.boxSkin != null)
				box.reloadBox(swagPage.boxSkin);
			
			if(swagPage.text != null)
			{
				//text.text = swagPage.text;
				startTyping(swagPage.text);
				if(box != null)
				{
					text.x = box.x + box.txtPos.x;
					text.y = box.y + box.txtPos.y;
				}
			}
			
			function loadChar(daChar:DialogueChar, newChar:String)
			{
				daChar.visible = true;
				if(newChar == '')
					daChar.visible = false;
				
				daChar.reloadChar(newChar);
			}
			
			if(swagPage.charFocus != null)
			{
				charL.alpha = charR.alpha = 0.4;
				switch(swagPage.charFocus)
				{
					case 'left': charL.alpha = 1;
					case 'right':charR.alpha = 1;
				}
			}
			
			if(swagPage.charLeft != null)
				loadChar(charL, swagPage.charLeft);
			if(swagPage.charRight != null)
				loadChar(charR, swagPage.charRight);
		}
		catch(e)
		{
			finishCallback();
		}
	}
}
class DialogueChar extends FlxSprite
{
	public function new()
	{
		super();
	}
	
	public var curChar:String = '';
	public function reloadChar(curChar:String):DialogueChar
	{
		this.curChar = curChar;
		switch(curChar)
		{
			case 'bf-pixel':
				loadGraphic(Paths.image('dialogue/chars/bf-pixel/bf-pixel'));
				antialiasing = false;
				scale.set(6,6);
				updateHitbox();
				
				defaultPos();
				x += 300;
				
				fakeAnimate([x + 200, x]);
			
			case 'senpai'|'senpai-angry'|'spirit':
				loadGraphic(Paths.image('dialogue/chars/senpai/$curChar'));
				antialiasing = false;
				scale.set(6,6);
				updateHitbox();
				
				defaultPos();
				x -= 300;
				
				if(curChar == 'spirit')
					y += 165;
				
				fakeAnimate([x - 200, x]);
				
			default:
				return reloadChar('bf-pixel');
		}
		return this;
	}
	
	function defaultPos()
	{
		screenCenter(X);
		y = FlxG.height - height - 335; // 320
	}
	
	function fakeAnimate(daPos:Array<Float>, time:Float = 0.45, ?ease:EaseFunction)
	{
		if(daPos.length < 2) daPos = [0,0];
		if(ease == null) ease = FlxEase.cubeOut;
		
		x = daPos[0];
		var storedAlpha:Float = alpha;
		alpha = 0;
		FlxTween.tween(this, {x: daPos[1], alpha: storedAlpha}, time, {ease: ease});
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
				scale.set(6,6);
				updateHitbox();
				
				fakeAnimate([0.05, 0.15, 0.5, 0.88, 1.0], 12, false);
				
				txtPos.set(100,90);
				
			case "school-evil":
				makeGraphic(190 * 6, 42 * 6, 0xFF000000);
				
				fakeAnimate([0.05, 0.15, 0.5, 0.98, 1.0], 12, true);
				
			default:
				boxSkin = "default";
				makeGraphic(Std.int(FlxG.width * 0.9), Std.int(FlxG.height * 0.32), 0xFF000000);
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