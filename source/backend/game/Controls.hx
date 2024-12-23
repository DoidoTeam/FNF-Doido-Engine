package backend.game;

import flixel.input.gamepad.FlxGamepadInputID as FlxPad;
import flixel.input.keyboard.FlxKey;
import flixel.input.FlxInput.FlxInputState;

#if TOUCH_CONTROLS
import flixel.util.FlxTimer;
import backend.game.Mobile;
import backend.game.GameData;
import objects.mobile.DoidoPad;
#end

using haxe.EnumTools;

/*
	Custom input and controller handler
*/

enum DoidoKey
{
	// gameplay
	LEFT;
	DOWN;
	UP;
	RIGHT;
	RESET;
	// ui stuff
	UI_LEFT;
	UI_DOWN;
	UI_UP;
	UI_RIGHT;
	ACCEPT;
	BACK;
	PAUSE;
	TEXT_LOG;
	CONTROL;
	// none
	NONE;
}

class Controls
{
	public static function justPressed(bind:DoidoKey):Bool
	{
		return checkBind(bind, JUST_PRESSED);
	}

	public static function pressed(bind:DoidoKey):Bool
	{
		return checkBind(bind, PRESSED);
	}

	public static function released(bind:DoidoKey):Bool
	{
		return checkBind(bind, JUST_RELEASED);
	}

	public static function checkBind(rawBind:DoidoKey, inputState:FlxInputState):Bool
	{
		var bind = bindToString(rawBind);
		if(!allControls.exists(bind))
		{
			Logs.print('Bind $bind not found', WARNING);
			return false;
		}

		for(i in 0...allControls.get(bind)[0].length)
		{
			var key:FlxKey = allControls.get(bind)[0][i];
			if(FlxG.keys.checkStatus(key, inputState)
			&& key != FlxKey.NONE)
				return true;
		}

		// gamepads
		if(FlxG.gamepads.lastActive != null)
		for(i in 0...allControls.get(bind)[1].length)
		{
			var key:FlxPad = allControls.get(bind)[1][i];
			if(FlxG.gamepads.lastActive.checkStatus(key, inputState)
			&& key != FlxPad.NONE)
				return true;
		}

		#if TOUCH_CONTROLS
		return checkMobile(bind, inputState);
		#else
		return false;
		#end
	}

	inline public static function bindToString(bind:DoidoKey):String
	{
		var constructors = DoidoKey.getConstructors();
		return constructors[constructors.indexOf(Std.string(bind))];
	}

	//THIS IS A TEMP FIX!!!! CHANGE LATER!!!!
	inline public static function stringToBind(bind:String):DoidoKey
	{
		switch(bind.toUpperCase()) {
			case "LEFT":
				return LEFT;
			case "DOWN":
				return DOWN;
			case "UP":
				return UP;
			case "RIGHT":
				return RIGHT;
			case "RESET":
				return RESET;
			case "UI_LEFT":
				return UI_LEFT;
			case "UI_DOWN":
				return UI_DOWN;
			case "UI_UP":
				return UI_UP;
			case "UI_RIGHT":
				return UI_RIGHT;
			case "ACCEPT":
				return ACCEPT;
			case "BACK":
				return BACK;
			case "PAUSE":
				return PAUSE;
			case "TEXT_LOG":
				return TEXT_LOG;
			case "CONTROL":
				return CONTROL;
			default:
				return NONE;
		}

		// NOTE: This does not work on Linux or macOS
		//return cast DoidoKey.getConstructors().indexOf(Std.string(bind));
	}
	
	public static function setSoundKeys(?empty:Bool = false)
	{
		if(empty)
		{
			FlxG.sound.muteKeys 		= [];
			FlxG.sound.volumeDownKeys 	= [];
			FlxG.sound.volumeUpKeys 	= [];
		}
		else
		{
			FlxG.sound.muteKeys 		= [ZERO,  NUMPADZERO];
			FlxG.sound.volumeDownKeys 	= [MINUS, NUMPADMINUS];
			FlxG.sound.volumeUpKeys 	= [PLUS,  NUMPADPLUS];
		}
	}
	
	// self explanatory (i think)
	public static final changeableControls:Array<String> = [
		'LEFT', 'DOWN', 'UP', 'RIGHT',
		'RESET',
	];
	
