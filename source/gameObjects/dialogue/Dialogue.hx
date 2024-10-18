package gameObjects.dialogue;

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
import data.DialogueUtil;
import gameObjects.dialogue.DialogueObjects;

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
		
		textAlphabet = new Alphabet(0,0,"",false);
		textAlphabet.visible = false;
		
		bg = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFF000000);
		bg.screenCenter();
		bg.alpha = 0.3;
		add(bg);
		
		add(grpChar);
		add(box);
		add(text);
		add(textAlphabet);
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

	var textSpeed:Float = 4;
	var scrollSfx:Array<String> = [];
	var clickSfx:String = '';
	
	public function load(data:DialogueData, preload:Bool = false)
	{
		this.data = data;
		// preloading
		var spawnedChars:Array<String> = [];
		for(page in data.pages)
		{
			if(page.boxSkin != null)
				reloadBox(page.boxSkin);
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

			if(page.music != null)
				Paths.preloadSound('music/${page.music}');

			if(page.clickSfx != null)
				Paths.preloadSound('sounds/${page.clickSfx}');

			if(page.scrollSfx != null) {
				for (sound in page.scrollSfx) {
					Paths.preloadSound('sounds/${sound}');
				}
			}
		}
		// first page
		changePage(false, preload);
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
			if(typeTimer >= (textSpeed / 100))
			{
				if(textSpeed > 2.5 || (typeLoop % 2 == 0)) {
					if(scrollSfx.length > 0)
						FlxG.sound.play(Paths.sound(scrollSfx[FlxG.random.int(0, scrollSfx.length - 1)]));
				}


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
	
	public function changePage(change:Bool = true, preload:Bool = false):Void
	{
		if(change) curPage++;
		if(curPage >= data.pages.length)
			return finishCallback();
		
		try{
			var swagPage = data.pages[curPage];

			if(swagPage.music != null && !preload)
				CoolUtil.playMusic(swagPage.music);
			if(swagPage.clickSfx != null)
				clickSfx = swagPage.clickSfx;
			if(swagPage.scrollSfx != null)
				scrollSfx = swagPage.scrollSfx;

			if(change)
				FlxG.sound.play(Paths.sound(clickSfx), 0.5);
			
			if(swagPage.boxSkin != null)
				reloadBox(swagPage.boxSkin);
			
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

			if(swagPage.textSpeed != null)
				textSpeed = swagPage.textSpeed;
			
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
			if(swagPage.fontBold != null)
			{
				text.bold = swagPage.fontBold;
				textAlphabet.bold = swagPage.fontBold;
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

	function reloadBox(skin:String) {
		box.reloadBox(skin);
		text.fieldWidth = box.fieldWidth;
		textAlphabet.fieldWidth = box.fieldWidth;
	}
}
