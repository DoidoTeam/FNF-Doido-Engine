package states.menu;

import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import data.GameData.MusicBeatState;
import gameObjects.menu.AlphabetMenu;
import gameObjects.menu.options.*;
import SaveData.SettingType;

class OptionsState extends MusicBeatState
{
	var optionShit:Map<String, Array<String>> =
	[
		"main" => [
			"gameplay",
			"appearance",
			"controls",
		],
		"gameplay" => [
			"Ghost Tapping",
			"Downscroll",
			"Middlescroll",
			"Framerate Cap",

			// dont ask
			/*"Framerate Cap",
			"Framerate Cap",
			"Framerate Cap",
			"Framerate Cap",
			"Framerate Cap",
			"Framerate Cap",
			"Framerate Cap",
			"Framerate Cap",
			"Framerate Cap",
			"Framerate Cap",
			"Framerate Cap",
			"Framerate Cap",*/
		],
		"appearance" => [
			"Antialiasing",
			"Note Splashes",
			"Ratings on HUD",
			"Split Holds",
		],
	];

	public static var bgColors:Map<String, FlxColor> = [
		"main" 		=> 0xFFcf68f7,
		"gameplay"	=> 0xFF83e6aa,
		"appearence"=> 0xFFf58ea9,
		"controls"  => 0xFF8295f5,
	];

	public static var curCat:String = "main";

	static var curSelected:Int = 0;
	static var storedSelected:Map<String, Int> = [];

	var grpTexts:FlxTypedGroup<AlphabetMenu>;
	var grpAttachs:FlxTypedGroup<FlxBasic>;

	// objects
	var bg:FlxSprite;

	// makes you able to go to the options and go back to the state you were before
	static var backTarget:FlxState;
	public function new(?newBackTarget:FlxState)
	{
		super();
		if(newBackTarget == null)
		{
			newBackTarget = new states.MenuState();
			if(backTarget == null)
				backTarget = newBackTarget;
		}
		else
			backTarget = newBackTarget;
	}

	override function create()
	{
		super.create();
		CoolUtil.playMusic("lilBitBack");
		bg = new FlxSprite().loadGraphic(Paths.image('menu/backgrounds/menuDesat'));
		bg.scale.set(1.2,1.2); bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		grpTexts = new FlxTypedGroup<AlphabetMenu>();
		grpAttachs = new FlxTypedGroup<FlxBasic>();

		add(grpTexts);
		add(grpAttachs);

		reloadCat();
	}

	public function reloadCat(curCat:String = "main")
	{
		storedSelected.set(OptionsState.curCat, curSelected);

		OptionsState.curCat = curCat;
		grpTexts.clear();
		grpAttachs.clear();

		if(storedSelected.exists(curCat))
			curSelected = storedSelected.get(curCat);
		else
			curSelected = 0;

		if(bgColors.exists(curCat))
			bg.color = bgColors.get(curCat);
		else
			bg.color = bgColors.get("main");

		FlxG.sound.play(Paths.sound("menu/scrollMenu"));

		if(curCat == "main")
		{
			for(i in 0...optionShit.get(curCat).length)
			{
				var item = new AlphabetMenu(0,0, optionShit.get(curCat)[i], true);
				grpTexts.add(item);

				item.ID = i;

				item.align = CENTER;
				item.updateHitbox();

				item.posUpdate = false;

				var spaceY:Float = 36;

				item.x = FlxG.width / 2;
				item.y = (FlxG.height / 2) + ((item.height + spaceY) * i);
				item.y -= (item.height + spaceY) * (optionShit.get(curCat).length - 1) / 2;
				item.y -= (item.boxHeight / 2);
			}
		}
		else
		{
			for(i in 0...optionShit.get(curCat).length)
			{
				var daOption:String = optionShit.get(curCat)[i];
				var item = new AlphabetMenu(0,0, daOption, true);
				grpTexts.add(item);

				item.ID = i;
				item.focusY = i;

				item.align = LEFT;
				item.scale.set(0.7,0.7);
				item.updateHitbox();
				
				item.xTo = 128;
				item.spaceX = 0;

				item.yTo = 48;
				item.spaceX = 0;
				item.spaceY = (item.boxHeight + 12);

				item.updatePos();

				if(optionShit.get(curCat).length <= 7)
				{
					item.posUpdate = false;

					var spaceY:Float = 12;

					item.y = (FlxG.height / 2) + ((item.height + spaceY) * i);
					item.y -= (item.height + spaceY) * (optionShit.get(curCat).length - 1) / 2;
					item.y -= (item.boxHeight / 2);
				}

				if(SaveData.displaySettings.exists(daOption))
				{
					var daDisplay:Dynamic = SaveData.displaySettings.get(daOption);

					switch(daDisplay[1])
					{
						case CHECKMARK:
							var daCheck = new OptionCheckmark(SaveData.data.get(daOption), 0.7);
							daCheck.ID = i;
							daCheck.x = FlxG.width - 128 - daCheck.width;
							grpAttachs.add(daCheck);

						case SELECTOR:
							var daSelec = new OptionSelector(
								daOption,
								SaveData.data.get(daOption),
								daDisplay[3]
							);
							daSelec.xTo = FlxG.width - 128;
							daSelec.updateValue();
							daSelec.ID = i;
							grpAttachs.add(daSelec);

						default: // uhhh
					}
				}
			}
		}

		updateAttachPos();
		changeSelection();
	}

