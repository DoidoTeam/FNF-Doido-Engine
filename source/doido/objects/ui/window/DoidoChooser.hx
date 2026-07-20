package doido.objects.ui.window;

import flixel.group.FlxSpriteGroup;
import flixel.math.FlxRect;
import flixel.math.FlxMath;
import doido.utils.EditorUtil;
import states.editors.ChartingState;
import flixel.FlxSprite;
import flixel.text.FlxBitmapText;
import doido.objects.ui.buttons.DoidoButton;
import objects.ui.HealthIcon;
import doido.utils.EventUtil;
import doido.utils.NoteUtil;
import flixel.util.FlxTimer;

enum ChooserView
{
	LIST;
	GRID;
}

enum ChooserType
{
	NONE;
	CHARACTER;
	EVENT;
	NOTETYPE;
}

enum ChooserAlign
{
	LEFT;
	CENTER;
}

class ChooserWindow extends DoidoWindow
{
	public var x:Float;
	public var y:Float;
	public var width:Int;
	public var height:Int;
	public var filter(default, set):String;

	var spacing:Int = 12;
	var buttonWidth:Int = 1;
	var buttonHeight:Int = 1;
	var bottom:Int = 0;

	var buttons:Array<ChooserButton> = [];
	var slider:DoidoSlider;

	public var options(default, set):Array<String>;
	public var descs(default, set):Array<String>;
	public var descOnly:Bool = false;

	var filtered:Array<String> = [];
	var noScroll(get, never):Bool;

	public var view(default, set):ChooserView = GRID;
	public var type:ChooserType = CHARACTER;
	public var align:ChooserAlign = CENTER;

	public var onClick:String->Void;

	public var buttonId:String = "";

	var gridCount:Int = 4;
	var locked:Bool = false;

	public function new(x:Float = 0, y:Float = 0, width:Int = 440, height:Int = 185, list:Array<String>, chartState:ChartingState)
	{
		super(chartState);
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
		@:bypassAccessor filter = "";

		bg.scale.set(width, height);
		bg.updateHitbox();
		bg.x = x;
		bg.y = y;

		slider = new DoidoSlider(bg.x + bg.width - 18 - spacing, bg.y + spacing, 18, height - (spacing * 2), 0, 0, 1, 0, 0, true, true);
		slider.bar.color = 0xFF000000;
		slider.onScrub.add((b) ->
		{
			yOffset = slider.value;
			updateButtons();
		});
		add(slider);

		view = GRID;
		options = list;
		@:bypassAccessor descs = [];
	}

	function buildButtons()
	{
		for (button in buttons)
			button.kill();

		buttons = [];

		for (i in 0...filtered.length)
		{
			var button:ChooserButton = new ChooserButton(descOnly ? descs[i] : filtered[i], descOnly ? "" : descs[i] ?? "", type, view, align, buttonWidth,
				buttonHeight, () ->
				{
					if (locked)
						return;

					if (onClick != null)
						onClick(filtered[i]);

					locked = true;
					new FlxTimer().start(0.1, (tmr) -> locked = false);
				});

			if (view == GRID)
				button.x = x + spacing + ((i % gridCount) * buttonWidth);
			else
				button.x = x + spacing;

			button.ID = i;
			buttons.push(button);
			add(button);
		}

		yOffset = 0;
		slider.value = 0;
		calcBottom();
		slider.disabled = noScroll;
		slider.rangeMax = bottom;
		updateButtons();
	}

	function calcBottom()
	{
		if (view == LIST)
			bottom = (buttonHeight * filtered.length) + (2 * spacing) - height;
		else
			bottom = (buttonHeight * Math.ceil(filtered.length / gridCount)) + (2 * spacing) - height;
	}

	var yOffset:Float = 0;

	function updateButtons()
	{
		yOffset = (noScroll ? 0 : FlxMath.bound(yOffset, 0, bottom));
		for (button in buttons)
		{
			if (view == GRID)
				button.y = y + spacing + (buttonHeight * Math.floor(button.ID / gridCount)) - yOffset;
			else
				button.y = y + spacing + (buttonHeight * button.ID) - yOffset;
			for (item in button.members)
				setClip(item);
		}
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		for (button in buttons)
			button.button.disabled = !overlapping;

		if (overlapping && !noScroll)
		{
			if (FlxG.mouse.wheel != 0)
			{
				yOffset -= FlxG.mouse.wheel * 32;
				updateButtons();
				slider.value = yOffset;
			}
		}
	}

	function setClip(sprite:FlxSprite)
	{
		var newx:Float = x - sprite.x;
		var newy:Float = y - sprite.y;
		var newwidth:Float = (x + width - sprite.x) - newx;
		var newheight:Float = (y + height - sprite.y) - newy;
		sprite.clipRect = new FlxRect(newx / sprite.scale.x, newy / sprite.scale.y, newwidth / sprite.scale.x, newheight / sprite.scale.y);
	}

