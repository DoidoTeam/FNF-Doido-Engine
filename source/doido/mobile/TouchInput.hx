package doido.mobile;

import objects.ui.notes.Strumline;
import flixel.group.FlxSpriteGroup;
#if TOUCH_CONTROLS
import doido.objects.DoidoButton.ButtonHitbox;
import doido.utils.NoteUtil;
import flixel.input.FlxInput.FlxInputState;
import flixel.util.FlxColor;
import flixel.FlxSprite;

class TouchInput extends FlxSpriteGroup
{
    var buttonMap:Map<String, ButtonHitbox> = [];
	var wide:Bool;
    public function new(strumline:Strumline)
    {
        super();
		this.wide = strumline.wide;
        var directions = NoteUtil.directions;

		if(wide) {
			var buttonSize = NoteUtil.noteWidth(true);
			for (i in 0...directions.length) {
				var button = new ButtonHitbox(0, 0, buttonSize + 50, buttonSize - 10, 0);
				buttonMap.set(directions[i], button);
				add(button);

				button.x = strumline.strums[i].x - (button.width / 2);
				button.y = strumline.strums[i].y - (button.height / 2);
			}
		}
		else {
			var buttonWidth = (FlxG.width/directions.length);
			for (i in 0...directions.length) {
				var button = new ButtonHitbox(i*buttonWidth, 0, buttonWidth, FlxG.height, 0);
				buttonMap.set(directions[i], button);
				add(button);

				var colors:Array<FlxColor> = [0xFFC24B99, 0xFF00FFFF, 0xFF12FA05, 0xFFF9393F];
				var hint:FlxSprite = new FlxSprite().loadImage("notes/other/hitbox", true, 320, 720);
				hint.animation.add("idle", [0], 0, false);
				hint.animation.add("pressed", [1], 0, false);
				hint.color = colors[i];
				hint.alpha = 0.5;
				var hintScale = buttonWidth / hint.width;
				hint.scale.set(hintScale, hintScale);
				hint.updateHitbox();
				hint.x = button.x;
				add(hint);

				button.onUp.add(() -> {hint.animation.play("idle");});
				button.onDown.add(() -> {hint.animation.play("pressed");});
			}
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
#else
class TouchInput extends FlxSpriteGroup
{
    public function new(strumline:Strumline)
		super();

	public inline function justPressed(direction:String):Bool
		return false;

	public inline function pressed(direction:String):Bool
		return false;

	public inline function released(direction:String):Bool
		return false;
}
#end