package doido;

import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID as FlxPad;
import flixel.input.FlxInput.FlxInputState;
import flixel.input.gamepad.FlxGamepad.FlxGamepadModel;
#if TOUCH_CONTROLS
import doido.mobile.TouchHandler;
#end

enum abstract DoidoKey(String)
{
	// gameplay
	var LEFT = "left";
	var DOWN = "down";
	var UP = "up";
	var RIGHT = "right";
	var RESET = "reset";
	// ui
	var UI_LEFT = "ui_left";
	var UI_DOWN = "ui_down";
	var UI_UP = "ui_up";
	var UI_RIGHT = "ui_right";
	var ACCEPT = "accept";
	var BACK = "back";
    var PAUSE = "pause";
    //other
    var ANY = "any";
	var NONE = "none";
}

typedef Binds =
{
	var keyboard:Array<FlxKey>;
	var gamepad:Array<FlxPad>;
	var rebindable:Bool;
}

class Controls
{
	public static var bindMap:Map<DoidoKey, Binds> = [
		// GAMEPLAY
		LEFT => {
            keyboard: [FlxKey.A, FlxKey.LEFT],
            gamepad: [FlxPad.LEFT_TRIGGER, FlxPad.DPAD_LEFT],
			rebindable: true
        },
        DOWN => {
            keyboard: [FlxKey.S, FlxKey.DOWN],
            gamepad: [FlxPad.LEFT_SHOULDER, FlxPad.DPAD_DOWN],
			rebindable: true
        },
        UP => {
            keyboard: [FlxKey.W, FlxKey.UP],
            gamepad: [FlxPad.RIGHT_SHOULDER, FlxPad.DPAD_UP],
			rebindable: true
        },
        RIGHT => {
            keyboard: [FlxKey.D, FlxKey.RIGHT],
            gamepad: [FlxPad.RIGHT_TRIGGER, FlxPad.DPAD_RIGHT],
			rebindable: true
        },
		RESET => {
			keyboard: [FlxKey.R, FlxKey.NONE],
			gamepad: [FlxPad.BACK, FlxPad.NONE],
			rebindable: true
		},

		// UI
		UI_LEFT => {
            keyboard: [FlxKey.A, FlxKey.LEFT],
            gamepad: [FlxPad.LEFT_STICK_DIGITAL_LEFT, FlxPad.DPAD_LEFT],
			rebindable: false
        },
        UI_DOWN => {
            keyboard: [FlxKey.S, FlxKey.DOWN],
            gamepad: [FlxPad.LEFT_STICK_DIGITAL_DOWN, FlxPad.DPAD_DOWN],
			rebindable: false
        },
        UI_UP => {
            keyboard: [FlxKey.W, FlxKey.UP],
            gamepad: [FlxPad.LEFT_STICK_DIGITAL_UP, FlxPad.DPAD_UP],
			rebindable: false
        },
        UI_RIGHT => {
            keyboard: [FlxKey.D, FlxKey.RIGHT],
            gamepad: [FlxPad.LEFT_STICK_DIGITAL_RIGHT, FlxPad.DPAD_RIGHT],
			rebindable: false
        },
		ACCEPT => {
			keyboard: [FlxKey.SPACE, FlxKey.ENTER],
			gamepad: [FlxPad.A, FlxPad.X, FlxPad.START],
			rebindable: false
		},
		BACK => {
			keyboard: [FlxKey.BACKSPACE, FlxKey.ESCAPE],
			gamepad: [FlxPad.B],
			rebindable: false
		},
        PAUSE => {
            //temp
			keyboard: [/*FlxKey.ESCAPE,*/ FlxKey.ENTER],
			gamepad: [FlxPad.START],
			rebindable: false
		},
	];

	public static function setSoundKeys(?empty:Bool = false) {
		if(empty) {
			FlxG.sound.muteKeys 		= [];
			FlxG.sound.volumeDownKeys 	= [];
			FlxG.sound.volumeUpKeys 	= [];
		}
		else {
			FlxG.sound.muteKeys 		= [ZERO,  NUMPADZERO];
			FlxG.sound.volumeDownKeys 	= [MINUS, NUMPADMINUS];
			FlxG.sound.volumeUpKeys 	= [PLUS,  NUMPADPLUS];
		}
	}

	public static inline function justPressed(bind:DoidoKey):Bool
		return checkBind(bind, JUST_PRESSED);

	public static inline function pressed(bind:DoidoKey):Bool
		return checkBind(bind, PRESSED);

	public static inline function released(bind:DoidoKey):Bool
		return checkBind(bind, JUST_RELEASED);

