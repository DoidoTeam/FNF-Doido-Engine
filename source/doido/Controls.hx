package doido;

import doido.utils.EditorUtil;
import flixel.FlxBasic;
import flixel.input.FlxInput.FlxInputState;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID as FlxPad;
import flixel.input.gamepad.FlxGamepad.FlxGamepadModel;
#if TOUCH_CONTROLS
import doido.mobile.TouchHandler;
#end

enum abstract DoidoKey(String)
{
	// notes
	var LEFT = "left";
	var DOWN = "down";
	var UP = "up";
	var RIGHT = "right";
	// gameplay
	var RESET = "reset";
	var PAUSE = "pause";
	var DIALOGUE_HISTORY = "dialogue_history";
	// ui
	var UI_LEFT = "ui_left";
	var UI_DOWN = "ui_down";
	var UI_UP = "ui_up";
	var UI_RIGHT = "ui_right";
	var ACCEPT = "accept";
	var BACK = "back";
	// volume
	var VOLUME_UP = "volume_up";
	var VOLUME_DOWN = "volume_down";
	var VOLUME_MUTE = "volume_mute";
	// other
	var ANY = "any";
	var NONE = "none";
}

typedef Binds =
{
	var keyboard:Array<FlxKey>;
	var gamepad:Array<FlxPad>;
}

enum InputType
{
	KEYBOARD;
	GAMEPAD;
	TOUCH;
}

class InputDelayHandler extends FlxBasic
{
	public function new()
	{
		super();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (Controls.inputDelay > 0)
			Controls.inputDelay--;
	}
}

class SoundInput extends FlxBasic
{
    public static var canChangeVolume:Bool = true;

	public function new() {
		super();
		FlxG.sound.muteKeys = [];
		FlxG.sound.volumeUpKeys = [];
		FlxG.sound.volumeDownKeys = [];
	}
    
	override function update(elapsed:Float)
	{
		super.update(elapsed);
        if (!canChangeVolume || EditorUtil.isTyping) return;

        if (Controls.justPressed(VOLUME_MUTE))
            FlxG.sound.toggleMuted();
        else if (Controls.justPressed(VOLUME_UP))
            FlxG.sound.changeVolume(0.1);
        else if (Controls.justPressed(VOLUME_DOWN))
            FlxG.sound.changeVolume(-0.1);
	}
}

class Controls
{
	public static var defaultBindMap:Map<DoidoKey, Binds> = [];
	public static var bindMap:Map<DoidoKey, Binds> = [
		// NOTES
		LEFT => {
			keyboard: [FlxKey.A, FlxKey.LEFT],
			gamepad: [FlxPad.LEFT_TRIGGER, FlxPad.DPAD_LEFT],
		},
		DOWN => {
			keyboard: [FlxKey.S, FlxKey.DOWN],
			gamepad: [FlxPad.LEFT_SHOULDER, FlxPad.DPAD_DOWN],
		},
		UP => {
			keyboard: [FlxKey.W, FlxKey.UP],
			gamepad: [FlxPad.RIGHT_SHOULDER, FlxPad.DPAD_UP],
		},
		RIGHT => {
			keyboard: [FlxKey.D, FlxKey.RIGHT],
			gamepad: [FlxPad.RIGHT_TRIGGER, FlxPad.DPAD_RIGHT],
		},

		// GAMEPLAY
		RESET => {
			keyboard: [FlxKey.R, FlxKey.NONE],
			gamepad: [FlxPad.BACK, FlxPad.NONE],
		},
		PAUSE => {
			// temp
			keyboard: [/*FlxKey.ESCAPE,*/ FlxKey.ENTER],
			gamepad: [FlxPad.START],
		},
		DIALOGUE_HISTORY => {
			// temp
			keyboard: [FlxKey.TAB],
			gamepad: [FlxPad.Y],
		},

		// UI
		UI_LEFT => {
			keyboard: [FlxKey.A, FlxKey.LEFT],
			gamepad: [FlxPad.LEFT_STICK_DIGITAL_LEFT, FlxPad.DPAD_LEFT],
		},
		UI_DOWN => {
			keyboard: [FlxKey.S, FlxKey.DOWN],
			gamepad: [FlxPad.LEFT_STICK_DIGITAL_DOWN, FlxPad.DPAD_DOWN],
		},
		UI_UP => {
			keyboard: [FlxKey.W, FlxKey.UP],
			gamepad: [FlxPad.LEFT_STICK_DIGITAL_UP, FlxPad.DPAD_UP],
		},
		UI_RIGHT => {
			keyboard: [FlxKey.D, FlxKey.RIGHT],
			gamepad: [FlxPad.LEFT_STICK_DIGITAL_RIGHT, FlxPad.DPAD_RIGHT],
		},
		ACCEPT => {
			keyboard: [FlxKey.SPACE, FlxKey.ENTER],
			gamepad: [FlxPad.A, FlxPad.X, FlxPad.START],
		},
		BACK => {
			keyboard: [FlxKey.BACKSPACE, FlxKey.ESCAPE],
			gamepad: [FlxPad.B],
		},

		// VOLUME
		VOLUME_UP => {
			keyboard: [FlxKey.PLUS, FlxKey.NUMPADPLUS],
			gamepad: [FlxPad.RIGHT_STICK_DIGITAL_UP, FlxPad.RIGHT_STICK_DIGITAL_RIGHT],
		},
		VOLUME_DOWN => {
			keyboard: [FlxKey.MINUS, FlxKey.NUMPADMINUS],
			gamepad: [FlxPad.RIGHT_STICK_DIGITAL_DOWN, FlxPad.RIGHT_STICK_DIGITAL_LEFT],
		},
		VOLUME_MUTE => {
			keyboard: [FlxKey.ZERO, FlxKey.NUMPADZERO],
			gamepad: [FlxPad.RIGHT_STICK_CLICK],
		},

		// DEBUG
	];

