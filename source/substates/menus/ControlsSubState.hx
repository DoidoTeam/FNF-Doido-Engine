package substates.menus;

import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.group.FlxGroup.FlxTypedGroup;
import doido.objects.Alphabet;
import doido.utils.NoteUtil;
import flixel.FlxSprite;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepad.FlxGamepadModel;
import flixel.input.gamepad.FlxGamepadInputID as FlxPad;
import flixel.input.gamepad.id.PS4ID;
import flixel.math.FlxMath;
import objects.ui.notes.Strumline;

enum ControlMode
{
	OPTIONS;
	EDIT_CHOOSING;
	EDIT_WAITING;
	CLEARING;
	RESETTING;
}

class ControlsSubState extends MusicBeatSubState
{
	public var allBinds:Array<DoidoKey> = [LEFT, DOWN, UP, RIGHT];
	public var allOptions:Array<String> = ["EDIT", "CLEAR", "RESET"];

	public var bannedKeys:Array<FlxKey> = [
		FlxKey.ZERO,
		FlxKey.PLUS,
		FlxKey.MINUS,
		FlxKey.F1,
		FlxKey.F2,
		FlxKey.F3,
		FlxKey.F4,
		FlxKey.F5,
		FlxKey.F6,
		FlxKey.F7,
		FlxKey.F8,
		FlxKey.F9,
		FlxKey.F10,
		FlxKey.F11,
		FlxKey.F12
	];

	final formatNum:Array<String> = ['ZERO', 'ONE', 'TWO', 'THREE', 'FOUR', 'FIVE', 'SIX', 'SEVEN', 'EIGHT', 'NINE'];

	public var optionsSubState:OptionsSubState;

	public var bg:FlxSprite;
	public var strumline:Strumline;

	public var bindGrpArray:Array<FlxTypedGroup<BindSprite>> = [];
	public var bindGrp0:FlxTypedGroup<BindSprite>;
	public var bindGrp1:FlxTypedGroup<BindSprite>;
	public var bindOptions:FlxTypedGroup<Alphabet>;
	public var bindSquare:FlxSprite;
	public var awaitingTxt:Alphabet;

	public var curOption:Int = 0;
	public var curSelectedX:Int = 0;
	public var curSelectedY:Int = 0;

	public var curBindSpr:BindSprite;

	public var curMode:ControlMode = OPTIONS;
	public var isGamepad:Bool = false;

	public function new(optionsSubState:OptionsSubState)
	{
		super();
		this.optionsSubState = optionsSubState;
		var prevBG = optionsSubState.bg;
		bg = new FlxSprite(prevBG.x, prevBG.y).makeColor(prevBG.width, prevBG.height, 0xFF000000);
		bg.alpha = prevBG.alpha;
	}

	override function create()
	{
		super.create();
		FlxTween.tween(bg.scale, {x: FlxG.width + 10, y: FlxG.height + 10}, 0.4, {ease: FlxEase.cubeOut});
		add(bg);

		var middlescroll:Bool = Save.data.middlescroll;
		if (optionsSubState.playState == null)
			middlescroll = true;

		NoteUtil.setUpDirections(4);
		strumline = new Strumline(middlescroll ? 0 : FlxG.width / 4, Save.data.downscroll, true, false, false, "base");
		add(strumline);

		bindGrpArray.push(bindGrp0 = new FlxTypedGroup<BindSprite>());
		bindGrpArray.push(bindGrp1 = new FlxTypedGroup<BindSprite>());
		for (i in 0...bindGrpArray.length)
		{
			var bindGrp = bindGrpArray[i];
			bindGrp.ID = i;
			add(bindGrp);
		}

		add(bindOptions = new FlxTypedGroup<Alphabet>());
		for (i in 0...allOptions.length)
		{
			var option = new Alphabet(FlxG.width / 4 - 80, 0, allOptions[i], true);
			option.scale.set(0.8, 0.8);
			option.updateHitbox();
			option.align = CENTER;
			option.y = (FlxG.height / 2) + (60 * i) - (60 * (allOptions.length / 2));
			bindOptions.add(option);
			option.ID = i;
		}

		bindSquare = new FlxSprite(strumline.x, -200).loadSparrow("menu/controls/squares");
		for (anim in ["edit", "clear", "reset"])
			bindSquare.animation.addByPrefix(anim, '$anim square', 24, true);
		bindSquare.animation.play("edit");
		bindSquare.scale.set(0.7, 0.7);
		bindSquare.updateHitbox();
		bindSquare.offset.x += (bindSquare.width / 2) - 10;
		bindSquare.offset.y += (bindSquare.height / 2) + 16;
		add(bindSquare);

		awaitingTxt = new Alphabet(FlxG.width / 2, 24, "<color value=#FFFFFF>Press any key...</color>", false, CENTER);
		awaitingTxt.scale.set(0.6, 0.6);
		awaitingTxt.updateHitbox();
		awaitingTxt.visible = false;
		add(awaitingTxt);
		if (!Save.data.downscroll)
			awaitingTxt.y = FlxG.height - awaitingTxt.height - 24;

		for (j in 0...2)
		{
			var strums = strumline.strums;
			for (i in 0...strums.length)
			{
				var key = new BindSprite();
				key.setPosition(strums[i].x, strums[i].y + (NoteUtil.noteWidth() * (j + 1)),);
				if (Save.data.downscroll)
					key.y -= NoteUtil.noteWidth() * 3;

				key.ID = i;

				if (j == 0)
					bindGrp0.add(key);
				else
					bindGrp1.add(key);
			}
		}
		respawnBinds();

		onInputChange.add((inputType) -> {
			respawnBinds();
		});
	}