	/*
	** [0]: keyboard
	** [1]: gamepad
	*/
	public static var allControls:Map<String, Array<Dynamic>> = [
		// gameplay controls
		'LEFT' => [
			[FlxKey.A, FlxKey.LEFT],
			[FlxPad.LEFT_TRIGGER, FlxPad.DPAD_LEFT],
		],
		'DOWN' => [
			[FlxKey.S, FlxKey.DOWN],
			[FlxPad.LEFT_SHOULDER, FlxPad.DPAD_DOWN],
		],
		'UP' => [
			[FlxKey.W, FlxKey.UP],
			[FlxPad.RIGHT_SHOULDER, FlxPad.DPAD_UP],
		],
		'RIGHT' => [
			[FlxKey.D, FlxKey.RIGHT],
			[FlxPad.RIGHT_TRIGGER, FlxPad.DPAD_RIGHT],
		],
		'RESET' => [
			[FlxKey.R, FlxKey.NONE],
			[FlxPad.BACK, FlxPad.NONE],
		],

		// ui controls
		'UI_LEFT' => [
			[FlxKey.A, FlxKey.LEFT],
			[FlxPad.LEFT_STICK_DIGITAL_LEFT, FlxPad.DPAD_LEFT],
		],
		'UI_DOWN' => [
			[FlxKey.S, FlxKey.DOWN],
			[FlxPad.LEFT_STICK_DIGITAL_DOWN, FlxPad.DPAD_DOWN],
		],
		'UI_UP' => [
			[FlxKey.W, FlxKey.UP],
			[FlxPad.LEFT_STICK_DIGITAL_UP, FlxPad.DPAD_UP],
		],
		'UI_RIGHT' => [
			[FlxKey.D, FlxKey.RIGHT],
			[FlxPad.LEFT_STICK_DIGITAL_RIGHT, FlxPad.DPAD_RIGHT],
		],

		// ui buttons
		'ACCEPT' => [
			[FlxKey.SPACE, FlxKey.ENTER],
			[FlxPad.A, FlxPad.X, FlxPad.START],
		],
		'BACK' => [
			[FlxKey.BACKSPACE, FlxKey.ESCAPE],
			[FlxPad.B],
		],
		'PAUSE' => [
			[FlxKey.ENTER, FlxKey.ESCAPE],
			[FlxPad.START],
		],
		'TEXT_LOG' => [
			[FlxKey.TAB],
			[FlxPad.Y],
		],
		'CONTROL' => [
			[#if mac FlxKey.WINDOWS, #end FlxKey.CONTROL],
			[],
		],
	];

	public static function load()
	{
		if(SaveData.saveControls.data.allControls == null)
		{
			SaveData.saveControls.data.allControls = allControls;
		}

		if(Lambda.count(allControls) != Lambda.count(SaveData.saveControls.data.allControls))
		{
			var oldControls:Map<String, Array<Dynamic>> = SaveData.saveControls.data.allControls;
			
			for(key => values in allControls) {
				if(oldControls.get(key) == null)
					oldControls.set(key, values);
			}
			for(key => values in oldControls) {
				if(allControls.get(key) == null)
					oldControls.remove(key);
			}

			SaveData.saveControls.data.allControls = allControls = oldControls;
		}
		
		// allControls = SaveData.saveControls.data.allControls;
		var impControls:Map<String, Array<Dynamic>> = SaveData.saveControls.data.allControls;
		for(label => key in impControls)
		{
			if(changeableControls.contains(label))
				allControls.set(label, key);
		}

		save();
	}

	public static function save()
	{
		SaveData.saveControls.data.allControls = allControls;
		SaveData.save();
	}

	#if TOUCH_CONTROLS
	public static var canTouch:Bool = false;
	public static var timer:FlxTimer;
	public static function resetTimer() {
		canTouch = false;

		if(timer != null)
			timer.cancel();
		timer = new FlxTimer().start(0.25, function(tmr:FlxTimer)
		{
			canTouch = true;
		});
	}

	public static function checkMobile(bind:String, inputState:FlxInputState) {
		if(!canTouch)
			return false;
		
		// DOIDOPAD
		if(Main.activeState is MusicBeatSubState || Main.activeState is MusicBeatState) {
			var state = cast(Main.activeState);
			var pad:DoidoPad = state.pad;

			if(pad.padActive) {
				if(pad.checkButton(bind, inputState))
					return pad.checkButton(bind, inputState);

				//if(bind == "ACCEPT" && inputState == JUST_PRESSED && (pad.checkButton(bind, PRESSED) || pad.checkButton(bind, JUST_RELEASED)))
				//	return false;	
			}
		}

		// SPECIAL BUTTONS
		if(bind.startsWith("UI_"))
			return Mobile.getSwipe(bind);
		else if(bind == "BACK")
			return Mobile.back;
		else if(bind == "ACCEPT") {
			return Mobile.getTap(inputState) && !Mobile.getSwipe() && !Mobile.back;
		}
		else
			return false;
	}
	#end
}