package states.menu;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.gamepad.FlxGamepadInputID as FlxPad;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.util.FlxTimer;
import data.GameData.MusicBeatState;
import gameObjects.menu.Alphabet;

using StringTools;

class ControlsState extends MusicBeatState
{
	var isGamepad:Bool = false;

	var curMenu:String = "main";

	var grpMain:FlxTypedGroup<Alphabet>;

	var controlList:Array<String> = [
		"LEFT",
		"DOWN",
		"UP",
		"RIGHT",
		"RESET",
	];

	var grpLabel:FlxTypedGroup<Alphabet>;
	var grpControlsA:FlxTypedGroup<Alphabet>;
	var grpControlsB:FlxTypedGroup<Alphabet>;

	var curSelectedX:Int = 0;
	var curSelectedY:Int = 0;

	override function create()
	{
		super.create();
		var bg = new FlxSprite().loadGraphic(Paths.image('menu/backgrounds/menuDesat'));
		bg.scale.set(1.2,1.2); bg.updateHitbox();
		bg.screenCenter();
		bg.color = OptionsState.bgColors.get("controls");
		add(bg);

		grpMain = new FlxTypedGroup<Alphabet>();
		add(grpMain);

		grpLabel = new FlxTypedGroup<Alphabet>();
		grpControlsA = new FlxTypedGroup<Alphabet>();
		grpControlsB = new FlxTypedGroup<Alphabet>();

		add(grpLabel);
		add(grpControlsA);
		add(grpControlsB);

		reloadMenu();
	}

	public function reloadMenu(curMenu:String = "main")
	{
		this.curMenu = curMenu;
		grpMain.clear();
		grpLabel.clear();
		grpControlsA.clear();
		grpControlsB.clear();

		switch(curMenu)
		{
			case "main":
				var daStuff:Array<String> = ["keyboard", "gamepad"];
				for(i in 0...daStuff.length)
				{
					var item = new Alphabet(0, 0, daStuff[i], true);
					item.align = CENTER;
					item.updateHitbox();
					grpMain.add(item);

					item.ID = i;
					var spaceY:Float = 36;

					item.x = FlxG.width / 2;
					item.y = (FlxG.height / 2) + ((item.height + spaceY) * i);
					item.y -= (item.height + spaceY) * (daStuff.length - 1) / 2;
					item.y -= (item.boxHeight / 2);
				}

			default:
				isGamepad = false;
				if(curMenu == "gamepad")
					isGamepad = true;

				for(i in 0...controlList.length)
				{
					var label = new Alphabet(0, 0, controlList[i], true);
					label.scale.set(1.1,1.1);
					label.align = LEFT;
					label.updateHitbox();
					grpLabel.add(label);

					var spaceY:Float = 12;

					label.y = (FlxG.height / 2) + ((label.height + spaceY) * i);
					label.y -= (label.height + spaceY) * (controlList.length - 1) / 2;
					label.y -= (label.boxHeight / 2);

					var daControl = Controls.allControls.get(controlList[i])[getArrayNum()];

					var controlA = new Alphabet(0, 0, formatKey(daControl[0]), false);
					controlA.scale.set(1.1,1.1);
					controlA.align = LEFT;
					controlA.updateHitbox();
					grpControlsA.add(controlA);

					var controlB = new Alphabet(0, 0, formatKey(daControl[1]), false);
					controlB.scale.set(1.1,1.1);
					controlB.align = LEFT;
					controlB.updateHitbox();
					grpControlsB.add(controlB);

					label.ID = i;
					controlA.ID = i;
					controlB.ID = i;

					label.x = 128;
					controlA.x = 128 + 300;
					controlB.x = 128 + 600 + 128;

					controlA.y = controlB.y = (label.y - 8);

					if(isGamepad)
					{
						reloadAsGamepad(controlA);
						reloadAsGamepad(controlB);
					}
				}
		}

		changeMainSelection(false);
		changeSelection();
	}