	public function respawnBinds()
	{
		isGamepad = (Controls.lastInput == GAMEPAD);
		for (j in 0...2)
		{
			for (i in 0...strumline.strums.length)
			{
				var key = bindGrpArray[j].members[i];
				if (isGamepad)
					reloadPad(key, getSaveBind(i, j));
				else
					reloadKey(key, getSaveBind(i, j));
			}
		}

		changeOption();
		changeBind();
	}

	public function changeOption(change:Int = 0)
	{
		if (change != 0)
			FlxG.sound.play(Assets.sound("scroll"));

		curOption += change;
		curOption = FlxMath.wrap(curOption, 0, allOptions.length - 1);

		bindOptions.forEach((option) ->
		{
			option.alpha = (option.ID == curOption ? 1.0 : 0.4);
		});
	}

	public function changeBind(changeX:Int = 0, changeY:Int = 0)
	{
		if (changeX != 0 || changeY != 0)
			FlxG.sound.play(Assets.sound("scroll"));

		curSelectedX += changeX;
		curSelectedY += changeY;
		curSelectedX = FlxMath.wrap(curSelectedX, 0, strumline.strums.length - 1);
		curSelectedY = FlxMath.wrap(curSelectedY, 0, 1);

		curBindSpr = bindGrpArray[curSelectedY].members[curSelectedX];
	}