    public static function checkBind(bind:DoidoKey, inputState:FlxInputState):Bool {
		if(!bindMap.exists(bind)) {
			Logs.print('Bind $bind not found', WARNING);
			return false;
		}

		var binds:Binds = bindMap.get(bind);

		for(key in binds.keyboard) {
			if(FlxG.keys.checkStatus(key, inputState)
			&& key != FlxKey.NONE)
				return true;
		}

		if(FlxG.gamepads.lastActive != null) {
            for(key in binds.gamepad) {
                if(FlxG.gamepads.lastActive.checkStatus(key, inputState)
                && key != FlxPad.NONE)
                    return true;
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
	public static function checkMobile(bind:DoidoKey, inputState:FlxInputState) {
		if(isUiBind(bind))
			return TouchHandler.getSwipe(bind);
		else if(bind == BACK)
			return TouchHandler.back;
		else if(bind == ACCEPT) {
			return TouchHandler.getTap(inputState) && !TouchHandler.getSwipe() && !TouchHandler.back;
		}
		
        return false;
	}
	#end

	public static function save(?file:DoidoSave) {
		if(file == null)
			file = new DoidoSave("controls");
		file.data.bindMap = bindMap;
		file.close();
	}

	public static function load()
	{
		var file = new DoidoSave("controls");
		
		if (file != null && file.data != null && file.data.bindMap != null) {
			var saved:Map<DoidoKey, Binds> = file.data.bindMap;
			for (key in bindMap.keys()) {
				if (saved.exists(key)) {
					bindMap.set(key, saved.get(key));
				}
			}
		}
		
		save(file);
	}

	public static final formatNum:Array<String> = ['ZERO','ONE','TWO','THREE','FOUR','FIVE','SIX','SEVEN','EIGHT','NINE'];
    public static final ps4Binds:Map<String, String> = [
        "LB" => "L1",
        "LT" => "L2",
        "RB" => "R1",
        "RT" => "R2",
        "A"  => "CROSS",
        "B"  => "CIRCLE",
        "X"  => "SQUARE",
        "Y"  => "TRIANGLE",
        "START" => "OPTIONS",
        "SELECT" => "SHARE",
    ];
    public static final nSwitchBinds:Map<String, String> = [
        "LB" => "L",
        "LT" => "ZL",
        "RB" => "R",
        "RT" => "ZR",
        "A"  => "B",
        "B"  => "A",
        "X"  => "Y",
        "Y"  => "X",
        "START" => "PLUS",
        "SELECT" => "MINUS",
    ];

	public static function formatKey(rawKey:Null<String>, isGamepad:Bool):String
    {
        var fKey:String = '---';
        if(rawKey != null && rawKey != 'NONE')
        {
            fKey = rawKey;
            for(num in formatNum)
            {
                if(fKey.contains(num))
                    fKey = fKey.replace(num, '${formatNum.indexOf(num)}');
            }

            if(fKey.contains('NUMPAD'))
            {
                fKey = fKey.replace('NUMPAD', '');
                fKey += '#';
            }

            if(isGamepad)
            {
                fKey = fKey.replace("BACK", "SELECT"); // select fica menos confuso (eu acho)
                
                fKey = fKey.replace("DPAD_", "D-");

                if(fKey.contains("SHOULDER") || fKey.contains("TRIGGER"))
                {
                    fKey = fKey.replace("LEFT", "L");
                    fKey = fKey.replace("RIGHT", "R");
                    if(fKey.contains("SHOULDER"))
                    {
                        fKey = fKey.replace("_SHOULDER", "");
                        fKey += "B";
                    }
                    if(fKey.contains("TRIGGER"))
                    {
                        fKey = fKey.replace("_TRIGGER", "");
                        fKey += "T";
                    }
                }

                if(fKey.contains("STICK"))
                {
                    fKey = fKey.replace("LEFT_STICK",  "L-STICK");
                    fKey = fKey.replace("RIGHT_STICK", "R-STICK");
                    fKey = fKey.replace("_DIGITAL", "");
                    fKey = fKey.replace("_", "\n");
                }

				var curGamepad = FlxG.gamepads.lastActive;
                if(curGamepad != null)
                {
                    var convertMap:Int = 0;
                    if([PS4, PSVITA].contains(curGamepad.detectedModel))
                        convertMap = 1;
                    if([SWITCH_PRO].contains(curGamepad.detectedModel))
                        convertMap = 2;
                    
                    if(convertMap > 0)
                    {
                        for(bind => newBind in ((convertMap == 1) ? ps4Binds : nSwitchBinds))
                            if(fKey == bind)
                                fKey = newBind;
                    }
                }
            }
        }
        return fKey;
    }
}