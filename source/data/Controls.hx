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

	// very dumb yea... but still works tho :/
	private function checkBind(bind:String, state:FlxInputState):Bool
	{
		if(!SaveData.gameControls.exists(bind)) return false;

		for(key in SaveData.gameControls.get(bind))
		{
			if(FlxG.keys.checkStatus(key, state))
				return true;
		}

		return false;
	}
}