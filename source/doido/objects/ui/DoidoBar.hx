package doido.objects.ui;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxRect;

class DoidoBar extends FlxSpriteGroup
{
	public var border:FlxSprite;
	public var sideL:FlxSprite;
	public var sideR:FlxSprite;

	public var percent(default, set):Float = 0;

	public function set_percent(v:Float)
	{
		percent = v;
		if (sideL != null && sideR != null)
		{
			var rectL = FlxRect.get(0, 0, FlxMath.lerp(sideL.frameWidth, 0, percent / 100), sideL.frameHeight);
			sideL.clipRect = rectL;
			var rectR = FlxRect.get(FlxMath.lerp(sideR.frameWidth, 0, percent / 100), 0, sideR.frameWidth, sideR.frameHeight);
			sideR.clipRect = rectR;
		}
		return percent;
	}

	public function new(?x:Float = 0, ?y:Float = 0, barFile:String, ?borderFile:String, ?startPercent:Float = 50)
	{
		super(x, y);
		percent = startPercent;

		sideR = new FlxSprite();
		sideR.loadGraphic(Assets.image(barFile));
		sideL = new FlxSprite();
		sideL.loadGraphic(Assets.image(barFile));

		add(sideR);
		add(sideL);
		if (borderFile != null)
		{
			border = new FlxSprite().loadGraphic(Assets.image(borderFile));
			add(border);
		}
	}

	public function updatePos()
	{
		for (item in members)
			item.setPosition(x, y);
	}

	override function draw()
	{
		for (item in members)
			item.alpha = alpha;
		super.draw();
	}
}