	function getArrayNum():Int
	{
		return (isGamepad ? 1 : 0);
	}

	static var curMainSelected:Int = 0;
	function changeMainSelection(?change:Bool = true)
	{
		if(change)
			curMainSelected = (curMainSelected == 0) ? 1 : 0;

		for(item in grpMain.members)
		{
			item.alpha = 0.4;
			if(item.ID == curMainSelected)
				item.alpha = 1;
		}
	}

	var selectedItem:Alphabet = null;

	function changeSelection(?changeX:Int = 0, ?changeY:Int = 0)
	{
		if(changeX + changeY != 0)
			FlxG.sound.play(Paths.sound("beep"));

		curSelectedX += changeX;
		curSelectedY += changeY;

		curSelectedX = FlxMath.wrap(curSelectedX, 0, 1);
		curSelectedY = FlxMath.wrap(curSelectedY, 0, controlList.length - 1);

		for(item in grpLabel.members)
		{
			item.alpha = 0.4;
			if(curSelectedY == item.ID)
				item.alpha = 1;
		}

		for(item in grpControlsA.members)
		{
			item.alpha = 0.4;
			if(curSelectedY == item.ID && curSelectedX == 0)
			{
				selectedItem = item;
				item.alpha = 1;
			}
		}

		for(item in grpControlsB.members)
		{
			item.alpha = 0.4;
			if(curSelectedY == item.ID && curSelectedX == 1)
			{
				selectedItem = item;
				item.alpha = 1;
			}
		}
	}

	var waitingInput:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		var flxGamepad = FlxG.gamepads.firstActive;

		if(Controls.justPressed("BACK") && !waitingInput)
		{
			if(curMenu == "main")
			{
				new FlxTimer().start(0.1, function(tmr:FlxTimer)
				{
					Main.skipStuff();
					Main.switchState(new OptionsState());
				});
			}
			else
				reloadMenu("main");
		}

