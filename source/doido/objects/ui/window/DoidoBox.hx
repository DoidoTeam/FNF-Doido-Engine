package doido.objects.ui.window;

import doido.objects.ui.buttons.DoidoButton;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import states.editors.ChartingState;
import doido.objects.ui.window.DoidoWindow.IWindow;
import flixel.text.FlxBitmapText;
import flixel.FlxSprite;

class DoidoBox extends FlxGroup implements IWindow
{
	public var chartState:ChartingState;
	public var tabs:Array<DoidoWindow> = [];
	public var buttons:Array<BoxLabel> = [];
	public var tabMap:Map<String, Int> = [];

	public var x:Float = 0;
	public var y:Float = 0;
	public var width:Float = 0;
	public var buttonWidth:Float = 0;
	public var buttonHeight:Float = 0;

	var cur:Int = -1;
	var spacing:Float = 5;

	public function new(x:Float = 0, y:Float = 0, width:Float = 100, buttonHeight:Float = 20, startingTab:Int = -1, centerButtons:Bool = true, tabs:Array<DoidoWindow>, chartState:ChartingState)
	{
		super();
		this.x = x;
		this.y = y;
		this.width = width;
		this.buttonHeight = buttonHeight;

		this.tabs = tabs;
		this.chartState = chartState;

		buttonWidth = (width - ((tabs.length - 1) * spacing)) / tabs.length;
		for (i in 0...tabs.length)
			addButton(tabs[i].title, i, centerButtons);

		cur = startingTab;
		toggleButtons();
	}

	inline function toggleButtons()
	{
		for (button in buttons)
			button.selected = (cur == button.ID);
	}

	function addButton(title:String, i:Int, centerButtons:Bool)
	{
		tabMap.set(title, i);
		var newBtn = new BoxLabel(title, buttonWidth, buttonHeight, centerButtons, () ->
		{
			cur = (cur == i ? -1 : i);
			toggleButtons();
		});
		newBtn.ID = i;
		buttons.push(newBtn);
		add(newBtn);

		newBtn.x = x + i * (buttonWidth + spacing);
		newBtn.y = y;
	}

	override function draw()
	{
		super.draw();

		if (tabs[cur] != null)
			tabs[cur].draw();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (tabs[cur] != null)
			tabs[cur].update(elapsed);
	}

	public var overlapping(get, never):Bool;

	public function get_overlapping():Bool
	{
		for (button in buttons)
		{
			if (FlxG.mouse.overlaps(button, FlxG.cameras.list[FlxG.cameras.list.length - 1]))
				return true;
		}

		if (tabs[cur] != null)
			return tabs[cur].overlapping;

		return false;
	}

	public function setTab(title:String)
	{
		cur = tabMap.get(title) ?? -1;
		toggleButtons();
	}
}

class BoxLabel extends FlxSpriteGroup
{
	var text:FlxBitmapText;
	var bg:FlxSprite;
	var button:DoidoButton;
	var toggled:Bool = false;

	public function new(label:String, width:Float = 318, height:Float = 22, center:Bool = true, ?onUp:Void->Void, ?onDown:Void->Void)
	{
		super();

		bg = new FlxSprite().makeColor(width, height, 0xFFFFFFFF);
		bg.alpha = 0.5;
		add(bg);

		button = new DoidoButton(onUp, onDown);
		button.makeColor(width, height, 0xFFD8DAF6);
		button.alpha = 0;
		button.changeScale = false;
		button.maxScale = 1;
		button.minScale = 1;
		add(button);

		button.onHover.add(() ->
		{
			button.alpha = 0.2;
		});
		button.onOut.add(() ->
		{
			button.alpha = 0;
		});

		text = new FlxBitmapText(0, 0, Assets.bitmapFont("phantommuff"));
		text.color = 0xFFFFFFFF;
		text.alignment = (center ? CENTER : LEFT);
		text.text = label;
		text.scale.set(0.625, 0.625);
		text.updateHitbox();
		text.setPosition((center ? button.x + (button.width / 2) - (text.width / 2) : button.x + 2), button.y + ((button.height / 2) - (text.height / 2)));
		add(text);
	}

	public var selected(default, set):Bool;

	public function set_selected(b:Bool):Bool
	{
		selected = b;
		text.color = (selected ? 0xFF20222D : 0xFFD8DAF6);
		bg.color = (selected ? 0xFFD8DAF6 : 0xFF000000);
		bg.alpha = (selected ? 1 : 0.5);
		return selected;
	}
}
