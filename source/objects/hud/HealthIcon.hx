package objects.hud;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import backend.utils.CharacterUtil;

class HealthIcon extends FlxSprite
{
	public function new()
	{
		super();
	}

	public var isPlayer:Bool = false;
	public var curIcon:String = "";
	public var maxFrames:Int = 0;

	public function setIcon(curIcon:String = "face", isPlayer:Bool = false):HealthIcon
	{
		this.curIcon = curIcon;
		if(!Paths.fileExists('images/icons/icon-${curIcon}.png'))
		{
			if(curIcon.contains('-'))
				return setIcon(CharacterUtil.formatChar(curIcon), isPlayer);
			else
				return setIcon("face", isPlayer);
		}

		var iconGraphic = Paths.image("icons/icon-" + curIcon);

		maxFrames = Math.floor(iconGraphic.width / 150);

		loadGraphic(iconGraphic, true, Math.floor(iconGraphic.width / maxFrames), iconGraphic.height);

		antialiasing = FlxSprite.defaultAntialiasing;
		isPixelSprite = false;
		if(curIcon.contains('pixel'))
		{
			antialiasing = false;
			isPixelSprite = true;
		}

		animation.add("icon", [for(i in 0...maxFrames) i], 0, false);
		animation.play("icon");

		this.isPlayer = isPlayer;
		flipX = isPlayer;

		return this;
	}

	public function setAnim(health:Float = 1)
	{
		health /= 2;
		var daFrame:Int = 0;

		if(health < 0.3)
			daFrame = 1;

		if(health > 0.7)
			daFrame = 2;

		if(daFrame >= maxFrames)
			daFrame = 0;

		animation.curAnim.curFrame = daFrame;
	}

	public static function getColor(char:String = ""):FlxColor
	{
		var colorMap:Map<String, FlxColor> = [
			"face" 		=> 0xFFA1A1A1,
			"bf" 		=> 0xFF31B0D1,
			"bf-old"	=> 0xFFE9FF48,
			"bf-cool"	=> 0xFF5FB6F1,
			"gf"		=> 0xFFA5004D,
			"dad"		=> 0xFFAF66CE,
			"pico"		=> 0xFFB7D855,
			"spooky"	=> 0xFFD57E00,
			"luano"		=> 0xFFFFC03F,
			"luano-night"=>0xFFB5A5F0,
			// pixel guys
			"bf-pixel"	=> 0xFF7BD6F6,
			"senpai"	=> 0xFFFFAA6F,
			"spirit"	=> 0xFFFF3C6E,
		];

		function loopMap()
		{
			if(!colorMap.exists(char))
			{
				if(char.contains('-'))
				{
					char = CharacterUtil.formatChar(char);
					loopMap();
				}
				else
					char = "face";
			}
		}
		loopMap();

		return colorMap.get(char);
	}
}