		switch(curMenu)
		{
			case "main":
				if(Controls.justPressed("ACCEPT"))
				{
					if(curMainSelected == 0)
						reloadMenu("keyboard");
					else
					{
						// ill do this later
						reloadMenu("gamepad");
					}
				}

				if(Controls.justPressed("UI_UP")
				|| Controls.justPressed("UI_DOWN"))
					changeMainSelection();

			default:
				if(!waitingInput)
				{
					if(Controls.justPressed("UI_UP"))
						changeSelection(0, -1);
					if(Controls.justPressed("UI_DOWN"))
						changeSelection(0,  1);
					if(Controls.justPressed("UI_LEFT"))
						changeSelection(-1, 0);
					if(Controls.justPressed("UI_RIGHT"))
						changeSelection(1,  0);

					if(Controls.justPressed("ACCEPT"))
					{
						waitingInput = true;
						selectedItem.visible = false;
					}
				}
				else
				{
					var padPressed:Bool = false;
					if(flxGamepad != null)
						if(flxGamepad.justPressed.ANY)
							padPressed = true;

					if(isGamepad)
					{
						if(padPressed || FlxG.keys.justPressed.ANY)
						{
							waitingInput = false;
							selectedItem.visible = true;

							if(padPressed)
							{
								var daKey:FlxPad = flxGamepad.firstJustPressedID();

								if(flxGamepad.analog.value.LEFT_STICK_X < 0)
									daKey = FlxPad.LEFT_STICK_DIGITAL_LEFT;
								if(flxGamepad.analog.value.LEFT_STICK_X > 0)
									daKey = FlxPad.LEFT_STICK_DIGITAL_RIGHT;
								if(flxGamepad.analog.value.LEFT_STICK_Y < 0)
									daKey = FlxPad.LEFT_STICK_DIGITAL_UP;
								if(flxGamepad.analog.value.LEFT_STICK_Y > 0)
									daKey = FlxPad.LEFT_STICK_DIGITAL_DOWN;

								if(flxGamepad.analog.value.RIGHT_STICK_X < 0)
									daKey = FlxPad.RIGHT_STICK_DIGITAL_LEFT;
								if(flxGamepad.analog.value.RIGHT_STICK_X > 0)
									daKey = FlxPad.RIGHT_STICK_DIGITAL_RIGHT;
								if(flxGamepad.analog.value.RIGHT_STICK_Y < 0)
									daKey = FlxPad.RIGHT_STICK_DIGITAL_UP;
								if(flxGamepad.analog.value.RIGHT_STICK_Y > 0)
									daKey = FlxPad.RIGHT_STICK_DIGITAL_DOWN;

								Controls.allControls.get(controlList[curSelectedY])[1][curSelectedX] = daKey;
								Controls.save();

								selectedItem.text = formatKey(daKey);

								reloadAsGamepad(selectedItem);
							}
						}
					}
					else
					{
						if(padPressed || FlxG.keys.justPressed.ANY)
						{
							waitingInput = false;
							selectedItem.visible = true;

							if(!padPressed)
							{
								var daKey:FlxKey = FlxG.keys.firstJustPressed();

								Controls.allControls.get(controlList[curSelectedY])[0][curSelectedX] = daKey;
								Controls.save();

								selectedItem.text = formatKey(daKey);
							}
						}
					}
				}
		}
	}

	public function formatKey(rawKey:Int = 0):String
	{
		var txtKey:String = "none";
		if(isGamepad)
			txtKey = FlxPad.toStringMap.get(rawKey);
		else
			txtKey = FlxKey.toStringMap.get(rawKey);

		if(rawKey == -1)
			txtKey = "none";

		txtKey = txtKey.replace("NUMPAD", "#");

		for(i in 0...numbers.length)
		{
			if(txtKey.contains(numbers[i]))
				txtKey = txtKey.replace(numbers[i], Std.string(i));
		}

		if(txtKey == "BACK")
			txtKey = "SELECT";

		return txtKey;
	}

	var numbers:Array<String> = ["ZERO", "ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE"];

	public function reloadAsGamepad(item:Alphabet):Void
	{
		if(["none", "start", "select"].contains(item.text.toLowerCase()))
			return;

		var daText:String = item.text;
		item.clear();

		var newItem = new FlxSprite();
		newItem.frames = Paths.getSparrowAtlas("menu/alphabet/gamepad");

		var convertKey:String = switch(daText.toUpperCase())
		{
			case "LEFT_TRIGGER": "LT";
			case "LEFT_SHOULDER":"LB";
			case "RIGHT_TRIGGER": "RT";
			case "RIGHT_SHOULDER":"RB";

			case "A": "A";
			case "X": "X";
			case "Y": "Y";
			case "B": "B";

			case "LEFT_STICK_DIGITAL_LEFT": "L left";
			case "LEFT_STICK_DIGITAL_DOWN": "L down";
			case "LEFT_STICK_DIGITAL_UP": 	"L up";
			case "LEFT_STICK_DIGITAL_RIGHT":"L right";

			case "RIGHT_STICK_DIGITAL_LEFT": "R left";
			case "RIGHT_STICK_DIGITAL_DOWN": "R down";
			case "RIGHT_STICK_DIGITAL_UP": 	 "R up";
			case "RIGHT_STICK_DIGITAL_RIGHT":"R right";

			case "DPAD_LEFT": 	"dpad left";
			case "DPAD_DOWN": 	"dpad down";
			case "DPAD_UP": 	"dpad up";
			case "DPAD_RIGHT": 	"dpad right";

			default: "what";
		};

		newItem.animation.addByPrefix(daText, "gpad " + convertKey + "0", 24, true);
		newItem.animation.play(daText);

		item.add(newItem);

		newItem.scale.set(item.scale.x, item.scale.y);
		newItem.updateHitbox();
		newItem.y = item.y + (item.boxHeight * item.scale.y) / 2 - newItem.height / 2;
		newItem.x = item.x;
	}
}