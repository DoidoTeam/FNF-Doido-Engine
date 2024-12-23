package objects.mobile;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.ui.FlxButton;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class Hitbox extends FlxSpriteGroup
{
	public var buttonLeft:HitboxButton;
	public var buttonDown:HitboxButton;
	public var buttonUp:HitboxButton;
	public var buttonRight:HitboxButton;

	var hbxWidth:Float = 320;
	var hint:FlxSprite;

	var assetModifier:String = "base";
	
	public function new(assetModifier:String = "base")
	{
		super();
		this.assetModifier = assetModifier;

		hint = new FlxSprite(0, 0);
		hint.loadGraphic(Paths.image('mobile/hitbox/$assetModifier/hints'));
		hint.alpha = 0;
		add(hint);

		buttonLeft 	= 	new HitboxButton(0, 			"left", 	assetModifier);
		buttonDown 	= 	new HitboxButton(hbxWidth, 		"down", 	assetModifier);
		buttonUp 	= 	new HitboxButton(hbxWidth * 2, 	"up", 		assetModifier);
		buttonRight = 	new HitboxButton(hbxWidth * 3, 	"right", 	assetModifier);
		
		add(buttonLeft);
		add(buttonDown);
		add(buttonUp);
		add(buttonRight);
	}

	public function toggleHbx(active)
	{
		hint.alpha = (active ? (SaveData.data.get("Hitbox Opacity") / 10) * 0.2 : 0);

		buttonLeft.isActive = active;
		buttonLeft.setAlpha(false);

		buttonDown.isActive = active;
		buttonDown.setAlpha(false);

		buttonUp.isActive = active;
		buttonUp.setAlpha(false);

		buttonRight.isActive = active;
		buttonRight.setAlpha(false);
	}

	override public function destroy():Void
    {
        super.destroy();

        buttonLeft = null;
        buttonDown = null;
        buttonUp = null;
        buttonRight = null;
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