	public static inline function justPressed(bind:DoidoKey):Bool
		return checkBind(bind, JUST_PRESSED);

	public static inline function pressed(bind:DoidoKey):Bool
		return checkBind(bind, PRESSED);

	public static inline function released(bind:DoidoKey):Bool
		return checkBind(bind, JUST_RELEASED);

	public static var lastInput(default, null):InputType = #if !mobile KEYBOARD #else TOUCH #end;

	private static function setLastInput(v:InputType)
	{
		if (lastInput == GAMEPAD)
		{
			var curGamepad = FlxG.gamepads.lastActive;
			if (curGamepad != null)
				curGamepad.deadZone = Save.data.gamepadDeadzone;
		}
		
		if (lastInput != v)
		{
			lastInput = v;
			var state = MusicBeat.activeState;
			if (state != null)
			{
				if (Std.isOfType(state, MusicBeatState))
					cast(state, MusicBeatState).onInputChange.dispatch(lastInput);
				if (Std.isOfType(state, MusicBeatSubState))
					cast(state, MusicBeatSubState).onInputChange.dispatch(lastInput);
			}
		}
	}

	public static var inputDelay:Int = 0;

	public static function checkBind(bind:DoidoKey, inputState:FlxInputState):Bool
	{
		if (inputDelay > 0)
			return false;

		// lets you use both "BACK" and "back", for example
		bind = (cast bind).toLowerCase();

		if (!bindMap.exists(bind))
		{
			Logs.print('Bind $bind not found', WARNING);
			return false;
		}

		var binds:Binds = bindMap.get(bind);

		for (key in binds.keyboard)
		{
			if (FlxG.keys.checkStatus(key, inputState) && key != FlxKey.NONE)
			{
				setLastInput(KEYBOARD);
				return true;
			}
		}

		if (FlxG.gamepads.lastActive != null)
		{
			for (key in binds.gamepad)
			{
				if (FlxG.gamepads.lastActive.checkStatus(key, inputState) && key != FlxPad.NONE)
				{
					setLastInput(GAMEPAD);
					return true;
				}
			}
		}

		#if TOUCH_CONTROLS
		return checkMobile(bind, inputState);
		#end

		return false;
	}

	public static function isUiBind(bind:DoidoKey)
		return Std.string(bind).startsWith("ui_");

