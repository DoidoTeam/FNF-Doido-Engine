package doido.objects.ui.window;

import flixel.util.FlxSignal;
import doido.objects.ui.DoidoSlider;
import flixel.FlxBasic;
import flixel.group.FlxGroup;
import states.editors.ChartingState;
import flixel.FlxSprite;
import flixel.math.FlxRect;
import flixel.math.FlxMath;
import doido.utils.EditorUtil;

class DoidoWindow extends FlxGroup implements IWindow
{
	public var chartState:ChartingState;
	public var bg:FlxSprite;
	public var title:String = "";
	public var updateCallback:FlxSignal = new FlxSignal();

	public function new(chartState:ChartingState)
	{
		super();
		this.chartState = chartState;

		bg = new FlxSprite().makeColor(100, 100, 0xFF000000);
		bg.alpha = 0.5;
		add(bg);
	}

	public var overlapping(get, never):Bool;

	public function get_overlapping():Bool
		return FlxG.mouse.overlaps(bg, camera);
}

interface IWindow
{
	var overlapping(get, never):Bool;
}
