package objects.mobile;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.ui.FlxButton;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class Hitbox extends FlxSpriteGroup
{
	public var buttonLeft:FlxButton;
	public var buttonDown:FlxButton;
	public var buttonUp:FlxButton;
	public var buttonRight:FlxButton;

	var assetModifier:String = "base";
	
	public function new(assetModifier:String = "base")
	{
		super();
		this.assetModifier = assetModifier;

		var hint:FlxSprite = new FlxSprite(0, 0);
		hint.loadGraphic(Paths.image('mobile/hitbox/$assetModifier/hints'));
		hint.alpha = (SaveData.data.get("Hitbox Opacity") / 10) * 0.2;
		add(hint);

		add(buttonLeft 	= 	createhitbox(0, "left"));
		add(buttonDown 	= 	createhitbox(320, "down"));
		add(buttonUp 	= 	createhitbox(320 * 2, "up"));
		add(buttonRight = 	createhitbox(320 * 3, "right"));
	}

	public function createhitbox(x:Float, frame:String) {
		var button = new FlxButton(x, 0);
		button.loadGraphic(Paths.getFrame('mobile/hitbox/$assetModifier/hitbox', frame));

		button.setGraphicSize(Std.int(320), FlxG.height);
		button.updateHitbox();

		button.alpha = 0;

		var tween:FlxTween = null;

		button.onDown.callback = function (){
			if (tween != null)
				tween.cancel();
			tween = FlxTween.num(button.alpha, SaveData.data.get("Hitbox Opacity") / 10, 0.075, {ease: FlxEase.circInOut}, function (a:Float) { button.alpha = a; });
		};

		button.onUp.callback = function (){
			if (tween != null)
				tween.cancel();
			tween = FlxTween.num(button.alpha, 0, 0.15, {ease: FlxEase.circInOut}, function (a:Float) { button.alpha = a; });
		}
		
		button.onOut.callback = function (){
			if (tween != null)
				tween.cancel();
			tween = FlxTween.num(button.alpha, 0, 0.15, {ease: FlxEase.circInOut}, function (a:Float) { button.alpha = a; });
		}

		return button;
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