	public function set_filter(s:String)
	{
		filter = s;
		filtered = EditorUtil.doidoSearch(options, filter);
		buildButtons();
		return filter;
	}

	public function set_options(a:Array<String>)
	{
		options = a;
		filtered = EditorUtil.doidoSearch(options, filter);
		buildButtons();
		return options;
	}

	public function set_descs(a:Array<String>)
	{
		descs = a;
		buildButtons();
		return descs;
	}

	function get_noScroll()
	{
		return (height + bottom) <= height;
	}

	public function set_view(v:ChooserView)
	{
		view = v;
		switch (view)
		{
			case GRID:
				buttonWidth = Std.int((width - 40 - spacing) / gridCount);
				buttonHeight = buttonWidth;
			case LIST:
				buttonWidth = width - 40 - spacing;
				buttonHeight = 40;
		}
		return view;
	}
}

class ChooserButton extends FlxSpriteGroup
{
	var _label:FlxBitmapText;
	var _desc:FlxBitmapText;

	public var button:DoidoButton;
	public var icon:FlxSprite;

	public function new(label:String, desc:String = "", type:ChooserType, view:ChooserView, align:ChooserAlign, width:Int = 318, height:Int = 22,
			?onUp:Void->Void, ?onDown:Void->Void)
	{
		super();

		button = new DoidoButton(onUp, onDown);
		button.makeGraphic(width, height, 0xFFD8DAF6);
		button.alpha = 0;
		button.maxScale = 1;
		button.minScale = 1;
		button.changeScale = false;
		button.onDisable.add(() ->
		{
			if (button.disabled)
				button.alpha = 0;
		});
		add(button);

		button.onHover.add(() ->
		{
			button.alpha = 0.2;
		});
		button.onOut.add(() ->
		{
			button.alpha = 0;
		});

		icon = new FlxSprite();
		switch (type)
		{
			case CHARACTER:
				var uhhh = new HealthIcon();
				uhhh.setIcon(label, false);
				icon.loadGraphicFromSprite(uhhh);
			case EVENT:
				icon.loadImage(EventUtil.getEventSprite(label));
			case NOTETYPE:
				icon.loadImage(NoteUtil.getNoteSprite(label));
			default:
				icon.visible = false;
		}
		add(icon);

		_label = new FlxBitmapText(0, 0, Assets.bitmapFont("phantommuff"));
		_label.color = 0xFFFFFFFF;
		_label.alignment = align == LEFT ? LEFT : CENTER;
		_label.text = label;
		_label.scale.set(0.625, 0.625);
		_label.updateHitbox();
		add(_label);

		_desc = new FlxBitmapText(0, 0, Assets.bitmapFont("phantommuff"));
		_desc.color = 0xFFD8DAF6;
		_desc.alignment = align == LEFT ? LEFT : CENTER;
		_desc.text = desc;
		_desc.scale.set(0.625, 0.625);
		_desc.updateHitbox();
		add(_desc);

		switch (view)
		{
			case GRID:
				_label.x = button.x + (button.width - _label.width) / 2;
				_label.y = button.y + button.height - _label.height - 2;

				var ratio = icon.width / icon.height;
				icon.setGraphicSize(width - 20, (width / ratio) - 20);
				icon.updateHitbox();
				icon.x = button.x + (button.width - icon.width) / 2;
				icon.y = button.y + (button.height - icon.height) / 2;
			default:
				switch (align)
				{
					case LEFT:
						_label.setPosition(button.x + 4, button.y + ((button.height / 2) - (_label.height / 2)));
						_desc.setPosition(_label.x + 4, button.y + ((button.height / 2) - (_desc.height / 2)));
					default:
						_label.setPosition(button.x
							+ ((button.width / 2) - (_label.width / 2))
							- (_desc.width / 2)
							- 1,
							button.y
							+ ((button.height / 2) - (_label.height / 2)));
						_desc.setPosition(button.x
							+ ((button.width / 2) - (_desc.width / 2))
							+ (_label.width / 2)
							+ 1,
							button.y
							+ ((button.height / 2) - (_desc.height / 2)));
				}

				if (type == NOTETYPE)
				{
					var ratio = icon.height / icon.width;
					var scale = 0.8;
					icon.setGraphicSize((height / ratio) * scale, (height) * scale);
					icon.updateHitbox();
					icon.x = button.x + width - icon.width;
					icon.y = button.y + (button.height - icon.height) / 2;
				}
				else
				{
					var ratio = icon.width / icon.height;
					icon.setGraphicSize(height, (height / ratio));
					icon.updateHitbox();
					icon.x = button.x + width - icon.width;
					icon.y = button.y + (button.height - icon.height) / 2;
				}
		}
	}
}
