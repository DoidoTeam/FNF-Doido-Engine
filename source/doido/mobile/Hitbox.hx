package doido.mobile;

#if TOUCH_CONTROLS
import flixel.group.FlxSpriteGroup;
import doido.mobile.DoidoButton;
import doido.utils.NoteUtil;
import flixel.input.FlxInput.FlxInputState;
import flixel.util.FlxColor;

class Hitbox extends FlxSpriteGroup
{
    var buttonMap:Map<String, DoidoButton> = [];
    public function new()
    {
        super();
        
        var directions = NoteUtil.directions;
        var colors:Array<FlxColor> = [0xFFC24B99, 0xFF00FFFF, 0xFF12FA05, 0xFFF9393F];
        var buttonWidth = (FlxG.width/directions.length);
		for (i in 0...directions.length) {
			var button = new DoidoButton(i*buttonWidth, 0, buttonWidth, FlxG.height, 0.1, colors[i]);
            buttonMap.set(directions[i], button);
			add(button);
		}
    }

    public inline function justPressed(direction:String):Bool
		return checkButton(direction, JUST_PRESSED);

	public inline function pressed(direction:String):Bool
		return checkButton(direction, PRESSED);

	public inline function released(direction:String):Bool
		return checkButton(direction, JUST_RELEASED);

    public function checkButton(direction:String, inputState:FlxInputState):Bool
	{		
		var button = buttonMap.get(direction);
		if(button != null)
		{
			switch(inputState) {
				case PRESSED:
					return button.pressed;
				case JUST_PRESSED:
					return button.justPressed;
				case RELEASED | JUST_RELEASED:
					return button.justReleased;
				default:
					return false;
			}
		}
		return false;
	}
}
#end