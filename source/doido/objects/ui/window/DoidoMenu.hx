package doido.objects.ui.window;

import flixel.FlxSprite;
import flixel.text.FlxBitmapText;
import flixel.group.FlxSpriteGroup;
import states.editors.ChartingState;
import doido.objects.ui.buttons.DoidoButton;

// was i supposed to do something with this?
enum MenuObjects
{
	BUTTON;
	SEPARATOR;
}

class MenuWindow extends DoidoWindow
{
	public var buttons:Array<MenuButton> = [];
	public var separators:Array<FlxSprite> = [];

	var width:Float = 0;
	var yOffset:Float = 0;

	public function new(x:Float = 0, y:Float = 0, width:Float = 100, chartState:ChartingState)
	{
		super(chartState);
		this.width = width;
		bg.setPosition(x, y);
	}

	public function updateBg()
	{
		bg.scale.set(width, yOffset);
		bg.updateHitbox();
	}

	public function addButton(label:String, ?bind:String, ?func:Void->Void)
	{
		var newBtn = new MenuButton(label, bind, width, func);
		buttons.push(newBtn);
		add(newBtn);

		newBtn.x = bg.x;
		newBtn.y = bg.y + yOffset;
		yOffset += newBtn.height;
	}

	public function addCheck(label:String, defaultValue:Bool, func:Bool->Void)
	{
		var newBtn = new MenuButton(label, defaultValue, width);
		newBtn.button.onUp.add(() ->
		{
			newBtn.value = !newBtn.value;
			func(newBtn.value);
		});
		buttons.push(newBtn);
		add(newBtn);

		newBtn.x = bg.x;
		newBtn.y = bg.y + yOffset;
		yOffset += newBtn.height;
	}

	public function addSeparator()
	{
		var separator:FlxSprite = new FlxSprite().makeColor(width, 3, 0xFF000000);
		separator.alpha = 0.5;
		add(separator);

		separator.x = bg.x;
		separator.y = bg.y + yOffset;
		yOffset += separator.height;
	}
}

class MenuButton extends FlxSpriteGroup
{
	public var value(default, set):Bool;
	public var button:DoidoButton;

	var _label:FlxBitmapText;
	var _bind:FlxBitmapText;
	var check:FlxSprite;

	public function new(label:String, ?bind:String, ?defaultValue:Bool, width:Float = 318, height:Float = 22, ?onUp:Void->Void, ?onDown:Void->Void)
	{
		super();

		button = new DoidoButton(onUp, onDown);
		button.makeColor(width, height, 0xFFD8DAF6);
		button.alpha = 0;
		button.maxScale = 1;
		button.minScale = 1;
		button.changeScale = false;
		add(button);

		button.onHover.add(() ->
		{
			button.alpha = 0.2;
		});
		button.onOut.add(() ->
		{
			button.alpha = 0;
		});

		_label = new FlxBitmapText(0, 0, Assets.bitmapFont("phantommuff"));
		_label.color = 0xFFFFFFFF;
		_label.alignment = LEFT;
		_label.text = label;
		_label.scale.set(0.625, 0.625);
		_label.updateHitbox();
		_label.setPosition(button.x + 2, button.y + ((button.height / 2) - (_label.height / 2)));
		add(_label);

		if (bind != null)
		{
			_bind = new FlxBitmapText(0, 0, Assets.bitmapFont("phantommuff"));
			_bind.color = 0xFF557BA0;
			_bind.alignment = RIGHT;
			_bind.text = '($bind)';
			_bind.scale.set(0.625, 0.625);
			_bind.updateHitbox();
			_bind.setPosition(button.x + button.width - _bind.width - 2, button.y + ((button.height / 2) - (_bind.height / 2)));
			add(_bind);
		}

		if (defaultValue != null)
		{
			check = new FlxSprite();
			check.loadSparrow("editors/charting/checkmark");
			check.animation.addByPrefix("off", "button checkmark" + "0000", 0, false);
			check.animation.addByPrefix("on", "button checkmark" + "0001", 0, false);
			check.scale.set(0.76, 0.76);
			check.updateHitbox();
			check.setPosition(button.x + button.width - check.width - 2, button.y + ((button.height / 2) - (check.height / 2)));
			add(check);
			
			value = defaultValue;
		}
	}

	public function set_value(b:Bool)
	{
		value = b;
		check.animation.play((b ? "on" : "off"));
		return value;
	}
}
