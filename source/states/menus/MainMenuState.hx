package states.menus;

import substates.menus.DebugSubState;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import doido.utils.LerpUtil;
import flixel.math.FlxMath;
import doido.objects.DoidoCamera;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import states.*;

typedef MenuOption =
{
	var name:String;
	var press:Void->Void;
}

class MainMenuState extends MusicBeatState
{
	static var curSelected:Int = 0;

	var options:Array<MenuOption> = [];
	var grpOptions:FlxTypedGroup<FlxSprite>;
	var splashTxt:FlxText;
	var bg:FlxSprite;
	var bgMag:FlxSprite;

	var bgPosY:Float = 0;
	var centerOptX:Bool = true;
	var centerOptY:Bool = true;
	var bgBounds:Array<Float> = [0, 0];

	public function new()
	{
		super();
		addOption("story mode", () -> switchState(new states.menus.StoryMenuState()));
		addOption("freeplay", () -> switchState(new FreeplayState()));
		#if (android && MODS_FOLDER)
		addOption("debug", () -> openSubState(new substates.menus.ModSubState()));
		#else
		if (Save.data.developerMode)
			addOption("debug", () -> openSubState(new DebugSubState()));
		#end
		addOption("options", () -> openSubState(new substates.menus.OptionsSubState()));
		addOption("credits", () -> switchState(new states.menus.CreditsState()));
		loadScript();
	}

	override function create()
	{
		super.create();
		MusicBeat.playMusic("freakyMenu");
		DiscordIO.changePresence("In the Main Menu");

		bg = new FlxSprite().loadGraphic(Assets.image('menuBG'));
		bg.scale.set(1.1, 1.1);
		bg.updateHitbox();
		bg.screenCenter(X);
		bg.zIndex = 0;
		add(bg);

		bgMag = new FlxSprite().loadGraphic(Assets.image('menuBGMagenta'));
		bgMag.scale.set(bg.scale.x, bg.scale.y);
		bgMag.updateHitbox();
		bgMag.visible = false;
		bgMag.zIndex = 1;
		add(bgMag);

		grpOptions = new FlxTypedGroup<FlxSprite>();
		grpOptions.zIndex = 10;
		add(grpOptions);

		var optionSize:Float = 1;
		if (options.length > 4)
		{
			optionSize -= 0.1;
			for (i in 0...(options.length - 4))
				optionSize -= 0.04;
		}

		for (i in 0...options.length)
		{
			var item = new FlxSprite();
			item.frames = Assets.sparrow('menu/mainmenu/' + options[i].name.replace(' ', '-'));
			item.animation.addByPrefix('idle', options[i].name + ' basic', 24, true);
			item.animation.addByPrefix('hover', options[i].name + ' white', 24, true);
			item.animation.play('idle');
			grpOptions.add(item);

			item.scale.set(optionSize, optionSize);
			item.updateHitbox();

			var itemSize:Float = (90 * optionSize);

			var minY:Float = 40 + itemSize;
			var maxY:Float = FlxG.height - itemSize - 40;

			if (options.length < 4)
				for (i in 0...(4 - options.length))
				{
					minY += itemSize;
					maxY -= itemSize;
				}

			item.x = FlxG.width / 2;
			item.y = FlxMath.lerp(minY, // gets min Y
				maxY, // gets max Y
				i / (options.length - 1) // sorts it according to its ID
			);

			item.ID = i;
		}

		var splash:String = 'Doido Engine 4.0 ${Main.internalVer}';
		splash += '\nFriday Night Funkin\' Rewritten';

		#if MODS_FOLDER
		#if mobile
		splash += '\nPress DEBUG to manage Mods';
		#elseif desktop
		splash += '\nPress [TAB] to manage Mods';
		#end
		#end

		splashTxt = new FlxText(4, 0, 0, splash);
		splashTxt.setFormat(Main.globalFont, 18, 0xFFFFFFFF, LEFT);
		splashTxt.setBorderStyle(OUTLINE, 0xFF000000, 1.5);
		splashTxt.y = FlxG.height - splashTxt.height - 4;
		splashTxt.zIndex = 20;
		add(splashTxt);

		callScript("createPost");
		changeSelection(0);
		bg.y = bgPosY;
		bgMag.y = bgPosY;
		sort(ZIndex.sort);
	}

