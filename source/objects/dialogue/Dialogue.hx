package objects.dialogue;

import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import backend.utils.DialogueUtil;
import objects.dialogue.DialogueObjects;
import objects.menu.Alphabet;

class Dialogue extends FlxGroup
{
	public var finishCallback:Void->Void;
	
	public function new()
	{
		super();
		grpChar = new FlxTypedGroup<DialogueChar>();
		grpBg = new FlxTypedGroup<DialogueImg>();
		grpFg = new FlxTypedGroup<DialogueImg>();
		box = new DialogueBox();
		
		text = new FlxText(0, 0, 0, "");
		text.setFormat(Main.gFont, 36, 0xFFFFFFFF, LEFT);
		text.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
		text.antialiasing = false;
		
		textAlphabet = new Alphabet(0,0,"",false);
		textAlphabet.visible = false;
		
		underlay = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFF000000);
		underlay.screenCenter();
		underlay.alpha = 0.3;
		add(underlay);
		
		add(grpBg);
		add(grpChar);
		add(grpFg);

		add(box);
		add(text);
		add(textAlphabet);

		#if !TOUCH_CONTROLS
		var controlGuide = new FlxText(0,0,0,"Press BACK to skip.\nPress TAB/Y to open Text Log.");
        controlGuide.setFormat(Main.gFont, 22, 0xFFFFFFFF, CENTER);
		controlGuide.setBorderStyle(OUTLINE, 0xFF000000, 1);
		controlGuide.screenCenter(X);
		controlGuide.y = FlxG.height - controlGuide.height - 5;
		controlGuide.alpha = 0;
        add(controlGuide);

		FlxTween.tween(controlGuide, {alpha: 1}, 0.3, {
			startDelay: 0.3,
			onComplete: function(twn:FlxTween)
			{
				FlxTween.tween(controlGuide, {alpha: 0}, 1.5, {startDelay: 4});
			}
		});
		#end

		pastData = {pages: []};
	}
	
	public var data:DialogueData;
	public var pastData:DialogueData;
	
	public var underlay:FlxSprite;
	public var box:DialogueBox;
	public var grpChar:FlxTypedGroup<DialogueChar>;
	public var grpBg:FlxTypedGroup<DialogueImg>;
	public var grpFg:FlxTypedGroup<DialogueImg>;
	public var text:FlxText;
	public var textAlphabet:Alphabet;
	
	public var fontScale:Float = 1.0;
	
	var fontBorderSize:Float = 1.5;
	var fontBorderColor:Int = 0xFF000000;
	var fontBorderType:FlxTextBorderStyle = OUTLINE;

	var textDelay:Float = 4;
	var scrollSfx:Array<String> = [];
	var clickSfx:String = '';
	
	public function load(data:DialogueData, preload:Bool = false)
	{
		this.data = data;

		// preloading
		var spawnedChars:Array<String> = [];
		var spawnedBgs:Array<String> = [];
		var spawnedFgs:Array<String> = [];

		for(page in data.pages)
		{
			if(page.boxSkin != null)
				reloadBox(page.boxSkin);

			if(page.char != null)
			{
				if(!spawnedChars.contains(page.char))
				{
					var char = new DialogueChar();
					char.reloadChar(page.char);
					grpChar.add(char);

					spawnedChars.push(page.char);
				}
			}

			if(page.background != null) {
				if(!spawnedBgs.contains(page.background.image) && Paths.fileExists('images/${page.background.image}.png')) {
					var bg = new DialogueImg(page.background);
					grpBg.add(bg);
					spawnedBgs.push(page.background.image);
				}
			}

			if(page.foreground != null) {
				if(!spawnedFgs.contains(page.foreground.image) && Paths.fileExists('images/${page.foreground.image}.png')) {
					var fg = new DialogueImg(page.foreground);
					grpFg.add(fg);
					spawnedFgs.push(page.foreground.image);
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

			if(page.events != null) {
				for (event in page.events)
					preloadEvent(event);
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

		if(Controls.justPressed(TEXT_LOG)) {
			CoolUtil.activateTimers(false);
			FlxG.state.openSubState(new subStates.TextLogSubstate(pastData));
		}

		
		if(isTyping)
		{
			text.text = typeTxt.substring(0, typeLoop);
			typeTimer += elapsed;
			if(typeTimer >= (textDelay / 100))
			{
				if(textDelay > 2.5 || (typeLoop % 2 == 0)) {
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

			if(swagPage.textDelay != null)
				textDelay = swagPage.textDelay;
			
			if(swagPage.fontBorderType != null)
				fontBorderType = CoolUtil.stringToBorder(swagPage.fontBorderType);
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
				startTyping(swagPage.text);

			if(swagPage.underlayAlpha != null)
				underlay.alpha = swagPage.underlayAlpha;
			
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

			if(swagPage.background != null)
			{
				for(bg in grpBg.members)
				{
					bg.isActive = false;
					if(bg.sprName == swagPage.background.name)
						bg.isActive = true;
				}
			}

			if(swagPage.foreground != null)
			{
				for(fg in grpFg.members)
				{
					fg.isActive = false;
					if(fg.sprName == swagPage.foreground.name)
						fg.isActive = true;
				}
			}
			
			if(swagPage.charAnim != null)
			{
				if(activeChar != null)
					activeChar.playAnim(swagPage.charAnim);
			}

			if(swagPage.events != null && !preload) {
				for (event in swagPage.events)
					onEventHit(event);
			}

			pastData.pages.push(swagPage);
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

	function preloadEvent(event:DialogueEvent) {
		switch(event.name) {
			case 'Play SFX':
				Paths.preloadSound('sounds/${event.values[0]}');
		}
	}

	var shakeGrp:Array<FlxTween> = [];
	var shaking:Bool = false;

	function onEventHit(event:DialogueEvent) {
		switch(event.name)
		{
			case 'Play SFX':
				FlxG.sound.play(Paths.sound(event.values[0]), CoolUtil.stringToFloat(event.values[1], 1));


			case 'Flash Screen':
				CoolUtil.flash(
					FlxG.cameras.list[FlxG.cameras.list.length - 1],
					CoolUtil.stringToFloat(event.values[0], 2),
					CoolUtil.stringToColor(event.values[1])
				);

			case 'Shake Screen':
				var duration:Float = CoolUtil.stringToFloat(event.values[0], 1);
				var intensity:Float = CoolUtil.stringToFloat(event.values[1], 0.05);
				var isAll:Bool = CoolUtil.stringToBool(event.values[2]);

				if(shaking) {
					cancelShaking();

					if(duration == 0)
						return;
				}

				var objects:Array<DialogueObj> = [];
				var groups:Array<FlxTypedGroup<Dynamic>> = [grpChar, grpBg, grpFg];

				for (group in groups) {
					for (obj in group.members) {
						if (obj.isActive || isAll)
							objects.push(obj);
					}
				}

				for (obj in objects) {
					if(duration != 0)
						shakeGrp.push(FlxTween.shake(obj, intensity, duration, XY));
					else
						shakeGrp.push(FlxTween.shake(obj, intensity, 1, XY, {type: LOOPING}));
				}

				shaking = true;
		}
	}
	
	function cancelShaking() {
		for(shake in shakeGrp)
			if(shake != null)
				shake.cancel();

		shaking = false;
	}
}