	#if TOUCH_CONTROLS
	public static function checkMobile(bind:DoidoKey, inputState:FlxInputState)
	{
		if (inputDelay > 0)
			return false;

		var daCheck:Bool = false;

		if (isUiBind(bind))
			daCheck = TouchHandler.getSwipe(bind);
		else if (bind == BACK)
			daCheck = TouchHandler.back;
		else if (bind == ACCEPT)
			daCheck = (TouchHandler.getTap(inputState) && !TouchHandler.getSwipe() && !TouchHandler.back);

		if (daCheck)
			setLastInput(TOUCH);
		return daCheck;
	}
	#end

	public static function save(?file:DoidoSave)
	{
		if (file == null)
			file = new DoidoSave("controls");
		file.data.bindMap = bindMap;
		file.close();
	}

	public static function load()
	{
		for (key => value in bindMap)
			defaultBindMap.set(key, value);

		var file = new DoidoSave("controls");

		if (file != null && file.data != null && file.data.bindMap != null)
		{
			var saved:Map<DoidoKey, Binds> = file.data.bindMap;
			for (key in bindMap.keys())
			{
				if (saved.exists(key))
				{
					bindMap.set(key, saved.get(key));
				}
			}
		}

		save(file);
	}

	public static final formatNum:Array<String> = ['ZERO', 'ONE', 'TWO', 'THREE', 'FOUR', 'FIVE', 'SIX', 'SEVEN', 'EIGHT', 'NINE'];
	public static final ps4Binds:Map<String, String> = [
		"LB" => "L1",
		"LT" => "L2",
		"RB" => "R1",
		"RT" => "R2",
		"A" => "CROSS",
		"B" => "CIRCLE",
		"X" => "SQUARE",
		"Y" => "TRIANGLE",
		"START" => "OPTIONS",
		"SELECT" => "SHARE",
	];
	public static final nSwitchBinds:Map<String, String> = [
		"LB" => "L",
		"LT" => "ZL",
		"RB" => "R",
		"RT" => "ZR",
		"A" => "B",
		"B" => "A",
		"X" => "Y",
		"Y" => "X",
		"START" => "PLUS",
		"SELECT" => "MINUS",
	];

	public static function formatKey(rawKey:Null<String>, isGamepad:Bool):String
	{
		var fKey:String = '---';
		if (rawKey != null && rawKey != 'NONE')
		{
			fKey = rawKey;
			for (num in formatNum)
			{
				if (fKey.contains(num))
					fKey = fKey.replace(num, '${formatNum.indexOf(num)}');
			}

			if (fKey.contains('NUMPAD'))
			{
				fKey = fKey.replace('NUMPAD', '');
				fKey += '#';
			}

			if (isGamepad)
			{
				fKey = fKey.replace("BACK", "SELECT"); // select fica menos confuso (eu acho)

				fKey = fKey.replace("DPAD_", "D-");

				if (fKey.contains("SHOULDER") || fKey.contains("TRIGGER"))
				{
					fKey = fKey.replace("LEFT", "L");
					fKey = fKey.replace("RIGHT", "R");
					if (fKey.contains("SHOULDER"))
					{
						fKey = fKey.replace("_SHOULDER", "");
						fKey += "B";
					}
					if (fKey.contains("TRIGGER"))
					{
						fKey = fKey.replace("_TRIGGER", "");
						fKey += "T";
					}
				}

				if (fKey.contains("STICK"))
				{
					fKey = fKey.replace("LEFT_STICK", "L-STICK");
					fKey = fKey.replace("RIGHT_STICK", "R-STICK");
					fKey = fKey.replace("_DIGITAL", "");
					fKey = fKey.replace("_", "\n");
				}

				var curGamepad = FlxG.gamepads.lastActive;
				if (curGamepad != null)
				{
					var convertMap:Int = 0;
					if ([PS4, PSVITA].contains(curGamepad.detectedModel))
						convertMap = 1;
					if ([SWITCH_PRO].contains(curGamepad.detectedModel))
						convertMap = 2;

					if (convertMap > 0)
					{
						for (bind => newBind in ((convertMap == 1) ? ps4Binds : nSwitchBinds))
							if (fKey == bind)
								fKey = newBind;
					}
				}
			}
		}
		return fKey;
	}
}
