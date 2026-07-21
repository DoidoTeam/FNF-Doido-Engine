package doido.objects.ui;

import flixel.math.FlxPoint;
import flixel.group.FlxSpriteGroup;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.util.FlxSignal;

typedef SliderSignal = FlxTypedSignal<DoidoSlider->Void>;

class DoidoSlider extends FlxSpriteGroup
{
	public var onScrub(default, null):SliderSignal = new SliderSignal();
	public var bar:FlxSprite;
	public var slider:FlxSprite;
	public var dots:Array<FlxSprite> = [];

	public var value:Float = 0;
	public var rangeMin:Float = 0;
	public var rangeMax:Float = 1;
	public var steps(default, set):Int = 2;
	public var vertical:Bool = false;
	public var center:Bool = true;
	public var snappingStrength(default, set):Float; // 0.05 seems pretty good
	public var disabled:Bool = false;
	public var dotSpacing:Float = 1;

	var wid:Int = 160;

	public function new(x:Float = 0, y:Float = 0, wid:Int = 160, hei:Int = 6, defValue:Float = 0, rangeMin:Float = 0, rangeMax:Float = 0, steps:Int = 2, snappingStrength:Float = 0, vertical:Bool = false, center:Bool = false)
	{
		super(x, y);
		this.rangeMin = rangeMin;
		this.rangeMax = rangeMax;
		this.vertical = vertical;
		this.center = center;
		this.wid = wid;

		bar = new FlxSprite().makeGraphic(wid, hei, 0xFFD8DAF6);
		add(bar);

		this.steps = steps;

		slider = new FlxSprite().loadImage("editors/charting/slider" + (vertical ? "-vertical" : ""));
		slider.x = (bar.width / 2) - (slider.width / 2);
		slider.y = (bar.height / 2) - (slider.height / 2);
		slider.zIndex = 10;
		add(slider);

		value = defValue;
		this.snappingStrength = snappingStrength;
	}

	function set_steps(i:Int)
	{
		steps = i;

		// you cant really have less than two
		if (steps >= 2)
		{
			for (dot in dots)
				dot.destroy();

			dots = [];

			dotSpacing = wid / (steps - 1);
			for (i in 0...steps)
			{
				var dot = new FlxSprite().loadImage("editors/charting/dot");
				dot.x = (dotSpacing * i) - (dot.width / 2);
				dot.y = (bar.height / 2) - (dot.height / 2);
				add(dot);
				dots.push(dot);
			}
		}

		sort(ZIndex.sort);

		return steps;
	}

	override function draw()
	{
		setAxis(FlxMath.lerp(getStart(), getEnd(), FlxMath.remapToRange(value, rangeMin, rangeMax, 0, 1)) - (getCenter(slider) / 2), slider);
		super.draw();
	}

	var scrubbing:Bool = false;

	var mousePos(get, never):FlxPoint;

	function get_mousePos():FlxPoint
		return FlxG.mouse.getViewPosition(MusicBeat.getTopCamera());

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (bar.overlapsPoint(mousePos) || slider.overlapsPoint(mousePos))
		{
			// chartState.curCursor = POINTER;
			if (FlxG.mouse.justPressed)
				scrubbing = true;
		}

		if (scrubbing && !disabled)
		{
			value = FlxMath.bound(FlxMath.remapToRange((vertical ? mousePos.y : mousePos.x), getStart(), getEnd(), rangeMin, rangeMax), rangeMin, rangeMax);

			if (steps >= 2 && snappingStrength >= 0)
			{
				// shit workaround
				var t = FlxMath.remapToRange(value, rangeMin, rangeMax, 0, 1);
				for (i in 0...steps)
				{
					var stepT = i / (steps - 1);
					if (Math.abs(t - stepT) <= snappingStrength)
					{
						value = FlxMath.remapToRange(stepT, 0, 1, rangeMin, rangeMax);
						break;
					}
				}
			}

			if (!FlxG.mouse.pressed)
				scrubbing = false;

			onScrub.dispatch(this);
		}
	}

	function set_snappingStrength(f:Float)
	{
		snappingStrength = FlxMath.bound(f, 0, 0.5 / (steps - 1));
		return snappingStrength;
	}

	function getStart()
		return getAxis(bar) + (center ? getCenter(slider) / 2 : 0);

	function getEnd()
		return getAxis(bar) + getCenter(bar) - (center ? getCenter(slider) / 2 : 0);

	function getCenter(sprite:FlxSprite)
		return (vertical ? sprite.height : sprite.width);

	function getAxis(sprite:FlxSprite)
		return (vertical ? sprite.y : sprite.x);

	function setAxis(f:Float, sprite:FlxSprite)
	{
		if (vertical)
			sprite.y = f;
		else
			sprite.x = f;
	}
}
