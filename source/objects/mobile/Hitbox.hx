package objects.mobile;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.ui.FlxButton;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.input.FlxInput.FlxInputState;

class Hitbox extends FlxSpriteGroup
{
	var hint:FlxSprite;
	var hbxWidth:Float = 320;
	var hbxMap:Map<String, HitboxButton> = [];

	var assetModifier:String = "base";
	
	public function new(assetModifier:String = "base")
	{
		super();
		this.assetModifier = assetModifier;

		hint = new FlxSprite(0, 0);
		hint.loadGraphic(Paths.image('mobile/hitbox/$assetModifier/hints'));
		hint.alpha = 0;
		add(hint);

		var directions = CoolUtil.directions;
		for (i in 0...directions.length) {
			var button = new HitboxButton(hbxWidth*i, directions[i], assetModifier);
			hbxMap.set(directions[i], button);
			add(button);
		}
	}

	public function toggleHbx(active)
	{
		hint.alpha = (active ? (SaveData.data.get("Hitbox Opacity") / 10) * 0.2 : 0);

		for(button in hbxMap) {
			button.isActive = active;
			button.setAlpha(false);
		}
	}

	override public function destroy():Void
    {
        super.destroy();

		for(button in hbxMap)
			button.destroy();

		hbxMap = [];
    }

	public function checkButton(buttonID:String, inputState:FlxInputState):Bool
	{		
		var button = hbxMap.get(buttonID);
		if(button != null)
		{
			if(!button.isActive)
				return false;

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

class HitboxButton extends FlxButton
{
	public var isActive:Bool = false;
	var tween:FlxTween = null;

	public function new(x:Float, frame:String, assetModifier:String)
	{
		super(x, 0);

		loadGraphic(Paths.getFrame('mobile/hitbox/$assetModifier/hitbox', frame));
		alpha = 0;

		onDown.callback = function () {
			setAlpha(true);
		};

		onUp.callback = function () {
			setAlpha(false);
		}
		
		onOut.callback = function () {
			setAlpha(false);
		}

		active = true;
	}
	
	public function setAlpha(visible:Bool = false)
	{
		if (tween != null)
			tween.cancel();

		if(!isActive) {
			alpha = 0;
			return;
		}

		if(visible)
			alpha = SaveData.data.get("Hitbox Opacity") / 10;
		else
			tween = FlxTween.num(
				alpha,
				0,
				0.15,
				{ease: FlxEase.circInOut},
				function (a:Float) {
					alpha = a;
				}
			);
	}
}