	public function changeMenu(newMenu:ControlMode, ?sfx:String)
	{
		curMode = newMenu;
		if (sfx != null)
			FlxG.sound.play(Assets.sound(sfx));

		switch (newMenu)
		{
			case RESETTING:
				bindSquare.animation.play("reset");
			case CLEARING:
				bindSquare.animation.play("clear");
			case EDIT_CHOOSING:
				bindSquare.animation.play("edit");
			default:
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (curMode == OPTIONS)
		{
			if (Controls.justPressed(UI_UP))
				changeOption(-1);
			if (Controls.justPressed(UI_DOWN))
				changeOption(1);

			if (Controls.justPressed(ACCEPT))
			{
				switch (allOptions[curOption])
				{
					case "RESET":
						changeMenu(RESETTING, "scroll");
					case "CLEAR":
						changeMenu(CLEARING, "scroll");
					default:
						changeMenu(EDIT_CHOOSING, "scroll");
				}
			}

			if (Controls.justPressed(BACK))
			{
				optionsSubState.bg.scale.set(bg.scale.x, bg.scale.y);
				close();
			}
		}
		else if (curMode == EDIT_WAITING)
		{
			awaitingTxt.visible = true;

			var curGamepad = FlxG.gamepads.lastActive;
			if (!isGamepad)
			{
				if (FlxG.keys.justPressed.ANY || curGamepad?.justPressed.ANY)
				{
					Controls.inputDelay = 2;
					awaitingTxt.visible = false;
					if (FlxG.keys.justPressed.ESCAPE || FlxG.keys.anyJustPressed(bannedKeys) || curGamepad?.justPressed.ANY)
					{
						reloadKey(curBindSpr, getSaveBind());
						changeMenu(EDIT_CHOOSING, "cancel");
					}
					else
					{
						var key = FlxG.keys.firstJustPressed();
						setSaveBind(key);
						reloadKey(curBindSpr, key);
						changeMenu(EDIT_CHOOSING, "confirm");
					}
				}
			}
			else
			{
				if (curGamepad != null)
				{
					if (curGamepad.justPressed.ANY || FlxG.keys.justPressed.ANY)
					{
						Controls.inputDelay = 2;
						awaitingTxt.visible = false;
						if (FlxG.keys.justPressed.ANY)
						{
							reloadPad(curBindSpr, getSaveBind());
							changeMenu(EDIT_CHOOSING, "cancel");
						}
						else
						{
							var key = curGamepad.firstJustPressedID();
							// checking joystick input!!
							var joysticksJustPressed = [
								curGamepad.getXAxis(FlxPad.LEFT_ANALOG_STICK) <= -curGamepad.deadZone,
								curGamepad.getYAxis(FlxPad.LEFT_ANALOG_STICK) >= curGamepad.deadZone,
								curGamepad.getYAxis(FlxPad.LEFT_ANALOG_STICK) <= -curGamepad.deadZone,
								curGamepad.getXAxis(FlxPad.LEFT_ANALOG_STICK) >= curGamepad.deadZone,
								
								curGamepad.getXAxis(FlxPad.RIGHT_ANALOG_STICK) <= -curGamepad.deadZone,
								curGamepad.getYAxis(FlxPad.RIGHT_ANALOG_STICK) >= curGamepad.deadZone,
								curGamepad.getYAxis(FlxPad.RIGHT_ANALOG_STICK) <= -curGamepad.deadZone,
								curGamepad.getXAxis(FlxPad.RIGHT_ANALOG_STICK) >= curGamepad.deadZone,
							];
							var joysticksID:Array<FlxPad> = [
								LEFT_STICK_DIGITAL_LEFT,
								LEFT_STICK_DIGITAL_DOWN,
								LEFT_STICK_DIGITAL_UP,
								LEFT_STICK_DIGITAL_RIGHT,

								RIGHT_STICK_DIGITAL_LEFT,
								RIGHT_STICK_DIGITAL_DOWN,
								RIGHT_STICK_DIGITAL_UP,
								RIGHT_STICK_DIGITAL_RIGHT,
							];
							if (joysticksJustPressed.contains(true)) {
								key = joysticksID[joysticksJustPressed.indexOf(true)];
							}

							setSaveBind(key);
							reloadPad(curBindSpr, key);
							changeMenu(EDIT_CHOOSING, "confirm");
						}
					}
				}
			}
		}
		else
		{
			var changeX:Int = ((Controls.justPressed(UI_RIGHT) ? 1 : 0) - (Controls.justPressed(UI_LEFT) ? 1 : 0));
			var changeY:Int = ((Controls.justPressed(UI_DOWN) ? 1 : 0) - (Controls.justPressed(UI_UP) ? 1 : 0));
			if (changeX != 0 || changeY != 0)
				changeBind(changeX, changeY);

			if (Controls.justPressed(ACCEPT))
			{
				switch (curMode)
				{
					case CLEARING:
						FlxG.sound.play(Assets.sound('cancel'));
						if (!isGamepad) {
							setSaveBind(FlxKey.NONE);
							reloadKey(curBindSpr);
						} else {
							setSaveBind(FlxPad.NONE);
							reloadPad(curBindSpr);
						}

					case RESETTING:
						FlxG.sound.play(Assets.sound('cancel'));
						var key = getSaveBind(true);
						setSaveBind(key);
						if (isGamepad)
							reloadPad(curBindSpr, key);
						else
							reloadKey(curBindSpr, key);

					default:
						if (!isGamepad)
							reloadKey(curBindSpr);
						else
							reloadPad(curBindSpr);
						changeMenu(EDIT_WAITING, "scroll");
				}
			}

			if (Controls.justPressed(BACK))
				changeMenu(OPTIONS, "cancel");
		}

		if (curBindSpr != null)
		{
			bindSquare.setPosition(FlxMath.lerp(bindSquare.x, curMode == OPTIONS ? strumline.x : curBindSpr.x, elapsed * 8), FlxMath.lerp(bindSquare.y, curMode == OPTIONS ? -200 : curBindSpr.y, elapsed * 12));
		}
	}

	public function setSaveBind(newValue:Int):Void
	{
		var x = curSelectedX;
		var y = curSelectedY;

		var bind = Controls.bindMap.get(allBinds[x]);
		isGamepad ? bind.gamepad[y] = newValue : bind.keyboard[y] = newValue;
		Controls.save();
	}

	public function getSaveBind(?x:Int, ?y:Int, ?isDefault:Bool = false):Int
	{
		if (x == null)
			x = curSelectedX;
		if (y == null)
			y = curSelectedY;

		var bind = (isDefault ? Controls.defaultBindMap : Controls.bindMap).get(allBinds[x]);
		return isGamepad ? bind.gamepad[y] : bind.keyboard[y];
	}

	public function reloadKey(spr:BindSprite, keyID:Int = FlxKey.NONE)
	{
		var key:Null<String> = FlxKey.toStringMap[keyID];
		// trace(key);
		for (i in 0...formatNum.length)
		{
			if (key.contains(formatNum[i]))
			{
				key = i + (key.startsWith("NUMPAD") ? "#" : "");
			}
		}

		if (keyID == FlxKey.NONE)
			key = null;

		spr.reload(key);
	}

	public function reloadPad(spr:BindSprite, padID:Int = FlxPad.NONE)
	{
		var pad:Null<String> = FlxPad.toStringMap[padID];

		if (padID == FlxPad.NONE)
			pad = null;

		spr.reload(pad, true);
	}
}

class BindSprite extends FlxSprite
{
	public var label:Alphabet;