	public function changeSelection(change:Int = 0)
	{
		curSelected += change;
		curSelected = FlxMath.wrap(curSelected, 0, optionShit.get(curCat).length - 1);

		for(item in grpTexts.members)
		{
			item.focusY = item.ID;
			item.alpha = 0.4;
			if(item.ID == curSelected)
			{
				item.alpha = 1;
			}
			if(curSelected > 7)
			{
				item.focusY -= curSelected - 7;
			}
		}
		for(item in grpAttachs.members)
		{
			var daAlpha:Float = 0.4;
			if(item.ID == curSelected)
				daAlpha = 1;

			if(Std.isOfType(item, OptionCheckmark))
			{
				var check = cast(item, OptionCheckmark);
				check.alpha = daAlpha;
			}
			
			if(Std.isOfType(item, OptionSelector))
			{
				var selector = cast (item, OptionSelector);
				for(i in selector.members)
				{
					i.alpha = daAlpha;
				}
			}
		}

		if(change != 0)
			FlxG.sound.play(Paths.sound("menu/scrollMenu"));

		// uhhh
		selectorTimer = Math.NEGATIVE_INFINITY;
	}

	function updateAttachPos()
	{
		for(item in grpAttachs.members)
		{
			for(text in grpTexts.members)
			{
				if(text.ID == item.ID)
				{
					if(Std.isOfType(item, OptionCheckmark))
					{
						var check = cast(item, OptionCheckmark);
						check.y = text.y + text.height / 2 - check.height / 2;
					}
					
					if(Std.isOfType(item, OptionSelector))
					{
						var selector = cast(item, OptionSelector);
						selector.setY(text);
					}
				}
			}
		}
	}

	var selectorTimer:Float = Math.NEGATIVE_INFINITY;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		updateAttachPos();

		if(Controls.justPressed("BACK"))
		{
			if(curCat == "main")
			{
				storedSelected.set("main", curSelected);
				FlxG.sound.play(Paths.sound("menu/cancelMenu"));
				Main.switchState(backTarget);
				backTarget = null;
			}
			else
				reloadCat("main");
		}

		if(Controls.justPressed("UI_UP"))
			changeSelection(-1);
		if(Controls.justPressed("UI_DOWN"))
			changeSelection(1);

		if(Controls.justPressed("ACCEPT"))
		{
			if(curCat == "main")
			{
				storedSelected.set("main", curSelected);
				var daOption:String = grpTexts.members[curSelected].text;
				switch(daOption.toLowerCase())
				{
					default:
						if(optionShit.exists(daOption))
							reloadCat(daOption);

					case "controls":
						new FlxTimer().start(0.1, function(tmr:FlxTimer)
						{
							Main.skipStuff();
							Main.switchState(new ControlsState());
						});
				}
			}
			else
			{
				var curAttach = grpAttachs.members[curSelected];
				if(Std.isOfType(curAttach, OptionCheckmark))
				{
					var checkmark = cast(curAttach, OptionCheckmark);
					checkmark.setValue(!checkmark.value);

					SaveData.data.set(optionShit[curCat][curSelected], checkmark.value);
					SaveData.save();

					FlxG.sound.play(Paths.sound("menu/scrollMenu"));
				}
			}
		}
		
		if(Controls.pressed("UI_LEFT") || Controls.pressed("UI_RIGHT"))
		{
			var curAttach = grpAttachs.members[curSelected];
			if(Std.isOfType(curAttach, OptionSelector))
			{
				var selector = cast(curAttach, OptionSelector);

				if(Controls.justPressed("UI_LEFT") || Controls.justPressed("UI_RIGHT"))
				{
					selectorTimer = -0.5;
					FlxG.sound.play(Paths.sound("menu/scrollMenu"));

					if(Controls.justPressed("UI_LEFT"))
						selector.updateValue(-1);
					else
						selector.updateValue(1);
				}

				if(Controls.pressed("UI_LEFT"))
					selector.arrowL.animation.play("push");

				if(Controls.pressed("UI_RIGHT"))
					selector.arrowR.animation.play("push");

				if(selectorTimer != Math.NEGATIVE_INFINITY && !Std.isOfType(selector.bounds[0], String))
				{
					selectorTimer += elapsed;
					if(selectorTimer >= 0.02)
					{
						selectorTimer = 0;
						if(Controls.pressed("UI_LEFT"))
							selector.updateValue(-1);
						if(Controls.pressed("UI_RIGHT"))
							selector.updateValue(1);
					}
				}
			}
		}
		if(Controls.released("UI_LEFT") || Controls.released("UI_RIGHT"))
		{
			selectorTimer = Math.NEGATIVE_INFINITY;
			for(attach in grpAttachs.members)
			{
				if(Std.isOfType(attach, OptionSelector))
				{
					var selector = cast(attach, OptionSelector);
					if(Controls.released("UI_LEFT"))
						selector.arrowL.animation.play("idle");

					if(Controls.released("UI_RIGHT"))
						selector.arrowR.animation.play("idle");
				}
			}
		}
	}
}