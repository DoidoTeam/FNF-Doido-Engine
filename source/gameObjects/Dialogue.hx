package gameObjects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import gameObjects.menu.Alphabet;

typedef DialogueData = {
	var pages:Array<DialoguePage>;
}
typedef DialoguePage = {
	// box
	var ?boxSkin:String;
	// character
	var ?char:String;
	var ?charAnim:String;
	// dialogue text
	var ?text:String;
	// text settings
	var ?fontFamily:String;
	var ?fontScale:Float;
	var ?fontColor:Int;
	// text border
	var ?fontBorderType:FlxTextBorderStyle;
	var ?fontBorderColor:Int;
	var ?fontBorderSize:Float;
}
class Dialogue extends FlxGroup
{
	public var finishCallback:Void->Void;
	
	public function new()
	{
		super();
		grpChar = new FlxTypedGroup<DialogueChar>();
		box = new DialogueBox();
		
		text = new FlxText(0, 0, 0, "");
		text.setFormat(Main.gFont, 36, 0xFFFFFFFF, LEFT);
		text.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
		text.antialiasing = false;
		
		textAlphabet = new Alphabet(0,0,"",true);
		textAlphabet.visible = false;
		add(textAlphabet);
		
		bg = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFF000000);
		bg.screenCenter();
		bg.alpha = 0.3;
		add(bg);
		
		add(grpChar);
		add(box);
		add(text);
	}
	
	public var data:DialogueData;
	
	public var bg:FlxSprite;
	public var box:DialogueBox;
	public var grpChar:FlxTypedGroup<DialogueChar>;
	public var text:FlxText;
	public var textAlphabet:Alphabet;
	
	public var fontScale:Float = 1.0;
	
	var fontBorderSize:Float = 1.5;
	var fontBorderColor:Int = 0xFF000000;
	var fontBorderType:FlxTextBorderStyle = OUTLINE;
	
	public function load(data:DialogueData)
	{
		this.data = data;
		// preloading
		var spawnedChars:Array<String> = [];
		for(page in data.pages)
		{
			if(page.boxSkin != null)
				box.reloadBox(page.boxSkin);
			//if(page.char != null)
			//	char.reloadChar(page.char);
			if(page.char != null)
			{
				if(!spawnedChars.contains(page.char))
				{
					var char = new DialogueChar();
					char.reloadChar(page.char);
					grpChar.add(char);
				}
			}
		}
		// first page
		changePage(false);
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if(Controls.justPressed(ACCEPT))
		{
			if(isTyping)
				isTyping = false;
			else
				changePage();
		}
		if(Controls.justPressed(BACK))
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
		
		if(textAlphabet.visible)
			textAlphabet.text = text.text.replace("\n", "\\");
		
		if(box != null)
		{
			text.x = box.x + box.txtPos.x;
			text.y = box.y + box.txtPos.y;
			
			textAlphabet.setPosition(text.x, text.y);
		}
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
	public var activeChar:DialogueChar;
	
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
			
			if(swagPage.fontFamily != null)
			{
				textAlphabet.visible = false;
				text.visible = false;
				if(swagPage.fontFamily == 'Alphabet')
					textAlphabet.visible = true;
				else
				{
					text.visible = true;
					text.font = Paths.font(swagPage.fontFamily);
				}
			}
			
			//text.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
			if(swagPage.fontBorderType != null)
				fontBorderType = swagPage.fontBorderType;
			if(swagPage.fontBorderColor != null)
				fontBorderColor = swagPage.fontBorderColor;
			if(swagPage.fontBorderSize != null)
				fontBorderSize = swagPage.fontBorderSize;
			
			text.setBorderStyle(fontBorderType, fontBorderColor, fontBorderSize);
			
			if(swagPage.fontScale != null)
			{
				fontScale = swagPage.fontScale;
				text.size = Math.floor(36 * fontScale);
				text.updateHitbox();
				
				textAlphabet.scale.set(fontScale, fontScale);
				textAlphabet.updateHitbox();
			}
			if(swagPage.fontColor != null)
			{
				text.color = swagPage.fontColor;
				textAlphabet.color = swagPage.fontColor;
			}
			
			if(swagPage.text != null)
			{
				//text.text = swagPage.text;
				startTyping(swagPage.text);
			}
			
			if(swagPage.char != null)
			{
				for(char in grpChar.members)
				{
					char.isActive = false;
					if(char.curChar == swagPage.char)
					{
						char.isActive = true;
						activeChar = char;
					}
				}
			}
			
			if(swagPage.charAnim != null)
			{
				if(activeChar != null)
					activeChar.playAnim(swagPage.charAnim);
			}
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
				
			case "school-evil":
				makeGraphic(190 * 5, 42 * 5, 0xFF000000);
				
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