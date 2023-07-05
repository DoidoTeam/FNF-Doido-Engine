package data;

import flixel.FlxG;
import flixel.input.keyboard.FlxKey;
import flixel.input.FlxInput.FlxInputState;

/*
*	VERY improvised, but works
*/
class Controls
{
	public function new() {}

	public function justPressed(bind:String):Bool
	{
		return checkBind(bind, JUST_PRESSED);
	}

	public function pressed(bind:String):Bool
	{
		return checkBind(bind, PRESSED);
	}

	public function released(bind:String):Bool
	{
		return checkBind(bind, JUST_RELEASED);
	}

	// soon it will work with gamepads but for now just supports keyboard
	private function checkBind(bind:String, inputState:FlxInputState):Bool
	{
		if(!SaveData.keyControls.exists(bind))
		{
			trace("that bind does not exist dumbass");
			return false;
		}

		for(key in SaveData.keyControls.get(bind))
		{
			if(FlxG.keys.checkStatus(key, inputState)
			&& key != FlxKey.NONE)
				return true;
		}

		return false;
	}
}