	public function new()
	{
		super();
		this.loadSparrow("menu/controls/keys");
		for (anim in [
			"L bumper",
			"L joystick click",
			"L joystick down",
			"L joystick left",
			"L joystick right",
			"L joystick up",
			"L shoulder",
			"R bumper",
			"R joystick click",
			"R joystick down",
			"R joystick left",
			"R joystick right",
			"R joystick up",
			"R shoulder",
			"arrow down",
			"arrow left",
			"arrow right",
			"arrow up",
			"backspace",
			"dpad down",
			"dpad left",
			"dpad right",
			"dpad up",
			"enter",
			"face down",
			"face left",
			"face right",
			"face up",
			"select",
			"start",
			"key empty long",
			"key empty",
		])
		{
			animation.addByPrefix(anim, anim + "0", 24, true);
			animation.play(anim);
		}

		label = new Alphabet(0, 0, "", false, CENTER);
	}

	override function draw()
	{
		super.draw();
		if (label.text.length > 0)
		{
			label.setPosition(x, y - (height / 2) + 8);
			label.draw();
		}
	}

	public function reload(?key:String, gamepad:Bool = false)
	{
		// trace(key);
		label.text = "";
		if (!gamepad)
		{
			// KEY ANIMATION
			animation.play(switch (key)
			{
				case "LEFT" | "DOWN" | "UP" | "RIGHT": "arrow " + key.toLowerCase();
				case "SHIFT" | "CONTROL" | "ALT" | "0#" | "CAPSLOCK" | "BACKSPACE" | "SCROLL_LOCK" | "BREAK" | "PAGEUP" | "PAGEDOWN": "key empty long";
				case "ENTER": "enter";
				default: "key empty";
			});
			// KEY TEXT
			if (key != null && !gamepad)
			{
				label.text = switch (key)
				{
					case "LEFT" | "DOWN" | "UP" | "RIGHT": "";
					case "CONTROL": "CTRL";
					case "BACKSLASH": "/";
					case "SEMICOLON": ";";
					case "COLON": ":";
					case "COMMA": ",";
					case "PERIOD": ".";
					case "QUOTE": "'";
					case "CAPSLOCK": "CAPS";
					case "PAGEUP": "PGUP";
					case "PAGEDOWN": "PGDWN";
					case "DELETE": "DEL";
					case "BACKSPACE": "BKSP";
					case "SCROLL_LOCK": "SCRLK";
					case "INSERT": "INS";
					default: key;
				}
				label.flipX = key == "BACKSLASH";
			}
		}
		else
		{
			// KEY ANIMATION
			animation.play(switch (key.toUpperCase())
			{
				case "DPAD_LEFT" | "DPAD_DOWN" | "DPAD_UP" | "DPAD_RIGHT": key.toLowerCase().replace("_", " ");

				case "X": "face left";
				case "A": "face down";
				case "Y": "face up";
				case "B": "face right";

				case "START": "start";
				case "BACK": "select";
				
				case "LEFT_STICK_DIGITAL_LEFT": "L joystick left";
				case "LEFT_STICK_DIGITAL_DOWN": "L joystick down";
				case "LEFT_STICK_DIGITAL_UP": 	"L joystick up";
				case "LEFT_STICK_DIGITAL_RIGHT":"L joystick right";
				case "LEFT_STICK_CLICK": "L joystick click";

				case "RIGHT_STICK_DIGITAL_LEFT": "R joystick left";
				case "RIGHT_STICK_DIGITAL_DOWN": "R joystick down";
				case "RIGHT_STICK_DIGITAL_UP": 	 "R joystick up";
				case "RIGHT_STICK_DIGITAL_RIGHT":"R joystick right";
				case "RIGHT_STICK_CLICK": "R joystick click";

				case "LEFT_SHOULDER": "L bumper";
				case "LEFT_TRIGGER": "L shoulder";
				case "RIGHT_SHOULDER": "R bumper";
				case "RIGHT_TRIGGER": "R shoulder";

				default: "key empty";
			});
		}
		scale.set(0.7, 0.7);
		updateHitbox();

		offset.x += width / 2;
		offset.y += height / 2;

		label.scale.set(0.7 * scale.x, 0.7 * scale.y);
		label.updateHitbox();
	}
}
