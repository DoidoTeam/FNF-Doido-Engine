package objects.ui;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import doido.objects.DoidoSprite;

typedef IconData =
{
	var ?image:String;
	var ?color:String;
	var ?scale:Float;
	var ?pixel:Bool;
	var ?gridWidth:Int;
	var ?gridFrames:Int;
	var ?flipX:Bool;
	var ?flipY:Bool;
}

class HealthIcon extends FlxSprite
{
	public var gridFrames:Int = 0;
	public var isPlayer:Bool = false;
	public var curIcon:String = "";
	public var barColor:FlxColor;

	public var globalScale(default, set):Float = 1;

	public function set_globalScale(v:Float):Float
	{
		globalScale = v;
		if (data != null)
		{
			var newscale = data.scale * globalScale;
			scale.set(newscale, newscale);
			updateHitbox();
		}
		return globalScale;
	}

	var data:IconData;

	public function setIcon(curIcon:String = "face", isPlayer:Bool = false):HealthIcon
	{
		this.isPlayer = isPlayer;
		this.curIcon = curIcon;
		var DEFAULT = defaultIcon();

		try
		{
			data = cast(Assets.json('data/icons/$curIcon'));
		}
		catch (e)
		{
			if (curIcon.contains('-'))
				return setIcon(formatChar(curIcon), isPlayer);
			else
				data = DEFAULT;
		}

		var iconPath = data.image ?? curIcon;
		if (!Assets.fileExists('images/icons/$iconPath', IMAGE))
			iconPath = "face";

		var iconGraphic = Assets.image('icons/$iconPath');
		gridFrames = data.gridFrames ?? (Math.floor(iconGraphic.width / (data.gridWidth ?? DEFAULT.gridWidth)));
		loadGraphic(iconGraphic, true, Math.floor(iconGraphic.width / gridFrames), iconGraphic.height);

		animation.add("icon", [for (i in 0...gridFrames) i], 0, false);
		animation.play("icon");

		if (data.scale == null)
			data.scale = DEFAULT.scale;
		set_globalScale(globalScale);

		barColor = SpriteUtil.getColor(data.color ?? DEFAULT.color);
		flipX = data.flipX ?? DEFAULT.flipX;
		flipY = data.flipY ?? DEFAULT.flipY;
		antialiasing = ((data.pixel == true) ? false : flixel.FlxSprite.defaultAntialiasing);
		if (isPlayer)
			flipX = !flipX;

		return this;
	}

	public function setAnim(health:Float = 1)
	{
		health /= 2;
		var daFrame:Int = 0;

		if (health < 0.3)
			daFrame = 1;
		if (health > 0.7)
			daFrame = 2;
		if (daFrame >= gridFrames)
			daFrame = 0;

		animation.curAnim.curFrame = daFrame;
	}

	public static function defaultIcon():IconData
	{
		return {
			color: "0xFFA1A1A1",
			scale: 1,
			gridWidth: 150,
			flipX: false,
			flipY: false
		};
	}

	inline public static function formatChar(char:String):String
		return char.substring(0, char.lastIndexOf('-'));
}