	var canSelect = true;
	var flickMag:Float = 1;
	var flickBtn:Float = 1;

	var holdTimer:Float = 0.0;
	var holdMax:Float = 0.5;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (canSelect)
		{
			var change:Int = (Controls.pressed(UI_DOWN) ? 1 : 0) - (Controls.pressed(UI_UP) ? 1 : 0);
			if (change != 0)
				holdTimer += elapsed;
			else
				holdTimer = 0.0;
			if (Controls.justPressed(UI_UP) || Controls.justPressed(UI_DOWN) || holdTimer >= holdMax)
			{
				changeSelection(change);
				if (holdTimer >= holdMax)
					holdTimer = holdMax - 0.12;
			}

			if (Controls.justPressed(BACK))
				MusicBeat.switchState(new TitleState());

			if (Controls.justPressed(ACCEPT))
				options[curSelected].press();

			#if MODS_FOLDER
			if (FlxG.keys.justPressed.TAB)
				openSubState(new substates.menus.ModSubState());
			#end

			if (Save.data.developerMode && FlxG.keys.justPressed.EIGHT)
			{
				FlxG.sound.play(Assets.sound("cancel"));
				MusicBeat.switchState(new states.editors.CharacterEditor("face", false, false));
			}
		}
		else
		{
			if (Save.data.flashingLights != "OFF")
			{
				if (Save.data.flashingLights != "REDUCED")
				{
					flickMag += elapsed;
					if (flickMag >= 0.15)
					{
						flickMag = 0;
						bgMag.visible = !bgMag.visible;
					}
				}

				flickBtn += elapsed;
				if (flickBtn >= 0.15 / 2)
				{
					flickBtn = 0;
					for (item in grpOptions.members)
						if (item.ID == curSelected)
							item.visible = !item.visible;
				}
			}
		}

		bg.y = FlxMath.lerp(bg.y, bgPosY, elapsed * 6);
		bgMag.setPosition(bg.x, bg.y);
		callScript("updatePost", [elapsed]);
	}

	public function switchState(?target:MusicBeatState, tOut:String = 'funkin', ?tIn:String)
	{
		if (!canSelect)
			return;

		canSelect = false;

		if (callScript("switchState", [target]) ?? true)
		{
			trace("switching");
			FlxG.sound.play(Assets.sound('confirm'));

			for (item in grpOptions.members)
			{
				if (item.ID != curSelected)
					FlxTween.tween(item, {alpha: 0}, 0.4, {ease: FlxEase.cubeOut});
			}

			new FlxTimer().start(1.2, (tmr) -> MusicBeat.switchState(target, tOut, tIn));
		}
	}

	public function changeSelection(change:Int = 0)
	{
		curSelected += change;
		curSelected = FlxMath.wrap(curSelected, 0, options.length - 1);

		if (callScript("changeSelection", [change]) ?? true)
		{
			if (change != 0)
				FlxG.sound.play(Assets.sound('scroll'));

			bgPosY = FlxMath.lerp(-bgBounds[0], -(bg.height - FlxG.height) + bgBounds[1], curSelected / (options.length - 1));
			for (item in grpOptions.members)
			{
				item.animation.play('idle');
				if (curSelected == item.ID)
					item.animation.play('hover');

				item.updateHitbox();

				// makes it offset to its middle point
				if (centerOptX)
					item.offset.x += (item.frameWidth * item.scale.x) / 2;
				if (centerOptY)
					item.offset.y += (item.frameHeight * item.scale.y) / 2;
			}
		}
	}

	public function addOption(name:String, press:Void->Void, ?pos:Int)
	{
		var option:MenuOption = {name: name, press: press};
		if (pos == null)
			options.push(option);
		else
			options.insert(pos, option);
	}

	public function removeOption(name:String)
	{
		var opt:MenuOption = null;
		for (option in options)
		{
			if (option.name == name)
			{
				opt = option;
				break;
			}
		}
		if (opt != null)
			options.remove(opt);
	}

	public function moveOption(name:String, pos:Int)
	{
		var opt:MenuOption = null;
		for (option in options)
		{
			if (option.name == name)
			{
				opt = option;
				break;
			}
		}
		if (opt != null)
			options.remove(opt);
		addOption(opt.name, opt.press, pos);
	}
}
