package gameObjects.hud;

import flixel.FlxG;
import flixel.FlxSprite;
import sys.FileSystem;

class HealthIcon extends FlxSprite
{
	public var curIcon:String = "";

	public function new()
	{
		super();
		setIcon("face");
	}

	public function setIcon(curIcon:String = "face", isPlayer:Bool = false):HealthIcon
	{
		this.curIcon = curIcon;
		if(!FileSystem.exists('assets/images/icons/icon-${curIcon}.png'))
			return setIcon("face", isPlayer);

		var iconGraphic = Paths.image("icons/icon-" + curIcon);

		loadGraphic(iconGraphic, true, Math.floor(iconGraphic.width / 2), iconGraphic.height);

		animation.add("icon", [0,1], 0, false);
		animation.play("icon");

		flipX = isPlayer;

		return this;
	}

	public function setAnim(health:Float = 1)
	{
		var daFrame:Int = 0;

		if(health < 0.6)
			daFrame = 1;

		animation.curAnim.curFrame = daFrame;
	}
}